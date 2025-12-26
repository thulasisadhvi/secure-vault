const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Secure Vault System", function () {
  let authManager, secureVault;
  let admin, user, attacker;

  // Setup before every test
  beforeEach(async function () {
    [admin, user, attacker] = await ethers.getSigners();

    // 1. Deploy Authorization Manager
    const AuthManager = await ethers.getContractFactory("AuthorizationManager");
    authManager = await AuthManager.deploy();
    await authManager.waitForDeployment();

    // 2. Deploy Secure Vault
    const SecureVault = await ethers.getContractFactory("SecureVault");
    secureVault = await SecureVault.deploy(authManager.target);
    await secureVault.waitForDeployment();
  });

  it("Should allow withdrawal with valid off-chain signature", async function () {
    const amount = ethers.parseEther("1.0");
    const authId = ethers.keccak256(ethers.toUtf8Bytes("unique-id-123"));

    // Step A: Fund the vault
    await admin.sendTransaction({
      to: secureVault.target,
      value: amount
    });

    // Step B: Create the Off-Chain Signature (The "Server" part)
    // IMPORTANT: The order of parameters must match the Solidity contract exactly!
    // vault address + recipient + amount + authId
    const messageHash = ethers.solidityPackedKeccak256(
      ["address", "address", "uint256", "bytes32"],
      [secureVault.target, user.address, amount, authId]
    );

    // Sign the binary data
    const messageBytes = ethers.getBytes(messageHash);
    const signature = await admin.signMessage(messageBytes);

    // Step C: Execute Withdrawal (The "Client" part)
    // We check the user's balance before and after
    await expect(
      secureVault.connect(user).withdraw(user.address, amount, authId, signature)
    ).to.changeEtherBalances(
      [secureVault, user],
      [-amount, amount]
    );
  });

  it("Should prevent replay attacks (using same signature twice)", async function () {
    const amount = ethers.parseEther("1.0");
    const authId = ethers.keccak256(ethers.toUtf8Bytes("unique-id-456"));

    // Fund vault
    await admin.sendTransaction({ to: secureVault.target, value: amount });

    // Generate Signature
    const messageHash = ethers.solidityPackedKeccak256(
      ["address", "address", "uint256", "bytes32"],
      [secureVault.target, user.address, amount, authId]
    );
    const signature = await admin.signMessage(ethers.getBytes(messageHash));

    // First withdrawal works
    await secureVault.connect(user).withdraw(user.address, amount, authId, signature);

    // Second withdrawal with SAME signature must fail
    await expect(
      secureVault.connect(user).withdraw(user.address, amount, authId, signature)
    ).to.be.revertedWith("Authorization already used");
  });
});