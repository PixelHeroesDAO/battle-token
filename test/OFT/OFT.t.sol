// SPDX-License-Identifier: MIT
/// @dev Transpile manually from OFT.test.js
/// All contracts are deployed by "owner" address and use PrankOwner modifier.
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "solidity-examples/mocks/LZEndpointMock.sol";
import "../../src/OFT/token/oft/mocks/OFTMock.sol";
import "solady/utils/LibClone.sol";

contract TestOFT is Test {

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(uint16 srcChainId, bytes srcAddress, uint64 nonce, address dstAddress);
    event PayloadStored(uint16 srcChainId, bytes srcAddress, address dstAddress, uint64 nonce, bytes payload, bytes reason);
    event ValueTransferFailed(address indexed to, uint indexed quantity);


    uint16 internal constant chainIdSrc = 1;
    uint16 internal constant chainIdDst = 2;
    string internal constant name = "OmnichainFungibleToken";
    string internal constant symbol = "OFT";
    uint256 internal constant globalSupply = 10**18;
    uint256 internal constant OWNER_KEY = 8888;

    address internal immutable owner = vm.addr(OWNER_KEY);
    LZEndpointMock internal lzEndpointSrcMock;
    LZEndpointMock internal lzEndpointDstMock;
    OFTMock internal implOFTMock;
    OFTMock internal OFTSrc;
    OFTMock internal OFTDst;
    bytes internal dstPath;
    bytes internal srcPath;

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        /*
        LZEndpointMock = await ethers.getContractFactory("LZEndpointMock")
        OFTMock = await ethers.getContractFactory("OFTMock")
        OFT = await ethers.getContractFactory("OFT")
        */
        lzEndpointSrcMock = new LZEndpointMock(chainIdSrc);
        lzEndpointDstMock = new LZEndpointMock(chainIdDst);
        // create an OmnichinFungibleToken implementation.
        implOFTMock = new OFTMock();
        // create two OmnichainFungibleToken instances from implementation
        OFTSrc = OFTMock(LibClone.clone(address(implOFTMock)));
        OFTSrc.initialize(address(lzEndpointSrcMock));
        OFTDst = OFTMock(LibClone.clone(address(implOFTMock)));
        OFTDst.initialize(address(lzEndpointDstMock));

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        lzEndpointSrcMock.setDestLzEndpoint(address(OFTDst), address(lzEndpointDstMock));
        lzEndpointDstMock.setDestLzEndpoint(address(OFTSrc), address(lzEndpointSrcMock));

        // set each contracts source address so it can send to each other
        dstPath = abi.encodePacked(address(OFTDst), address(OFTSrc));
        srcPath = abi.encodePacked(address(OFTSrc), address(OFTDst));
        OFTSrc.setTrustedRemote(chainIdDst, dstPath); // for A, set B
        OFTDst.setTrustedRemote(chainIdSrc, srcPath); // for B, set A

        //set destination min gas
        OFTSrc.setMinDstGas(chainIdDst, OFTSrc.PT_SEND(), 220000);
        OFTSrc.setUseCustomAdapterParams(true);

        // mint initial tokens
        OFTSrc.mintTokens(owner, globalSupply);    
        vm.stopPrank(); 
    }

    function setUpSetUpStoredPayload() internal returns (bytes memory adapterParam, uint256 sendQty) {
        // v1 adapterParams, encoded for version 1 style, and 200k gas quote
        uint16 ver = 1;
        uint256 gasFee = 225000;
        adapterParam = abi.encodePacked(ver, gasFee);
        sendQty = 10**17; // amount to be sent across

        // ensure they're both starting with correct amounts
        assertEq(OFTSrc.balanceOf(owner), globalSupply);
        assertEq(OFTDst.balanceOf(owner), 0);

        // block receiving msgs on the dst lzEndpoint to simulate ua reverts which stores a payload
        lzEndpointDstMock.blockNextMsg();

        // estimate nativeFees
        (uint256 nativeFee, ) = OFTSrc.estimateSendFee(
            chainIdDst, 
            abi.encodePacked(owner), 
            sendQty, 
            false, 
            adapterParam
        );

        // stores a payload
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit PayloadStored(chainIdSrc, abi.encodePacked(address(OFTSrc)), (address(OFTDst)), 0, "", "");
        OFTSrc.sendFrom{ value: nativeFee }(
            owner,
            chainIdDst,
            abi.encodePacked(owner),
            sendQty,
            payable(owner),
            address(0),
            adapterParam
        );

        // verify tokens burned on source chain and minted on destination chain
        assertEq(OFTSrc.balanceOf(owner), globalSupply - sendQty);
        assertEq(OFTDst.balanceOf(owner), 0);
    }

    function test_hasStoredPayload() public PrankOwner {
        setUpSetUpStoredPayload();
        assertEq(lzEndpointDstMock.hasStoredPayload(chainIdSrc, srcPath), true);
    }
    function test_getLengthOfQueue() public PrankOwner {
        (bytes memory adapterParam, uint256 sendQty) = setUpSetUpStoredPayload();

        // queue is empty
        assertEq(lzEndpointDstMock.getLengthOfQueue(chainIdSrc, srcPath), 0);

        // estimate nativeFees
        (uint256 nativeFee, ) = OFTSrc.estimateSendFee(
            chainIdDst, 
            abi.encodePacked(owner), 
            sendQty, 
            false, 
            adapterParam
        );

        // now that a msg has been stored, subsequent ones will not revert, but will get added to the queue
        OFTSrc.sendFrom{ value: nativeFee }(
            owner,
            chainIdDst,
            abi.encodePacked(owner),
            sendQty,
            payable(owner),
            address(0),
            adapterParam
        );

        // queue has increased
        assertEq(lzEndpointDstMock.getLengthOfQueue(chainIdSrc, srcPath), 1);

    }

    function test_retryPayload() public PrankOwner {
        (bytes memory adapterParam, uint256 sendQty) = setUpSetUpStoredPayload();

        // balance before transfer is 0
        assertEq(OFTDst.balanceOf(owner), 0);

        bytes memory payload = abi.encode(0, abi.encodePacked(owner), sendQty);
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit PayloadCleared(0, "", 0, address(0));

        lzEndpointDstMock.retryPayload(chainIdSrc, srcPath, payload);

        // balance after transfer is sendQty
        assertEq(OFTDst.balanceOf(owner), sendQty);
    }

    // removes msg
    function test_forceResumeReceive() public PrankOwner {
        (bytes memory adapterParam, uint256 sendQty) = setUpSetUpStoredPayload();
        // balance before is 0
        assertEq(OFTDst.balanceOf(owner), 0);

        // forceResumeReceive deletes the stuck msg
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit UaForceResumeReceive(0, "");
        OFTDst.forceResumeReceive(chainIdSrc, srcPath);

        // stored payload gone
        assertEq(lzEndpointDstMock.hasStoredPayload(chainIdSrc, srcPath), false);

        // balance after transfer is 0
        assertEq(OFTDst.balanceOf(owner), 0);
    }

    // removes msg, delivers all msgs in the queue
    function test_forceResumeReceive2() public PrankOwner {
        (bytes memory adapterParam, uint256 sendQty) = setUpSetUpStoredPayload();
        uint256 msgsInQueue = 3;

        // estimate nativeFees
        (uint256 nativeFee, ) = OFTSrc.estimateSendFee(
            chainIdDst, 
            abi.encodePacked(owner), 
            sendQty, 
            false, 
            adapterParam
        );

        for (uint256 i = 0; i < msgsInQueue; ++i) {
            // first iteration stores a payload, the following get added to queue
            OFTSrc.sendFrom{ value: nativeFee }(
                owner,
                chainIdDst,
                abi.encodePacked(owner),
                sendQty,
                payable(owner),
                address(0),
                adapterParam                
            );
        }

        // msg queue is full
        assertEq(lzEndpointDstMock.getLengthOfQueue(chainIdSrc, srcPath), msgsInQueue);

        // balance before is 0
        assertEq(OFTDst.balanceOf(owner), 0);

        // forceResumeReceive deletes the stuck msg
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit UaForceResumeReceive(0, "");
        OFTDst.forceResumeReceive(chainIdSrc, srcPath);

        // balance after transfer is 0
        assertEq(OFTDst.balanceOf(owner), sendQty * msgsInQueue);

        // msg queue is empty
        assertEq(lzEndpointDstMock.getLengthOfQueue(chainIdSrc, srcPath), 0);
    }

    //emptied queue is actually emptied and doesnt get double counted
    function test_forceResumeReceive3() public PrankOwner {
        (bytes memory adapterParam, uint256 sendQty) = setUpSetUpStoredPayload();
        uint256 msgsInQueue = 3;

        // estimate nativeFees
        (uint256 nativeFee, ) = OFTSrc.estimateSendFee(
            chainIdDst, 
            abi.encodePacked(owner), 
            sendQty, 
            false, 
            adapterParam
        );

        for (uint256 i = 0; i < msgsInQueue; ++i) {
            // first iteration stores a payload, the following get added to queue
            OFTSrc.sendFrom{ value: nativeFee }(
                owner,
                chainIdDst,
                abi.encodePacked(owner),
                sendQty,
                payable(owner),
                address(0),
                adapterParam                
            );
        }
        // msg queue is full
        assertEq(lzEndpointDstMock.getLengthOfQueue(chainIdSrc, srcPath), msgsInQueue);

        // balance before is 0
        assertEq(OFTDst.balanceOf(owner), 0);

        // forceResumeReceive deletes the stuck msg
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit UaForceResumeReceive(0, "");
        OFTDst.forceResumeReceive(chainIdSrc, srcPath);

        // balance after transfer
        assertEq(OFTDst.balanceOf(owner), sendQty * msgsInQueue);

        // estimate nativeFees
        (nativeFee, ) = OFTSrc.estimateSendFee(
            chainIdDst, 
            abi.encodePacked(owner), 
            sendQty, 
            false, 
            adapterParam
        );

        // store a new payload
        lzEndpointDstMock.blockNextMsg();
        OFTSrc.sendFrom{ value: nativeFee }(
            owner,
            chainIdDst,
            abi.encodePacked(owner),
            sendQty,
            payable(owner),
            address(0),
            adapterParam
        );

        // forceResumeReceive deletes msgs but since there's nothing in the queue, balance shouldn't increase
        vm.expectEmit(false, false, false, false, address(lzEndpointDstMock));
        emit UaForceResumeReceive(0, "");
        OFTDst.forceResumeReceive(chainIdSrc, srcPath);

        // balance after transfer remains the same
        assertEq(OFTDst.balanceOf(owner), sendQty * msgsInQueue);
    }

    modifier PrankOwner() {
        vm.startPrank(owner, owner);
        _;
        vm.stopPrank();
    }
}
