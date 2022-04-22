import { expect } from "chai"
import { Contract } from "ethers";
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address"
import { BigNumber } from "@ethersproject/bignumber"
import { IUniswapV2Factory } from '../typechain-types/contracts/interfaces/IUniswapV2Factory'
import { IUniswapV2Router02 } from '../typechain-types/contracts/interfaces/IUniswapV2Router02'
import { IUniswapV2Pair } from '../typechain-types/contracts/interfaces/IUniswapV2Pair'

const ONE = ethers.BigNumber.from(1);
const TWO = ethers.BigNumber.from(2);

function sqrt(value: any) {
    let x = ethers.BigNumber.from(value);
    let z = x.add(ONE).div(TWO);
    let y = x;
    while (z.sub(y).isNegative()) {
        y = z;
        z = x.div(z).add(z).div(TWO);
    }
    return y;
}

describe("ERC20", function () {
    let owner: SignerWithAddress
    let stakerOne: SignerWithAddress
    let token: Contract
    let router: IUniswapV2Router02
    let factory: IUniswapV2Factory
    let pair: IUniswapV2Pair
    let jdtstake: Contract
    let pairAddress: string
    let tokenAmount: BigNumber
    let etherAmount: BigNumber
    let lpAmount: BigNumber


    beforeEach(async function () {
        // Get the signers
        [owner, stakerOne] = await ethers.getSigners()
        
        // Deploy the JDT token
        const testERC20 = await ethers.getContractFactory("testERC20")
        token = <Contract>(await testERC20.deploy("JediToken", "JDT", 10000000, 1))
        await token.deployed()

        const testStake = await ethers.getContractFactory("JediStaking")
        jdtstake = <Contract>(await testStake.deploy())
        await jdtstake.deployed()

        // Get the UniswapV2 Factory and Router
        router = <IUniswapV2Router02>(await ethers.getContractAt("IUniswapV2Router02", 
            process.env.ROUTER_ADDRESS as string));
        factory = <IUniswapV2Factory>(await ethers.getContractAt("IUniswapV2Factory", 
            process.env.FACTORY_ADDRESS as string));
        
        
        // Approve the token to the router
        tokenAmount = ethers.BigNumber.from(1000000);
        etherAmount = ethers.utils.parseEther("1")
        await token.mint(stakerOne.address, tokenAmount)
        await token.connect(stakerOne).approve(router.address, tokenAmount)

        // Create the liquidity
        let deadline = await (await ethers.provider.getBlock(
            await ethers.provider.getBlockNumber())).timestamp + 100

        await router.connect(stakerOne).addLiquidityETH(
            token.address, 1000000, 0, etherAmount,
            stakerOne.address, deadline, { value: etherAmount })
        
        // Get pair address
        pairAddress = await factory.getPair(token.address, process.env.WETH_ADDRESS as string)

        pair = <IUniswapV2Pair>(await ethers.getContractAt("IUniswapV2Pair", 
            pairAddress as string));

        jdtstake.setLPToken(pairAddress)
        jdtstake.setRewardToken(token.address)

        lpAmount = sqrt(tokenAmount.mul(etherAmount)).sub(ethers.BigNumber.from(1000))
        await pair.connect(stakerOne).approve(jdtstake.address, lpAmount)
        await token.mint(jdtstake.address, lpAmount)
    })
    
    it("should be deployed", async function () {
      expect(jdtstake.address).to.be.properAddress
    })

   it("should not be able to get reward when not staked", async function () {
    expect(jdtstake.connect(stakerOne).claim()).to.be.revertedWith("You did not staked")
    })

    it("should not be able to untake when not staked", async function () {
    expect(jdtstake.connect(stakerOne).unstake()).to.be.revertedWith("You did not staked")
    })

    it("should able to stake and get right balances and allowances", async function () {
        let preAllowance = await pair.allowance(stakerOne.address, jdtstake.address)
        let preStakerBalance = await pair.balanceOf(stakerOne.address)
        let preStakeBalance = await pair.balanceOf(jdtstake.address)

        await jdtstake.connect(stakerOne).stake(lpAmount)
        
        let postAllowance = await pair.allowance(stakerOne.address, jdtstake.address)
        let postStakerBalance = await pair.balanceOf(stakerOne.address)
        let postStakeBalance = await pair.balanceOf(jdtstake.address)
        
        expect(preAllowance).to.be.equal(lpAmount)
        expect(postAllowance).to.be.equal(0)
        expect(preStakerBalance).to.be.equal(lpAmount)
        expect(postStakerBalance).to.be.equal(0)
        expect(preStakeBalance).to.be.equal(0)
        expect(postStakeBalance).to.be.equal(lpAmount)
    })

    it("should not be able to unstake when lock time not passed", async function () {
        await jdtstake.connect(stakerOne).stake(lpAmount)

        expect(jdtstake.connect(stakerOne).unstake()).to.be.revertedWith("Lock time is not expired")
    })

    it("should able to claim", async function () {
        await jdtstake.connect(stakerOne).stake(lpAmount)

        await new Promise(f => setTimeout(f, 10000));

        let preStakerRewardToken = await token.balanceOf(stakerOne.address)
        
        await jdtstake.connect(stakerOne).claim()

        let postStakerRewardToken = await token.balanceOf(stakerOne.address)
        
        expect(preStakerRewardToken < postStakerRewardToken).to.be.true
    })

    it("should able to unstake", async function () {
        await jdtstake.connect(stakerOne).stake(lpAmount)

        await new Promise(f => setTimeout(f, 5000));

        let preStakerBalance = await pair.balanceOf(stakerOne.address)
        let preStakeBalance = await pair.balanceOf(jdtstake.address)
        let preStakerRewardToken = await token.balanceOf(stakerOne.address)
        
        await jdtstake.connect(stakerOne).unstake()

        let postStakerBalance = await pair.balanceOf(stakerOne.address)
        let postStakeBalance = await pair.balanceOf(jdtstake.address)
        let postStakerRewardToken = await token.balanceOf(stakerOne.address)

        expect(preStakerBalance).to.be.equal(postStakeBalance)
        expect(preStakeBalance).to.be.equal(postStakerBalance)
        expect(preStakerRewardToken < postStakerRewardToken).to.be.true
    })

    

  });
