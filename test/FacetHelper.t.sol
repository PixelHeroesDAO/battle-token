// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IDiamondCut } from "diamond-2-hardhat/interfaces/IDiamondCut.sol";
import "diamond-2-hardhat/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC165 } from "diamond-2-hardhat/interfaces/IERC165.sol";


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

abstract contract FacetInitilizerHelper {
    /** @dev `VAULT` address should be specified when construct. Since init contract
      * is delegate-called, storage variables not valid when diamond initializes.
      * Init function calls helpers in immutable `VAULT`.
      */
    FacetInitilizerExternalVault immutable public VAULT;

    constructor(FacetInitilizerExternalVault vault) {
        VAULT = vault;
    }

    function _initInterfaces() internal virtual{
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // Add IERC165 supportInterfaces.
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        // Add all interfaces on each helper.
        FacetHelper[] memory helpers = VAULT.values();
        for (uint256 i; i < helpers.length; ++i) {
            bytes4[] memory interfaces = helpers[i].supportedInterfaces();
            for (uint256 j; j < interfaces.length; ++j) {
                ds.supportedInterfaces[interfaces[i]] = true;
            }
        }
    }
}

abstract contract FacetInitilizerExternalVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _helperSet;

    function add(FacetHelper target) public virtual returns (bool){
        return _helperSet.add(address(target));
    }

    function remove(FacetHelper target) public virtual returns (bool) {
        return _helperSet.remove(address(target));
    }

    function contains(FacetHelper target) public virtual returns (bool) {
        return _helperSet.contains(address(target));
    }

    function at(uint256 index) public virtual returns (address) {
        return _helperSet.at(index);
    }

    function length() public virtual returns (uint256) {
        return _helperSet.length();
    }

    function values() public virtual returns (FacetHelper[] memory helpers) {
        address[] memory addresses = _helperSet.values();
        uint256 len = addresses.length;
        if (len > 0){
            helpers = new FacetHelper[](len);
            for (uint256 i = 0; i < len; ++i) {
                helpers[i] = FacetHelper(addresses[i]);
            }
        }
    }

}