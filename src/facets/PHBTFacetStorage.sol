// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library PHBTFacetStorage {
    struct Layout {
        address signer;
        mapping (address => uint256) nonce;
    }

    // keccak256(abi.encode(uint256(keccak256("diamond.storage.PHBTFacet")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PHBT_FACET_STORAGE = 0xe729ad199967b98860dcfe8aff5410c4b6228f6c0b524365b1124d2ce456fa00;

    function layout() internal pure returns (Layout storage $) {
        assembly {
            $.slot := PHBT_FACET_STORAGE
        }
    }

}