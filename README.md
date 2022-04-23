
<h1 align="center"><b>JediStaking Smart Contract</b></h3>

<div align="left">


[![Language](https://img.shields.io/badge/language-solidity-orange.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

</div>

---

<p align="center"><h2 align="center"><b>Solidity Smart contract for Staking JDT ERC20 Tokens
    </h2></b><br> 
</p>

## 📝 Table of Contents

- [EtherScan Link](#etherscan)
- [Installing](#install)
- [Contract Functions](#functions)
- [Deploy & Test Scripts](#scripts)
- [HardHat Tasks](#tasks)

## 🚀 Link on EtherScan <a name = "etherscan"></a>

https://rinkeby.etherscan.io/address/0x4AB7544890020E913995eAf0582B370175Ee2019#code



## 🚀 Installing <a name = "install"></a>
- Set initial values on scripts/deploy.ts file
- Deploy contract running on console:
```shell
node scripts/deploy.ts
```
- Copy address of deployed contract and paste to .env file as CONTRACT_ADDRESS
- Use stake, claim and unstake functions




## ⛓️ Contract Functions <a name = "functions"></a>

- **stake()**
>Staking function, takes amount of LP Tokens

- **claim()**
>Claims reward if reward rate passes

- **unstake()**
>Unstakes the full amount and claims left rewards

- **setRewardRate()**
>Sets the time reward gains<br>


- **setLockTime()**
>Sets the lock time, user can't unstake unless it passes

- **setRewardPercent()**
>Sets percent of rewards gained from amount of LP Tokens staked



## 🎈 Deploy & Test Scripts <a name = "scripts"></a>

```shell
node scripts/deploy.js --network rinkeby
npx hardhat test
```


## 💡 HardHat Tasks <a name = "tasks"></a>


```shell
npx hardhat stake
npx hardhat claim
npx hardhat unstake
```

