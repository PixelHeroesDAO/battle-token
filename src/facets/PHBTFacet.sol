// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PHBTFacetStorage.sol";
import "../OFT/token/oft/OFT.sol";
import "../utils/PermissionControl.sol";
import "../constant/ConstantPermissionRole.sol";
import "../utils/PermissionControlBase.sol";
import "solady/utils/SignatureCheckerLib.sol";


contract PHBTFacet is FacetInitializable, OFT, PermissionControlBase, ConstantPermissionRole {
    using PHBTFacetStorage for PHBTFacetStorage.Layout;
    using SignatureCheckerLib for address;

    error DeadlinePassed();
    error InvalidNonce();
    error InvalidSignature();

    // keccak256("PHBT")
    uint256 internal constant _SALT_PHBT = 0x568e1e43ace7fccb22d9b8817f5a8767f25732668a19cc9270f49fa5e61f7406;
    // Struct hash for mintWithSign function.
    // keccak256("MintWithSign(address receiver,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 internal constant _MINT_WITH_SIGN_HASH = 0x29ff2850a4a041340d33b060310c07291ddcd171f34f6f554f346f0e35c3a5ef;

    constructor() {
        _disableInitializers(_SALT_PHBT);
    }

    // Initializer must be public because there is no entry point of internal function for other contracts.
    function initialize(address _lzEndpoint, address _admin) external initializer(_SALT_PHBT) {
        __PHBTFacet_init(_lzEndpoint, _admin);
    }

    function __PHBTFacet_init(address _lzEndpoint, address _admin) internal onlyInitializing() {
        __PHBTFacet_init_unchained(_admin);
        __LzApp_init_unchained(_lzEndpoint);
        __OFT_init_unchained("PHBT", "PHBT");
    }
    
    function __PHBTFacet_init_unchained(address _admin) internal onlyInitializing() {}

    function mint(address to, uint256 amount) external onlyRoles(MINTER_ROLE) {
        _mint(to, amount);
    }
    function burn(address to, uint256 amount) external onlyRoles(BURNER_ROLE) {
        _burn(to, amount);
    }

    function getNonce(address account) external view virtual returns (uint256) {
        return PHBTFacetStorage.layout().nonce[account];
    }

    function getSigner() external view virtual returns (address) {
        return PHBTFacetStorage.layout().signer;
    }

    function setSigner(address newSigner) external virtual onlyAdmin {
        PHBTFacetStorage.layout().signer = newSigner;
    }

    function _increaseNonce(address account) internal virtual{
        ++PHBTFacetStorage.layout().nonce[account];
    }

    function mintWithSign(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external virtual {
        // Verify parameters.
        if (block.timestamp > deadline) revert DeadlinePassed();
        if (nonce != PHBTFacetStorage.layout().nonce[msg.sender]) revert InvalidNonce();

        // Prepare digest.
        bytes32 hashStruct = keccak256(abi.encode(_MINT_WITH_SIGN_HASH, msg.sender, amount, nonce, deadline));
        bytes32 digest = _hashTypedData(hashStruct);
        
        // Verify signature.
        address signer = PHBTFacetStorage.layout().signer;
        if (!signer.isValidSignatureNow(digest, signature)) revert InvalidSignature();

        // Increase nonce.
        _increaseNonce(msg.sender);

        // Mint token.
        _mint(msg.sender, amount);

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
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        bytes32 separator = DOMAIN_SEPARATOR();
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
