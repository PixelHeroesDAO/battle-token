// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/facets/PHBTFacet.sol";
import "../src/initializer/DiamondInitV1.sol";
import "diamond-2-hardhat/Diamond.sol";
import "diamond-2-hardhat/facets/DiamondLoupeFacet.sol";
import "diamond-2-hardhat/facets/DiamondCutFacet.sol";
import "diamond-2-hardhat/facets/OwnershipFacet.sol";
import "../src/facets/PermissionControlFacet.sol";
import "solidity-examples/mocks/LZEndpointMock.sol";

//import "../src/OFT/interfaces/ILayerZeroEndpoint.sol";
import "../src/constant/ConstantPermissionRole.sol";

import "./utils/SignMessage.sol";
import "solady/src/utils/LibString.sol";

import "./helpers/DiamondCutHelper.t.sol";
import "./facets/common/DiamondLoupeFacetHelper.t.sol";
import "./facets/common/OwnershipFacetHelper.t.sol";
import "./facets/PHBT/PHBTFacetHelper.t.sol";
import "./facets/PermissionControl/PermissionControlFacetHelper.t.sol";

contract TestPHBTInit is Test, SignMessage {
    using LibString for bytes;

    string constant FN_ENDPOINT = "./bytecode/Endpoint";
    uint16 constant CHAIN_ID = 1221;
    uint16 constant CHAIN_ID_B = 1222;
    address constant DEPLOYER_ENDPOINT = address(101);
    address constant DEPLOYER_B = address(103);
    address constant USER_ALICE = address(104);
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    Diamond public diamondB;
    DiamondCutFacet public diamondCutFacetB;
    LZEndpointMock public endpoint;
    LZEndpointMock public endpointB;

    DiamondCutHelper public diamondCutHelper;
    DiamondCutHelper public diamondCutHelperB;
    DiamondCutExternalVault public diamondCutVault;
    DiamondCutExternalVault public diamondCutVaultB;
    DiamondLoupeFacetHelper public diamondLoupeHelper;
    DiamondLoupeFacetHelper public diamondLoupeHelperB;
    OwnershipFacetHelper public ownershipFacetHelper;
    OwnershipFacetHelper public ownershipFacetHelperB;
    PHBTFacetHelper public PHBTHelper;
    PHBTFacetHelper public PHBTHelperB;
    PermissionControlFacetHelper public pcHelper;
    PermissionControlFacetHelper public pcHelperB;

    uint256 gas;

    function setUp() public {
        // Prepare ethers for depolyer
        vm.deal(DEPLOYER_ENDPOINT, 100 ether);
        vm.deal(DEPLOYER_B, 100 ether);
        // Prepare ethers for user
        vm.deal(USER_ALICE, 1 ether);
        // Deploy endpoint
        vm.startPrank(DEPLOYER_ENDPOINT);
        endpoint = new LZEndpointMock(CHAIN_ID);
        endpointB = new LZEndpointMock(CHAIN_ID_B);
        vm.stopPrank();

        // Prepare helper for first contracts group
        diamondCutVault = new DiamondCutExternalVault();
        diamondCutHelper = new DiamondCutHelper(diamondCutVault);
        diamondLoupeHelper = new DiamondLoupeFacetHelper();
        ownershipFacetHelper = new OwnershipFacetHelper();
        PHBTHelper = new PHBTFacetHelper(address(endpoint), address(this));
        pcHelper = new PermissionControlFacetHelper(address(this));

        diamondCutVault.add((address(diamondLoupeHelper)));
        diamondCutVault.add((address(ownershipFacetHelper)));
        diamondCutVault.add((address(PHBTHelper)));
        diamondCutVault.add((address(pcHelper)));

        // Deploy first contracts group
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(diamondCutFacet));

        // Prepare helper for second contracts group and Deploy diamond for second group
        vm.startPrank(DEPLOYER_B);
        {
            diamondCutVaultB = new DiamondCutExternalVault();
            diamondCutHelperB = new DiamondCutHelper(diamondCutVaultB);
            diamondLoupeHelperB = new DiamondLoupeFacetHelper();
            ownershipFacetHelperB = new OwnershipFacetHelper();
            PHBTHelperB = new PHBTFacetHelper(address(endpointB), DEPLOYER_B);
            pcHelperB = new PermissionControlFacetHelper(DEPLOYER_B);

            diamondCutVaultB.add((address(diamondLoupeHelperB)));
            diamondCutVaultB.add((address(ownershipFacetHelperB)));
            diamondCutVaultB.add((address(PHBTHelperB)));
            diamondCutVaultB.add((address(pcHelperB)));

            diamondCutFacetB = new DiamondCutFacet();
            diamondB = new Diamond(DEPLOYER_B, address(diamondCutFacetB));

        }
        vm.stopPrank();

        // internal bookkeeping for endpoints (only for test)
        endpoint.setDestLzEndpoint(address(diamondB), address(endpointB));
        vm.prank(DEPLOYER_B);
        endpointB.setDestLzEndpoint(address(diamond), address(endpoint));

        gas = gasleft();

        // Cut diamond facets for A
        IDiamondCut(address(diamond)).diamondCut(
            diamondCutHelper.getFacetCuts(),
            address(diamondCutHelper), 
            abi.encodeWithSelector(diamondCutHelper.initialize.selector)
        );

        // Cut diamond facets for B
        vm.startPrank(DEPLOYER_B, DEPLOYER_B);
        IDiamondCut(address(diamondB)).diamondCut(
            diamondCutHelperB.getFacetCuts(),
            address(diamondCutHelperB), 
            abi.encodeWithSelector(diamondCutHelperB.initialize.selector)
        );
        vm.stopPrank();

        // SetUp endpoint
        
        // SetUp for layerzero on A
        PHBTFacet(address(diamond)).setTrustedRemote(
            CHAIN_ID_B, 
            abi.encodePacked(address(diamondB), address(diamond))
        );
        vm.prank(DEPLOYER_B);
        PHBTFacet(address(diamondB)).setTrustedRemote(
            CHAIN_ID, 
            abi.encodePacked(address(diamond), address(diamondB))
        );
        // set in gas
        PHBTFacet(address(diamond)).setMinDstGas(CHAIN_ID_B, PHBTFacet(address(diamond)).PT_SEND(), 200000);
        PHBTFacet(address(diamond)).setUseCustomAdapterParams(true);

        vm.startPrank(DEPLOYER_B, DEPLOYER_B);
        {
            PHBTFacet(address(diamondB)).setMinDstGas(CHAIN_ID, PHBTFacet(address(diamondB)).PT_SEND(), 200000);
            PHBTFacet(address(diamondB)).setUseCustomAdapterParams(false);
        }
        vm.stopPrank();

        gas -= gasleft();
    }
    // deploy DiamondCutFacet

    function testTrial() public {

        PermissionControlFacet(address(diamond)).grantRoles(address(this), ConstantPermissionRole(address(diamond)).MINTER_ROLE());
        assertEq(
            PermissionControlFacet(address(diamond)).hasAnyRole(
                address(this), 
                ConstantPermissionRole(address(diamond)).MINTER_ROLE()
            ), true
        );

        PHBTFacet phbtA = PHBTFacet(address(diamond)); 
        PHBTFacet phbtB = PHBTFacet(address(diamondB));
        // Mint tokens for default address
        phbtA.mint(address(this), 10**18);
        console.log("Default user mints on PHBT-A. Balance:", phbtA.balanceOf(address(this)));
        assertEq(phbtA.balanceOf(address(this)), 10**18);

        //endpointB.blockNextMsg();
        //vm.stopPrank();
        uint16 ver = 1;
        uint256 bridgeGas = 225000;
        bytes memory param = abi.encodePacked(ver, bridgeGas);
        (uint256 nativeFee, ) = phbtA.estimateSendFee(
            CHAIN_ID_B, 
            abi.encodePacked(address(this)), 
            10**17,
            false,
            param
        );
        //uint256 nativeFee = 12300000;
        console.log(nativeFee);
        phbtA.sendFrom{ value: nativeFee }(
            address(this),
            CHAIN_ID_B,
            abi.encodePacked(address(this)),
            10**17,
            payable(address(this)),
            address(0),
            param
        );
        assertEq(phbtA.balanceOf(address(this)), 9 * 10**17);
        console.log("A / Default", phbtA.balanceOf(address(this)));
        assertEq(phbtA.balanceOf(USER_ALICE), 0 * 10**17);
        console.log("A / Alice  ", phbtA.balanceOf(USER_ALICE));
        assertEq(phbtB.balanceOf(address(this)), 1 * 10**17);
        console.log("B / Default", phbtB.balanceOf(address(this)));
        assertEq(phbtB.balanceOf(USER_ALICE), 0 * 10**17);
        console.log("B / Alice  ", phbtB.balanceOf(USER_ALICE));

        phbtB.transfer(USER_ALICE, 5*10**16);
        assertEq(phbtB.balanceOf(address(this)), 1 * 10**17 - 5 * 10**16);
        assertEq(phbtB.balanceOf(USER_ALICE), 5 * 10**16);
        //    ).to.emit(lzEndpointDstMock, "PayloadStored")
        vm.startPrank(USER_ALICE, USER_ALICE);
        {
            (nativeFee, ) = phbtB.estimateSendFee(
                CHAIN_ID, 
                abi.encodePacked(USER_ALICE), 
                10**16,
                false,
                bytes("")
            );
            phbtB.sendFrom{ value: nativeFee }(
                USER_ALICE,
                CHAIN_ID,
                abi.encodePacked(USER_ALICE),
                10**16,
                payable(USER_ALICE),
                address(0),
                bytes("")
            );
        }
        vm.stopPrank();

        assertEq(phbtA.balanceOf(address(this)), 9 * 10**17);
        console.log("A / Default", phbtA.balanceOf(address(this)));
        assertEq(phbtA.balanceOf(USER_ALICE), 1 * 10**16);
        console.log("A / Alice  ", phbtA.balanceOf(USER_ALICE));
        assertEq(phbtB.balanceOf(address(this)), 1 * 10**17 - 5 * 10**16);
        console.log("B / Default", phbtB.balanceOf(address(this)));
        assertEq(phbtB.balanceOf(USER_ALICE), 4 * 10**16);
        console.log("B / Alice  ", phbtB.balanceOf(USER_ALICE));

    }

    function test_mintWithSign() public {

        PHBTFacet phbtA = PHBTFacet(address(diamond)); 

        // Grant minter role for contract owner.
        PermissionControlFacet(address(diamond)).grantRoles(address(this), ConstantPermissionRole(address(diamond)).MINTER_ROLE());
        assertEq(
            PermissionControlFacet(address(diamond)).hasAnyRole(
                address(this), 
                ConstantPermissionRole(address(diamond)).MINTER_ROLE()
            ), true
        );

        // Set signer.
        phbtA.setSigner(vm.addr(101));

        // Prepare signature.
        bytes32 domainSeparator = phbtA.DOMAIN_SEPARATOR();
        bytes32 hashType = keccak256(bytes("MintWithSign(address receiver,uint256 value,uint256 nonce,uint256 deadline)"));
        uint256 nonce = phbtA.getNonce(vm.addr(1));
        uint256 deadline = block.timestamp + 100;
        bytes memory message = abi.encode(
            domainSeparator,
            keccak256(abi.encode(
                hashType,
                vm.addr(1),
                10**18,
                nonce,
                deadline
            ))
        );
        bytes memory signature = signTypedDataHash(message, 101);
        console.log("message:", message.toHexString());
        console.log("signature:", signature.toHexString());

        // Invalid user's minting should be failed.
        vm.startPrank(vm.addr(2), vm.addr(2));
        {
            vm.expectRevert(PHBTFacet.InvalidSignature.selector);
            phbtA.mintWithSign(10**18, nonce, deadline, signature);
        }
        vm.stopPrank();


        // Minting should be success.
        vm.startPrank(vm.addr(1), vm.addr(1));
        {
            phbtA.mintWithSign(10**18, nonce, deadline, signature);
        }
        vm.stopPrank();
        assertEq(phbtA.getNonce(vm.addr(1)), nonce + 1);
        assertEq(phbtA.balanceOf(vm.addr(1)), 10**18);

        // Re-minting with current nonce should be failed.
        vm.startPrank(vm.addr(1), vm.addr(1));
        {
            vm.expectRevert(PHBTFacet.InvalidSignature.selector);
            phbtA.mintWithSign(10**18, nonce + 1, deadline, signature);
        }
        vm.stopPrank();

        // Re-minting with old nonce should be failed.
        vm.startPrank(vm.addr(1), vm.addr(1));
        {
            vm.expectRevert(PHBTFacet.InvalidNonce.selector);
            phbtA.mintWithSign(10**18, nonce, deadline, signature);
        }
        vm.stopPrank();

    }

    function generateSelectors(string[] memory names) internal pure returns(bytes4[] memory selectors) {
        uint256 len = names.length;
        selectors = new bytes4[](len);
        uint256 i;
        while (i < len) {
            //selectors[i] = abi.encodeWithSelector(names[i]);
            unchecked{
                ++i;
            }
        }
    }
    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    /// This code is modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol).
    function _hashTypedData(bytes32 separator, bytes32 structHash) internal view virtual returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, separator) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }
}
