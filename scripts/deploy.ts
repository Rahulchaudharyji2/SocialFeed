import hardhat from "hardhat";
const { ethers } = hardhat;

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  let SocialFeed;
  try {
    SocialFeed = await ethers.getContractFactory("SocialFeed", deployer);
  } catch (error) {
    console.error("Error getting contract factory:", error);
    return;
  }

  let socialFeed;
  try {
    // Set gasPrice to 25 gwei (Amoy minimum)
    socialFeed = await SocialFeed.deploy({
      gasPrice: ethers.parseUnits("25", "gwei")
    });
    // No need for socialFeed.deployed() in Ethers v6
  } catch (error) {
    console.error("Error deploying contract:", error);
    return;
  }

  if (!socialFeed) {
    console.error("Contract deployment failed, socialFeed is undefined.");
    return;
  }

  // Use .target for contract address in ethers v6
  console.log("✅ SocialFeed deployed to:", socialFeed.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});