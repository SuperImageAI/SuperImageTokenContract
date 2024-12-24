import dotenv from 'dotenv';
const { ethers } = require("hardhat");
dotenv.config();

async function main() {
  const contractFactory = await ethers.getContractFactory("SuperImageCoin");
  const contract  = await contractFactory.deploy(process.env.OWNER,process.env.MULTI_SGIN_TIME_LOCK_CONTRACT);
  console.log("Deploying DeepLink... address :  ",await contract.getAddress());
}

main();