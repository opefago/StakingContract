// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const {ethers} = require("hardhat");
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const initialSupply = ethers.utils.parseEther("10000000000");
  const [deployer] = await ethers.getSigners();

  // We get the contract to deploy
  const rcTokenFactory = await ethers.getContractFactory("RCToken");
  const scTokenFactory = await ethers.getContractFactory("SCToken");
  const controllerFactory = await ethers.getContractFactory("StakingController");

  console.log(`Address deploying the contract --> ${deployer.address}`);
  
  const rc = await rcTokenFactory.deploy(initialSupply);

  console.log(`Reward Token contract address --> ${rc.address}`);
  
  const sc = await scTokenFactory.deploy(initialSupply);

  console.log(`Staking Token contract address --> ${sc.address}`);

  const controller =  await controllerFactory.deploy(1000, sc.address, rc.address, deployer.address);

  console.log(`Staking Controller contract address --> ${controller.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
