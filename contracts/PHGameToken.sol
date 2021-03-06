pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IPHGameToken.sol";

contract PHGameToken is ERC20, IPHGameToken, AccessControl{
    // AccessControl関係
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Pixel Heroes Game Token","PIKU"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address account, uint256 amount) external override onlyRole(MINTER_ROLE){
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyRole(MINTER_ROLE){
        _burn(account, amount);
    }

}

