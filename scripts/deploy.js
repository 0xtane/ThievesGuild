
const hre = require("hardhat");

async function main() {

  const ContractFactory = await hre.ethers.getContractFactory("ThievesGuild");
  const contractInstance = await ContractFactory.deploy("Hello, Hardhat!");

  await contractInstance.deployed();

  console.log("ThievesGuild deployed to:", contractInstance.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
