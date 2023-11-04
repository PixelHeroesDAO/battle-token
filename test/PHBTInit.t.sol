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

contract TestPHBTInit is Test {
    string constant FN_ENDPOINT = "./bytecode/Endpoint";
    uint16 constant CHAIN_ID = 1221;
    uint16 constant CHAIN_ID_B = 1222;
    address constant DEPLOYER_ENDPOINT = address(101);
    address constant DEPLOYER_B = address(103);
    address constant USER_ALICE = address(104);
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
    PermissionControlFacet public permissionFacet;
    PHBTFacet public phbtFacet;
    DiamondInit public init;
    Diamond public diamondB;
    DiamondCutFacet public diamondCutFacetB;
    DiamondLoupeFacet public diamondLoupeFacetB;
    OwnershipFacet public ownershipFacetB;
    PermissionControlFacet public permissionFacetB;
    PHBTFacet public phbtFacetB;
    DiamondInit public initB;
    LZEndpointMock public endpoint;
    LZEndpointMock public endpointB;

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

        // Deploy first contracts group
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        permissionFacet = new PermissionControlFacet();
        phbtFacet = new PHBTFacet();
        init = new DiamondInit(address(endpoint));
        diamond = new Diamond(address(this), address(diamondCutFacet));

        vm.startPrank(DEPLOYER_B);
        {
            diamondCutFacetB = new DiamondCutFacet();
            diamondLoupeFacetB = new DiamondLoupeFacet();
            ownershipFacetB = new OwnershipFacet();
            permissionFacetB = new PermissionControlFacet();
            phbtFacetB = new PHBTFacet();
            initB = new DiamondInit(address(endpointB));
            diamondB = new Diamond(DEPLOYER_B, address(diamondCutFacetB));
        }
        vm.stopPrank();

        // internal bookkeeping for endpoints (only for test)
        endpoint.setDestLzEndpoint(address(diamondB), address(endpointB));
        vm.prank(DEPLOYER_B);
        endpointB.setDestLzEndpoint(address(diamond), address(endpoint));

        gas = gasleft();

        // Cut diamond facets.
        IDiamondCut.FacetCut[] memory facets = new IDiamondCut.FacetCut[](4);
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = DiamondLoupeFacet.facets.selector;
        selectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        selectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        selectors[3] = DiamondLoupeFacet.facetAddress.selector;
        selectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        facets[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        selectors = new bytes4[](2);
        selectors[0] = OwnershipFacet.transferOwnership.selector;
        selectors[1] = OwnershipFacet.owner.selector;
        facets[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        selectors = new bytes4[](13);
        selectors[0] = bytes4(keccak256("ADMIN_ROLE()"));
        selectors[1] = bytes4(keccak256("MINTER_ROLE()"));
        selectors[2] = bytes4(keccak256("BURNER_ROLE()"));
        selectors[3] = permissionFacet.grantRoleBit.selector;
        selectors[4] = permissionFacet.grantRoles.selector;
        selectors[5] = permissionFacet.hasAllRoles.selector;
        selectors[6] = permissionFacet.hasAnyRole.selector;
        selectors[7] = permissionFacet.initializePermission.selector;
        selectors[8] = permissionFacet.renounceRoleBit.selector;
        selectors[9] = permissionFacet.renounceRoles.selector;
        selectors[10] = permissionFacet.revokeRoleBit.selector;
        selectors[11] = permissionFacet.revokeRoles.selector;
        selectors[12] = permissionFacet.rolesOf.selector;
        facets[2] = IDiamondCut.FacetCut({
            facetAddress: address(permissionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        selectors = new bytes4[](44);
        selectors[0] = bytes4(keccak256("DEFAULT_PAYLOAD_SIZE_LIMIT()"));
        selectors[1] = bytes4(keccak256("DOMAIN_SEPARATOR()"));
        selectors[2] = bytes4(keccak256("NO_EXTRA_GAS()"));
        selectors[3] = bytes4(keccak256("PT_SEND()"));
        selectors[4] = phbtFacet.allowance.selector;
        selectors[5] = phbtFacet.approve.selector;
        selectors[6] = phbtFacet.balanceOf.selector;
        selectors[7] = phbtFacet.burn.selector;
        selectors[8] = phbtFacet.circulatingSupply.selector;
        selectors[9] = phbtFacet.decimals.selector;
        selectors[10] = phbtFacet.decreaseAllowance.selector;
        selectors[11] = phbtFacet.estimateSendFee.selector;
        selectors[12] = phbtFacet.forceResumeReceive.selector;
        selectors[13] = phbtFacet.getConfig.selector;
        selectors[14] = phbtFacet.getTrustedRemoteAddress.selector;
        selectors[15] = phbtFacet.increaseAllowance.selector;
        selectors[16] = phbtFacet.initialize.selector;
        selectors[17] = phbtFacet.isTrustedRemote.selector;
        selectors[18] = phbtFacet.lzReceive.selector;
        selectors[19] = phbtFacet.mint.selector;
        selectors[20] = phbtFacet.name.selector;
        selectors[21] = phbtFacet.nonblockingLzReceive.selector;
        selectors[22] = phbtFacet.nonces.selector;
        selectors[23] = phbtFacet.permit.selector;
        selectors[24] = phbtFacet.retryMessage.selector;
        selectors[25] = phbtFacet.sendFrom.selector;
        selectors[26] = phbtFacet.setConfig.selector;
        selectors[27] = phbtFacet.setMinDstGas.selector;
        selectors[28] = phbtFacet.setPayloadSizeLimit.selector;
        selectors[29] = phbtFacet.setPrecrime.selector;
        selectors[30] = phbtFacet.setReceiveVersion.selector;
        selectors[31] = phbtFacet.setSendVersion.selector;
        selectors[32] = phbtFacet.setTrustedRemote.selector;
        selectors[33] = phbtFacet.setTrustedRemoteAddress.selector;
        selectors[34] = phbtFacet.setUseCustomAdapterParams.selector;
        selectors[35] = phbtFacet.symbol.selector;
        selectors[36] = phbtFacet.token.selector;
        selectors[37] = phbtFacet.totalSupply.selector;
        selectors[38] = phbtFacet.transfer.selector;
        selectors[39] = phbtFacet.transferFrom.selector;
        selectors[40] = phbtFacet.getNonce.selector;
        selectors[41] = phbtFacet.getSigner.selector;
        selectors[42] = phbtFacet.setSigner.selector;
        selectors[43] = phbtFacet.mintWithSign.selector;

        facets[3] = IDiamondCut.FacetCut({
            facetAddress: address(phbtFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        // Cut diamond facets for A
        IDiamondCut(address(diamond)).diamondCut(
            facets, 
            address(init), 
            abi.encodeWithSelector(DiamondInit.init.selector)
        );

        // Correct facets declaration.
        facets[0].facetAddress = address(diamondLoupeFacetB);
        facets[1].facetAddress = address(ownershipFacetB);
        facets[2].facetAddress = address(permissionFacetB);
        facets[3].facetAddress = address(phbtFacetB);
        // Cut diamond facets for B
        vm.prank(DEPLOYER_B);
        IDiamondCut(address(diamondB)).diamondCut(
            facets, 
            address(initB), 
            abi.encodeWithSelector(DiamondInit.init.selector)
        );
        
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
    /*
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
    */
}
