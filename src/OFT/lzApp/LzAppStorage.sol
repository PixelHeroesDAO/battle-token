// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../interfaces/ILayerZeroEndpoint.sol";

library LzAppStorage {
    struct Layout {
        ILayerZeroEndpoint lzEndpoint;
        mapping(uint16 => bytes) trustedRemoteLookup;
        mapping(uint16 => mapping(uint16 => uint)) minDstGasLookup;
        mapping(uint16 => uint) payloadSizeLimitLookup;
        address precrime;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.LzApp")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant LZ_APP_STORAGE = 0xedcbb5c7b85bb8243f473063e424fdb256e18a8304044e441e25f8bc21faba00;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := LZ_APP_STORAGE
        }
    }

}