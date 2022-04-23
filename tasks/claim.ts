/* eslint-disable prettier/prettier */
/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-extraneous-import */
import * as dotenv from "dotenv";

import { task } from "hardhat/config"

dotenv.config();

task("claim", "Claim rewards task")
  .setAction(async (taskArgs, hre) => {
    const [signer] = await hre.ethers.getSigners();
    const contractAddr = process.env.CONTRACT_ADDRESS;

    const StakingContract = await hre.ethers.getContractAt(
      "JediStaking",
      contractAddr as string,
      signer
    );

    const result = await StakingContract.claim();

    console.log(result);
  });
