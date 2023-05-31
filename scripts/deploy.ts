import { ethers } from "hardhat";

async function deployAContract(contractName: string) {
  const factory = await ethers.getContractFactory(contractName);
  let contract = await factory.deploy();

  console.log(
    `${contractName}: The address the Contract WILL have once mined: ${contract.address}`
  );

  console.log(
    `The transaction that was sent to the network to deploy the Contract: ${contract.deployTransaction.hash
    }`
  );

  console.log(
    'The contract is NOT deployed yet; we must wait until it is mined...'
  );

  await contract.deployed();
  console.log('Mined!\n\n-------------------\n\n');
}

async function main() {
  console.log("\n\n")
  await deployAContract("Counter");
  await deployAContract("Adoption");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
