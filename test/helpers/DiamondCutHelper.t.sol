// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IDiamondCut } from "diamond-2-hardhat/interfaces/IDiamondCut.sol";
import "diamond-2-hardhat/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC165 } from "diamond-2-hardhat/interfaces/IERC165.sol";

import "./FacetHelper.t.sol";

/**
 * @title DiamondCutHelper and DiamondCutExternalVault 
 * @author 0xedy.eth
 * @notice Helper contract for easy DiamondCut execution.
 * Follow the steps below to execute DiamondCut:
 * 1) Define a contract that inherits from FacetHelper that stores the Facet you want to Cut.
 * 2) 
 */

contract DiamondCutHelper {
    /** @dev `VAULT` address should be specified when construct. Since init contract
      * is delegate-called, storage variables not valid when diamond initializes.
      * Init function calls helpers in immutable `VAULT`.
      */
    DiamondCutExternalVault immutable public VAULT;

    constructor(DiamondCutExternalVault vault) {
        VAULT = vault;
    }

    function _setupInterfaces() internal virtual{
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // Add IERC165 supportInterfaces.
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        // Add diamond cut interfaces.
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        // Add all interfaces on each helper.
        FacetHelper[] memory helpers = VAULT.values();
        for (uint256 i; i < helpers.length; ++i) {
            bytes4[] memory interfaces = helpers[i].supportedInterfaces();
            for (uint256 j; j < interfaces.length; ++j) {
                ds.supportedInterfaces[interfaces[j]] = true;
            }
        }
    }

    function _setupInit() internal virtual{
        // Add all interfaces on each helper.
        FacetHelper[] memory helpers = VAULT.values();
        for (uint256 i; i < helpers.length; ++i) {
            if (helpers[i].initializer() != bytes4(0)) {
                bytes memory caller = abi.encodePacked(helpers[i].initializer(), helpers[i].initializeCalldata());
                (bool success, ) = address(this).call(caller);
                if (!success) revert(string(abi.encodePacked("Initialize failed. Helper index:",i)));

            }
        }

    }

    function initialize() external virtual {
        _setupInterfaces();
        _setupInit();
    }

    function getFacetCuts() public view virtual returns(IDiamondCut.FacetCut[] memory facets) {
        // Add all facets.
        FacetHelper[] memory helpers = VAULT.values();

        facets = new IDiamondCut.FacetCut[](helpers.length);
        for (uint256 i; i < helpers.length; ++i) {
            facets[i].facetAddress = helpers[i].facetAddress();
            facets[i].action = IDiamondCut.FacetCutAction.Add;
            facets[i].functionSelectors = helpers[i].selectors();
        }
    }

}

contract DiamondCutExternalVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _helperSet;

    function add(address target) public virtual returns (bool){
        return _helperSet.add((target));
    }

    function remove(address target) public virtual returns (bool) {
        return _helperSet.remove((target));
    }

    function contains(address target) public view virtual returns (bool) {
        return _helperSet.contains((target));
    }

    function at(uint256 index) public view virtual returns (address) {
        return _helperSet.at(index);
    }

    function length() public view virtual returns (uint256) {
        return _helperSet.length();
    }

    function values() public view virtual returns (FacetHelper[] memory helpers) {
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