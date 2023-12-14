// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../helpers/FacetHelper.t.sol";

import "src/facets/PHBTFacet.sol";
import { IOFT } from "src/OFT/token/oft/IOFT.sol";
import { IOFTCore } from "src/OFT/token/oft/IOFTCore.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract PHBTFacetHelper is FacetHelper {
    PHBTFacet public phbtFacet;
    address public lzEndpoint;
    address public diamondOwner;

    constructor(address endpoint, address owner) {
        phbtFacet = new PHBTFacet();
        lzEndpoint = endpoint;
        diamondOwner = owner;
    }

    function setDiamondOwner(address newOwner) external {
        diamondOwner = newOwner;
    }

    function setLzEndpoint(address newEndpoint) external {
        lzEndpoint = newEndpoint;
    }

    function facetAddress() public view override returns(address) {
        return address(phbtFacet);
    }

    function selectors() public view override returns(bytes4[] memory) {
        bytes4[] memory selectors_ = new bytes4[](44);
        selectors_[0] = bytes4(keccak256("DEFAULT_PAYLOAD_SIZE_LIMIT()"));
        selectors_[1] = bytes4(keccak256("DOMAIN_SEPARATOR()"));
        selectors_[2] = bytes4(keccak256("NO_EXTRA_GAS()"));
        selectors_[3] = bytes4(keccak256("PT_SEND()"));
        selectors_[4] = phbtFacet.allowance.selector;
        selectors_[5] = phbtFacet.approve.selector;
        selectors_[6] = phbtFacet.balanceOf.selector;
        selectors_[7] = phbtFacet.burn.selector;
        selectors_[8] = phbtFacet.circulatingSupply.selector;
        selectors_[9] = phbtFacet.decimals.selector;
        selectors_[10] = phbtFacet.decreaseAllowance.selector;
        selectors_[11] = phbtFacet.estimateSendFee.selector;
        selectors_[12] = phbtFacet.forceResumeReceive.selector;
        selectors_[13] = phbtFacet.getConfig.selector;
        selectors_[14] = phbtFacet.getTrustedRemoteAddress.selector;
        selectors_[15] = phbtFacet.increaseAllowance.selector;
        selectors_[16] = phbtFacet.initialize.selector;
        selectors_[17] = phbtFacet.isTrustedRemote.selector;
        selectors_[18] = phbtFacet.lzReceive.selector;
        selectors_[19] = phbtFacet.mint.selector;
        selectors_[20] = phbtFacet.name.selector;
        selectors_[21] = phbtFacet.nonblockingLzReceive.selector;
        selectors_[22] = phbtFacet.nonces.selector;
        selectors_[23] = phbtFacet.permit.selector;
        selectors_[24] = phbtFacet.retryMessage.selector;
        selectors_[25] = phbtFacet.sendFrom.selector;
        selectors_[26] = phbtFacet.setConfig.selector;
        selectors_[27] = phbtFacet.setMinDstGas.selector;
        selectors_[28] = phbtFacet.setPayloadSizeLimit.selector;
        selectors_[29] = phbtFacet.setPrecrime.selector;
        selectors_[30] = phbtFacet.setReceiveVersion.selector;
        selectors_[31] = phbtFacet.setSendVersion.selector;
        selectors_[32] = phbtFacet.setTrustedRemote.selector;
        selectors_[33] = phbtFacet.setTrustedRemoteAddress.selector;
        selectors_[34] = phbtFacet.setUseCustomAdapterParams.selector;
        selectors_[35] = phbtFacet.symbol.selector;
        selectors_[36] = phbtFacet.token.selector;
        selectors_[37] = phbtFacet.totalSupply.selector;
        selectors_[38] = phbtFacet.transfer.selector;
        selectors_[39] = phbtFacet.transferFrom.selector;
        selectors_[40] = phbtFacet.getNonce.selector;
        selectors_[41] = phbtFacet.getSigner.selector;
        selectors_[42] = phbtFacet.setSigner.selector;
        selectors_[43] = phbtFacet.mintWithSign.selector;
        return selectors_;
    }

    function supportedInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);
        interfaces[0] = type(IOFTCore).interfaceId;
        interfaces[1] = type(IOFT).interfaceId;
        interfaces[2] = type(IERC20Upgradeable).interfaceId;
    }

    function initializer() public pure override returns (bytes4) {
        return PHBTFacet.initialize.selector;
    }

    function initializeCalldata() public view override returns (bytes memory) {
        return abi.encode(lzEndpoint, diamondOwner);
    }

    function creationCode() public pure override returns (bytes memory) {
        return type(PHBTFacet).creationCode;
    }
}