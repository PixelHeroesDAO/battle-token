// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/facets/PHBTFacet.sol";
import "../src/initializer/DiamondInitV1.sol";
import "diamond-2-hardhat/Diamond.sol";
import "diamond-2-hardhat/facets/DiamondLoupeFacet.sol";
import "diamond-2-hardhat/facets/DiamondCutFacet.sol";
import "diamond-2-hardhat/facets/OwnershipFacet.sol";

import "../src/OFT/interfaces/ILayerZeroEndpoint.sol";

contract TestPHBTInit is Test {
    string constant FN_ENDPOINT = "./bytecode/Endpoint";
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
    DiamondInit public diamondInit;
    ILayerZeroEndpoint public endpoint;
    function setUp() public {
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        diamond = new Diamond(address(this), address(this));
        endpoint = ILayerZeroEndpoint(create2(vm.readFileBinary(FN_ENDPOINT), 0));
    }
    // deploy DiamondCutFacet

    function testTrial() public {
        console.log(address(endpoint));
        console.log(precomputeCreate2(vm.readFileBinary(FN_ENDPOINT), 0));
    }

    function create2(bytes memory bytecode, uint256 salt) internal returns (address child) {
        assembly {
            child := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }

    function precomputeCreate2(bytes memory bytecode, uint256 salt) internal view returns (address){
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(bytes20(_data << 96));
    }
}
