import hardhat from "hardhat";
const { ethers } = hardhat;

async function main() {
  // Get the contract factory
  const SocialFeed = await ethers.getContractFactory("SocialFeed");

  // Deploy the contract
  const socialFeed = await SocialFeed.deploy();

  // Wait for the deployment to be mined
  await socialFeed.deployed();

  console.log("✅ SocialFeed deployed to:", socialFeed.address);
}

// Run the deployment script and handle errors
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
