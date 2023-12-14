// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../helpers/FacetHelper.t.sol";
import { PermissionControlFacet } from "src/facets/PermissionControlFacet.sol";

contract PermissionControlFacetHelper is FacetHelper {
    PermissionControlFacet public pcFacet;
    address public diamondOwner;

    constructor(address owner) {
        pcFacet = new PermissionControlFacet();
        diamondOwner = owner;
    }

    function facetAddress() public view override returns(address) {
        return address(pcFacet);
    }

    function selectors() public view override returns(bytes4[] memory) {
        bytes4[] memory selectors_ = new bytes4[](10);
        selectors_[0] = bytes4(keccak256("ADMIN_ROLE()"));
        selectors_[1] = bytes4(keccak256("MINTER_ROLE()"));
        selectors_[2] = bytes4(keccak256("BURNER_ROLE()"));
        selectors_[3] = pcFacet.grantRoles.selector;
        selectors_[4] = pcFacet.hasAllRoles.selector;
        selectors_[5] = pcFacet.hasAnyRole.selector;
        selectors_[6] = pcFacet.initializePermission.selector;
        selectors_[7] = pcFacet.renounceRoles.selector;
        selectors_[8] = pcFacet.revokeRoles.selector;
        selectors_[9] = pcFacet.rolesOf.selector;
        return selectors_;
    }

    function supportedInterfaces() public pure override returns (bytes4[] memory interfaces) {
    }

    function initializer() public pure override returns (bytes4) {
        return PermissionControlFacet.initializePermission.selector;
    }

    function initializeCalldata() public view override returns (bytes memory) {
        return abi.encode(diamondOwner);
    }

    function creationCode() public pure override returns (bytes memory) {
        return type(PermissionControlFacet).creationCode;
    }
}