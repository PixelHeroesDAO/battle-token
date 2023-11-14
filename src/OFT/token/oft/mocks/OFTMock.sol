// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../OFT.sol";
import "diamond-2-hardhat/libraries/LibDiamond.sol";

// @dev example implementation inheriting a OFT
contract OFTMock is OFT {

    uint256 internal constant _SALT_OFT_MOCK = uint256(keccak256(abi.encodePacked("OFTMock")));

    function initialize(address _layerZeroEndpoint) public virtual initializer(_SALT_OFT_MOCK) {
        LibDiamond.setContractOwner(msg.sender);
        __OFT_init("MockOFT", "OFT", _layerZeroEndpoint);
    }
    //constructor(address _layerZeroEndpoint) OFT("MockOFT", "OFT", _layerZeroEndpoint) {}

    // @dev WARNING public mint function, do not use this in production
    function mintTokens(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}