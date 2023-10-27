// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


library OFTCoreStorage {
    struct Layout {
        bool useCustomAdapterParams;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.OFTCore")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OFT_CORE_STORAGE = 0x3f3b1835ff8da6cef2a4b4a77c8c56df4092f1422e2ae2fec192e4ed487ccb00;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := OFT_CORE_STORAGE
        }
    }

}