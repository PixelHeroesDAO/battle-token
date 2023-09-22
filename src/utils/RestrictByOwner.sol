// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import {Ownable} from "./Ownable.sol";
import { LibDiamond } from "diamond-2-hardhat/libraries/LibDiamond.sol";

abstract contract RestrictByOwner {
    modifier onlyOwner() virtual {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
