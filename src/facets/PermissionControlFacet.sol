// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/FacetInitializable.sol";
import "../utils/PermissionControl.sol";
import "../constant/ConstantPermissionRole.sol";

contract PermissionControlFacet is FacetInitializable, PermissionControl, ConstantPermissionRole {
    error GrantAdminToZero();

    // keccak256("PermissionControl")
    uint256 internal constant _SALT_PCF = 0x4eac3a24f950900890365f3b90168b157d93e83a5441bf7930d8cccd58f6bf1c;
    constructor() {
        _disableInitializers(_SALT_PCF);
    }

    function initializePermission(address newAdmin) external initializer(_SALT_PCF) {
        if (newAdmin == address(0)) revert GrantAdminToZero();
        _initializeAdmin(newAdmin);
    }
}