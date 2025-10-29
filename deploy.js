const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("ChainCanvas");
  const instance = await Contract.deploy();
  await instance.deployed();

  console.log("ChainCanvas deployed to:", instance.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
