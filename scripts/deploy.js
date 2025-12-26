const hre = require("hardhat");

async function main() {
  // 1. Get Network Information (Required by Step 6)
  const network = await hre.ethers.provider.getNetwork();
  console.log(`Connected to network: ${network.name} (Chain ID: ${network.chainId})`);

  // 2. Deploy AuthorizationManager
  console.log("Deploying AuthorizationManager...");
  const AuthManager = await hre.ethers.getContractFactory("AuthorizationManager");
  const authManager = await AuthManager.deploy();
  await authManager.waitForDeployment();
  console.log(`AuthorizationManager deployed to: ${authManager.target}`);

  // 3. Deploy SecureVault (Linked to AuthManager)
  console.log("Deploying SecureVault...");
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const secureVault = await SecureVault.deploy(authManager.target);
  await secureVault.waitForDeployment();
  console.log(`SecureVault deployed to: ${secureVault.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});