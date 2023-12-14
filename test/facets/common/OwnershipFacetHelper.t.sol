// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../helpers/FacetHelper.t.sol";
import "diamond-2-hardhat/facets/OwnershipFacet.sol";
import { IERC173 } from "diamond-2-hardhat/interfaces/IERC173.sol";

contract OwnershipFacetHelper is FacetHelper {
    OwnershipFacet public loupeFacet;

    constructor() {
        loupeFacet = new OwnershipFacet();
    }

    function facetAddress() public view override returns(address) {
        return address(loupeFacet);
    }

    function selectors() public view override returns(bytes4[] memory) {
        bytes4[] memory selectors_ = new bytes4[](2);
        selectors_[0] = OwnershipFacet.transferOwnership.selector;
        selectors_[1] = OwnershipFacet.owner.selector;
        return selectors_;
    }

    function supportedInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC173).interfaceId;
    }

    function initializer() public pure override returns (bytes4) {
        return bytes4(0);
    }

    function initializeCalldata() public pure override returns (bytes memory) {
        return "";
    }

    function creationCode() public pure override returns (bytes memory) {
        return type(OwnershipFacet).creationCode;
    }
}