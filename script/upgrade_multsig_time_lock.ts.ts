const { ethers, upgrades } = require("hardhat");

async function main() {
    const contract = await ethers.getContractFactory("MultSigTimeLock");

    await upgrades.upgradeProxy(
        process.env.MULTI_SGIN_TIME_LOCK_CONTRACT,
        contract
    );
    console.log("contract upgraded");
}

main();