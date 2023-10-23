// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../OFT/token/oft/OFT.sol";
import "../utils/PermissionControl.sol";
import "../constant/ConstantPermissionRole.sol";
import "../utils/PermissionControlBase.sol";


contract PHBTFacet is FacetInitializable, OFT, PermissionControlBase, ConstantPermissionRole {
    // keccak256("PHBT")
    uint256 internal constant _SALT_PHBT = 0x568e1e43ace7fccb22d9b8817f5a8767f25732668a19cc9270f49fa5e61f7406;

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
    
}
