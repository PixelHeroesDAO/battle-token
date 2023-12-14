// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IDiamondCut } from "diamond-2-hardhat/interfaces/IDiamondCut.sol";
import "diamond-2-hardhat/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC165 } from "diamond-2-hardhat/interfaces/IERC165.sol";

/**
 * @title FacetHelper 
 * @author 
 * @notice 
 */

abstract contract FacetHelper is IDiamondCut {
    /// @dev Deploy facet contract in ctor and return address for testing.
    function facetAddress() public view virtual returns (address);

    function selectors() public view virtual returns (bytes4[] memory);

    function initializer() public view virtual returns (bytes4);

    function initializeCalldata() public view virtual returns (bytes memory);

    function supportedInterfaces() public pure virtual returns (bytes4[] memory);

    /// @dev On replace, the other facet with the same selectors is replaced.
    function makeFacetCut(FacetCutAction action) public view returns (FacetCut memory) {
        return FacetCut({ action: action, facetAddress: facetAddress(), functionSelectors: selectors() });
    }

    function creationCode() public pure virtual returns (bytes memory);

    // empty implementation
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {

    }

}

