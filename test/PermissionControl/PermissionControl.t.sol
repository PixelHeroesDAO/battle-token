// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solady/test/utils/SoladyTest.sol";
import "solady/src/utils/LibClone.sol";
import "./mocks/MockPermissionControl.sol";

contract PermissionControlTest is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event OwnershipHandoverRequested(address indexed pendingOwner);

    event OwnershipHandoverCanceled(address indexed pendingOwner);

    event RolesUpdated(address indexed user, uint256 indexed roles);

    //MockPermissionControl implement;
    MockPermissionControl mockPermissionControl;

    function setUp() public {
        mockPermissionControl = new MockPermissionControl();
        //mockPermissionControl = MockPermissionControl(LibClone.clone(address(implement)));
    }

    function testBytecodeSize() public {
        MockPermissionControlBytecodeSizer mock = new MockPermissionControlBytecodeSizer();
        assertTrue(address(mock).code.length > 0);
        //assertEq(mock.owner(), address(this));
    }

    function testGrantAndRemoveRolesDirect(
        address user,
        uint256 rolesToGrant,
        uint256 rolesToRemove
    ) public {
        mockPermissionControl.removeRolesDirect(user, mockPermissionControl.rolesOf(user));
        assertEq(mockPermissionControl.rolesOf(user), 0);
        mockPermissionControl.grantRolesDirect(user, rolesToGrant);
        assertEq(mockPermissionControl.rolesOf(user), rolesToGrant);
        mockPermissionControl.removeRolesDirect(user, rolesToRemove);
        assertEq(mockPermissionControl.rolesOf(user), rolesToGrant ^ (rolesToGrant & rolesToRemove));
    }

    function testSetRolesDirect(uint256) public {
        address userA = _randomNonZeroAddress();
        address userB = _randomNonZeroAddress();
        while (userA == userB) userA = _randomNonZeroAddress();
        for (uint256 t; t != 2; ++t) {
            uint256 rolesA = _random();
            uint256 rolesB = _random();
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(userA, rolesA);
            mockPermissionControl.setRolesDirect(userA, rolesA);
            emit RolesUpdated(userB, rolesB);
            mockPermissionControl.setRolesDirect(userB, rolesB);
            assertEq(mockPermissionControl.rolesOf(userA), rolesA);
            assertEq(mockPermissionControl.rolesOf(userB), rolesB);
        }
    }

    function testGrantRoles() public {
        vm.expectEmit(true, true, true, true);
        uint256 roles = 11111 & ~mockPermissionControl.ADMIN_ROLE();
        emit RolesUpdated(address(1), roles);
        mockPermissionControl.grantRoles(address(1), roles);
    }

    function testGrantAndRevokeOrRenounceRoles(
        address user,
        bool granterIsAdmin,
        bool useRenounce,
        bool revokerIsAdmin,
        uint256 rolesToGrant,
        uint256 rolesToRevoke
    ) public {
        vm.assume(user != address(this) && rolesToRevoke != 0);
        uint256 adminRole = mockPermissionControl.ADMIN_ROLE();
        bool grantRolesWithAdmin = (rolesToGrant == adminRole)
            ? false
            : (1 == (rolesToGrant & adminRole));
        bool revokeRolesWithAdmin = (rolesToRevoke == adminRole)
            ? false
            : (1 == (rolesToRevoke & adminRole));
        uint256 rolesAfterRevoke = rolesToGrant ^ (rolesToGrant & rolesToRevoke);

        assertTrue(rolesAfterRevoke & rolesToRevoke == 0);
        assertTrue((rolesAfterRevoke | rolesToRevoke) & rolesToGrant == rolesToGrant);
        if (grantRolesWithAdmin) {
            vm.expectRevert(PermissionControlBase.UpdateRolesWithAdmin.selector);
        } else if (granterIsAdmin) {
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(user, rolesToGrant);
        } else {
            vm.prank(user);
            vm.expectRevert(PermissionControlBase.Unauthorized.selector);
        }
        mockPermissionControl.grantRoles(user, rolesToGrant);

        if (!granterIsAdmin || grantRolesWithAdmin) return;

        assertEq(mockPermissionControl.rolesOf(user), rolesToGrant);
        if (useRenounce) {
            if (revokeRolesWithAdmin) {
                vm.expectRevert(PermissionControlBase.UpdateRolesWithAdmin.selector);
                vm.prank(user);
                mockPermissionControl.renounceRoles(rolesToRevoke);
                return;
            } else {
                vm.expectEmit(true, true, true, true);
                emit RolesUpdated(user, rolesAfterRevoke);
                vm.prank(user);
                mockPermissionControl.renounceRoles(rolesToRevoke);
            }
        } else if (revokeRolesWithAdmin) {
            vm.expectRevert(PermissionControlBase.UpdateRolesWithAdmin.selector);
            mockPermissionControl.revokeRoles(user, rolesToRevoke);
            return;
        } else if (revokerIsAdmin || rolesToGrant == adminRole) {
            vm.expectEmit(true, true, true, true);
            emit RolesUpdated(user, rolesAfterRevoke);
            mockPermissionControl.revokeRoles(user, rolesToRevoke);
        } else {
            vm.prank(user);
            vm.expectRevert(PermissionControlBase.Unauthorized.selector);
            mockPermissionControl.revokeRoles(user, rolesToRevoke);
            return;
        }

        assertEq(mockPermissionControl.rolesOf(user), rolesAfterRevoke);
    }

    function testHasAllRoles(
        address user,
        uint256 rolesToGrant,
        uint256 rolesToGrantBrutalizer,
        uint256 rolesToCheck,
        bool useSameRoles
    ) public {
        uint256 adminRole = mockPermissionControl.ADMIN_ROLE();
        if (useSameRoles) {
            rolesToGrant = rolesToCheck;
        }
        rolesToGrant |= rolesToGrantBrutalizer;
        bool grantRolesWithAdmin = (rolesToGrant == adminRole)
            ? false
            : (1 == (rolesToGrant & adminRole));
        if (grantRolesWithAdmin) {
            vm.expectRevert(PermissionControlBase.UpdateRolesWithAdmin.selector);
            mockPermissionControl.grantRoles(user, rolesToGrant);
            return;
        } else {
            mockPermissionControl.grantRoles(user, rolesToGrant);
        }

        bool hasAllRoles = (rolesToGrant & rolesToCheck) == rolesToCheck;
        assertEq(mockPermissionControl.hasAllRoles(user, rolesToCheck), hasAllRoles);
    }

    function testHasAnyRole(address user, uint256 rolesToGrant, uint256 rolesToCheck) public {
        uint256 adminRole = mockPermissionControl.ADMIN_ROLE();
        bool grantRolesWithAdmin = (rolesToGrant == adminRole)
            ? false
            : (1 == (rolesToGrant & adminRole));
        if (grantRolesWithAdmin) {
            vm.expectRevert(PermissionControlBase.UpdateRolesWithAdmin.selector);
            mockPermissionControl.grantRoles(user, rolesToGrant);
            return;
        } else {
            mockPermissionControl.grantRoles(user, rolesToGrant);
        }
        assertEq(mockPermissionControl.hasAnyRole(user, rolesToCheck), rolesToGrant & rolesToCheck != 0);
    }

    function testRolesFromOrdinals(uint8[] memory ordinals) public {
        uint256 roles;
        unchecked {
            for (uint256 i; i < ordinals.length; ++i) {
                roles |= 1 << uint256(ordinals[i]);
            }
        }
        assertEq(mockPermissionControl.rolesFromOrdinals(ordinals), roles);
    }

    function testRolesFromOrdinals() public {
        unchecked {
            for (uint256 t; t != 32; ++t) {
                uint8[] memory ordinals = new uint8[](_random() % 32);
                for (uint256 i; i != ordinals.length; ++i) {
                    uint256 randomness = _random();
                    uint8 r;
                    assembly {
                        r := randomness
                    }
                    ordinals[i] = r;
                }
                testRolesFromOrdinals(ordinals);
            }
        }
    }

    function testOrdinalsFromRoles(uint256 roles) public {
        uint8[] memory ordinals = new uint8[](256);
        uint256 n;
        unchecked {
            for (uint256 i; i < 256; ++i) {
                if (roles & (1 << i) != 0) ordinals[n++] = uint8(i);
            }
        }
        uint8[] memory results = mockPermissionControl.ordinalsFromRoles(roles);
        assertEq(results.length, n);
        unchecked {
            for (uint256 i; i < n; ++i) {
                assertEq(results[i], ordinals[i]);
            }
        }
    }

    function testOrdinalsFromRoles() public {
        unchecked {
            for (uint256 t; t != 32; ++t) {
                testOrdinalsFromRoles(_random());
            }
        }
    }

    function testOnlyRolesModifier(address user, uint256 rolesToGrant, uint256 rolesToCheck)
        public
    {
        // Prevent grant and check admin role
        uint256 adminRole = mockPermissionControl.ADMIN_ROLE();
        rolesToGrant &= ~adminRole;
        rolesToCheck &= ~adminRole;
        
        mockPermissionControl.grantRoles(user, rolesToGrant);

        if (rolesToGrant & rolesToCheck == 0) {
            vm.expectRevert(PermissionControlBase.Unauthorized.selector);
        }
        vm.prank(user);
        mockPermissionControl.updateFlagWithOnlyRoles(rolesToCheck);
    }
}
