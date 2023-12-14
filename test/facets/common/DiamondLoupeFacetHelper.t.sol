// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../helpers/FacetHelper.t.sol";
import { IDiamondLoupe } from "diamond-2-hardhat/interfaces/IDiamondLoupe.sol";
import "diamond-2-hardhat/facets/DiamondLoupeFacet.sol";

contract DiamondLoupeFacetHelper is FacetHelper {
    DiamondLoupeFacet public loupeFacet;

    constructor() {
        loupeFacet = new DiamondLoupeFacet();
    }

    function facetAddress() public view override returns(address) {
        return address(loupeFacet);
    }

    function selectors() public view override returns(bytes4[] memory) {
        bytes4[] memory selectors_ = new bytes4[](5);
        selectors_[0] = DiamondLoupeFacet.facets.selector;
        selectors_[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        selectors_[2] = DiamondLoupeFacet.facetAddresses.selector;
        selectors_[3] = DiamondLoupeFacet.facetAddress.selector;
        selectors_[4] = DiamondLoupeFacet.supportsInterface.selector;
        return selectors_;
    }

    function supportedInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
                interfaces[0] = type(IDiamondLoupe).interfaceId;
    }

    function initializer() public pure override returns (bytes4) {
        return bytes4(0);
    }

    function initializeCalldata() public pure override returns (bytes memory) {
        return "";
    }

    function creationCode() public pure override returns (bytes memory) {
        return type(DiamondLoupeFacet).creationCode;
    }
}