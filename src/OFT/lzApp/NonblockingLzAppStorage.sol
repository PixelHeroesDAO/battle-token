// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library NonblockingLzAppStorage {
    struct Layout {
        mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) failedMessages;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.NonblockingLzApp")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant NONBLOCKING_LZ_APP_STORAGE = 0x65e04318090f9323551aebcc0467339c7d00deafd3b2bf1fe1706e53c42bfd00;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := NONBLOCKING_LZ_APP_STORAGE
        }
    }

}