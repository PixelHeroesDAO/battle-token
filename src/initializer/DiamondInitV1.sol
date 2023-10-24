// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "diamond-2-hardhat/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "diamond-2-hardhat/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "diamond-2-hardhat/interfaces/IDiamondCut.sol";
import { IERC173 } from "diamond-2-hardhat/interfaces/IERC173.sol";
import { IERC165 } from "diamond-2-hardhat/interfaces/IERC165.sol";
import { IOFT } from "../OFT/token/oft/IOFT.sol";
import { IOFTCore } from "../OFT/token/oft/IOFTCore.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../facets/PHBTFacet.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {    
    address public immutable LZ_ENDPOINT;

    constructor (address _lzEndpoint) {
        LZ_ENDPOINT = _lzEndpoint;
    }

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IOFTCore).interfaceId] = true;
        ds.supportedInterfaces[type(IOFT).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20Upgradeable).interfaceId] = true;

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
        PHBTFacet(address(this)).initialize(LZ_ENDPOINT, ds.contractOwner);
    }


}
