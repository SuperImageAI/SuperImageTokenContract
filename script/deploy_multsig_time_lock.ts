import dotenv from 'dotenv';
const { ethers } = require("hardhat");
dotenv.config();

async function main() {
  const contractFactory = await ethers.getContractFactory("MultSigTimeLock");
  const contract = await upgrades.deployProxy(contractFactory,[[process.env.SIGNER1,process.env.SIGNER2,process.env.SIGNER3],process.env.REQUIRED_APPROVE_COUNT,process.env.DELAY_SECONDS], { initializer: 'initialize' });
  console.log("deployed to:", contract.target);
}

main();