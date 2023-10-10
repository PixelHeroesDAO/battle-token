// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


library OFTStorage {
    struct Layout {
        string name;
        string symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.OFT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OFT_STORAGE = 0x6fab3f990d0c5a09e2003e4cce69473693a6b96abd3fc18132b962a1b5e29500;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := OFT_STORAGE
        }
    }

}