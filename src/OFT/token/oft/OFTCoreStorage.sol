// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


library OFTCoreStorage {
    struct Layout {
        bool useCustomAdapterParams;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.OFTCore")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OFT_CORE_STORAGE = 0xedcbb5c7b85bb8243f473063e424fdb256e18a8304044e441e25f8bc21faba00;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := OFT_CORE_STORAGE
        }
    }

}