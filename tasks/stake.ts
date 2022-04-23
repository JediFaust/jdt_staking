/* eslint-disable prettier/prettier */
/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-extraneous-import */
import * as dotenv from "dotenv";

import { task } from "hardhat/config"
import "@nomiclabs/hardhat-waffle";

dotenv.config();

task("stake", "Staking task")
  .addParam("amount", "Amount to transfer")
  .setAction(async (taskArgs, hre) => {
    const [signer] = await hre.ethers.getSigners();
    const contractAddr = process.env.CONTRACT_ADDRESS;

    const StakingContract = await hre.ethers.getContractAt(
      "JediStaking",
      contractAddr as string,
      signer
    );

    const result = await StakingContract.stake(taskArgs.amount);

    console.log(result);
  });
