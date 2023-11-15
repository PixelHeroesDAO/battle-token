// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PermissionControl, PermissionControlBase} from "../../../src/utils/PermissionControl.sol";
import {LibDiamond} from "diamond-2-hardhat/libraries/LibDiamond.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockPermissionControl is PermissionControl {
    bool public flag;

    constructor() payable {
        _initializeAdmin(msg.sender);

        // Perform the tests on the helper functions.
        address brutalizedAddress = _brutalizedAddress(address(0));
        bool brutalizedAddressIsBrutalized;
        /// @solidity memory-safe-assembly
        assembly {
            brutalizedAddressIsBrutalized := gt(shr(160, brutalizedAddress), 0)
        }

        if (!brutalizedAddressIsBrutalized) {
            revert("Setup failed");
        }
        
        bool badBool;
        /// @solidity memory-safe-assembly
        assembly {
            badBool := 2
        }

        bool checkedBadBool = _checkedBool(badBool);

        if (checkedBadBool) {
            revert("Setup failed");
        }
    }

    function setRolesDirect(address user, uint256 roles) public payable {
        _setRoles(_brutalizedAddress(user), roles);
    }

    function grantRolesDirect(address user, uint256 roles) public payable {
        _grantRoles(_brutalizedAddress(user), roles);
    }

    function removeRolesDirect(address user, uint256 roles) public payable {
        _removeRoles(_brutalizedAddress(user), roles);
    }

    function grantRoles(address user, uint256 roles) public payable virtual override {
        super.grantRoles(_brutalizedAddress(user), roles);
    }

    function revokeRoles(address user, uint256 roles) public payable virtual override {
        super.revokeRoles(_brutalizedAddress(user), roles);
    }

    function rolesOf(address user) public view virtual override returns (uint256 result) {
        result = super.rolesOf(_brutalizedAddress(user));
    }

    function updateFlagWithOnlyRoles(uint256 roles) public payable onlyRoles(roles) {
        flag = true;
    }

    function rolesFromOrdinals(uint8[] memory ordinals) public pure returns (uint256 roles) {
        roles = _rolesFromOrdinals(ordinals);
    }

    function ordinalsFromRoles(uint256 roles) public pure returns (uint8[] memory ordinals) {
        ordinals = _ordinalsFromRoles(roles);
    }

    function grantRoleBit(uint8 role, address user) public payable virtual override {
        super.grantRoleBit(role, _brutalizedAddress(user));
    }

    function revokeRoleBit(uint8 role, address user) public payable virtual override {
        super.revokeRoleBit(role, _brutalizedAddress(user));
    }


    function _brutalizedAddress(address value) private view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Some acrobatics to make the brutalized bits pseudorandomly
            // different with every call.
            mstore(0x00, or(calldataload(0), mload(0x40)))
            mstore(0x20, or(caller(), mload(0x00)))
            result := or(shl(160, keccak256(0x00, 0x40)), value)
            mstore(0x40, add(0x20, mload(0x40)))
            mstore(0x00, result)
        }
    }

    function _checkedBool(bool value) private pure returns (bool result) {
        result = value;
        bool resultIsOneOrZero;
        /// @solidity memory-safe-assembly
        assembly {
            // We wanna check if the result is either 1 or 0,
            // to make sure we practice good assembly politeness.
            resultIsOneOrZero := lt(result, 2)
        }
        if (!resultIsOneOrZero) result = !result;
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockPermissionControlBytecodeSizer is PermissionControl {
    constructor() payable {
        initialize();
    }

    function initialize() public payable {
        _initializeAdmin(msg.sender);
    }
}
