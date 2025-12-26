// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define an interface to interact with the Authorization Manager
interface IAuthorizationManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes memory signature
    ) external returns (bool);
}

contract SecureVault {
    // Reference to the Authorization Manager contract
    IAuthorizationManager public authManager;

    // Events for observability
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(bytes32 indexed authId, address indexed recipient, uint256 amount);

    // Initialize with the address of the Authorization Manager
    constructor(address _authManager) {
        authManager = IAuthorizationManager(_authManager);
    }

    // Accept native currency (ETH) deposits from anyone
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Executes a withdrawal after validating permissions with the Auth Manager.
     * @param recipient The address to receive the funds
     * @param amount The amount to withdraw
     * @param authId Unique ID for this authorization
     * @param signature Cryptographic proof provided by the off-chain signer
     */
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes memory signature
    ) external {
        // 1. Request authorization validation
        // We pass 'address(this)' so the Manager knows WHICH vault is asking.
        // This binds the authorization to this specific contract instance.
        bool isAuthorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            authId,
            signature
        );

        require(isAuthorized, "Withdrawal denied by Authorization Manager");

        // 2. Check if the vault has enough funds
        require(address(this).balance >= amount, "Insufficient vault funds");

        // 3. Transfer funds to the recipient
        // We use 'call' as it is the recommended way to send ETH
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");

        // 4. Emit withdrawal event
        emit Withdrawal(authId, recipient, amount);
    }
}