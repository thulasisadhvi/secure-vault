// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuthorizationManager {
    // The address allowed to sign withdrawal authorizations
    address public admin;

    // Mapping to track used authorization IDs to prevent replays
    mapping(bytes32 => bool) public processedAuths;

    event AuthorizationProcessed(bytes32 indexed authId, address indexed recipient, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    /**
     * @dev Verifies that a withdrawal is authorized by the admin.
     * @param vault The address of the vault requesting verification (binds auth to specific vault)
     * @param recipient The address receiving the funds
     * @param amount The amount of funds
     * @param authId A unique identifier for this specific authorization (nonce)
     * @param signature The cryptographic signature from the admin
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes memory signature
    ) external returns (bool) {
        // 1. Ensure authorization has not been used before
        require(!processedAuths[authId], "Authorization already used");

        // 2. Reconstruct the message hash 
        // We include the vault address to ensure this signature works ONLY for this specific vault
        bytes32 messageHash = keccak256(abi.encodePacked(vault, recipient, amount, authId));
        
        // 3. Add the standard Ethereum prefix to the hash
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // 4. Recover the signer from the signature
        address signer = recoverSigner(ethSignedMessageHash, signature);

        // 5. Validate authorization authenticity
        require(signer == admin, "Invalid signature");

        // 6. Mark authorization as consumed
        processedAuths[authId] = true;

        emit AuthorizationProcessed(authId, recipient, amount);

        return true;
    }

    // --- Helper Functions for Cryptography ---

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}