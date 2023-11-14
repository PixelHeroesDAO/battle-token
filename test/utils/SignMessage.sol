// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract SignMessage is Test {
    /// @dev Sign as Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function sign(bytes memory message, uint256 privateKey) internal pure returns (bytes memory) {

        // create digest: keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                                                    keccak256(message))
        );
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }

    function signTypedDataHash(bytes memory message, uint256 privateKey) internal pure returns (bytes memory) {

        // create digest: keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",
                                                    message)
        );
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }

    function getDigest(bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
    }
}
