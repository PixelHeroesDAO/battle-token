// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract ConstantPermissionRole {
    uint256 public constant MINTER_ROLE = 1 << 1;
    uint256 public constant BURNER_ROLE = 1 << 2;
}
