pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPHBattleVault.sol";
import "./interfaces/IPHGameToken.sol";

import "hardhat/console.sol";

contract PHGameExchange is Ownable{
    IPHBattleVault public vault;
    IPHGameToken public token;

    // 経験値1あたりのトークン交換レート
    uint256 public exchangeRate;

    event ExchangeToToken(
        address indexed account, 
        uint128 indexed cID, 
        uint128 indexed tID, 
        uint64 consumedExp, 
        uint256 tokenAmount
    );

    error ZeroAddress();

    constructor(){
        exchangeRate = 1 ether / 1000;
    }

    function setVault(IPHBattleVault vault_) public onlyOwner {
        if (address(vault_) == address(0)) revert ZeroAddress();
        vault = vault_;
    }

    function setToken(IPHGameToken token_) public onlyOwner {
        if (address(token_) == address(0)) revert ZeroAddress();
        token = token_;
    }

    function setExchangeRate(uint256 rate) public onlyOwner {
        exchangeRate = rate;
    }

    function exchangeToToken(
        uint256 uts,
        uint128 cID, 
        uint128 tID, 
        uint64 expAmount, 
        bytes memory signature
    ) public returns(bool) {
        uint256 tokenAmount = expAmount * exchangeRate;
        vault.decreaseExp(uts, cID, tID, expAmount, signature);
        token.mint(msg.sender, tokenAmount);
        emit ExchangeToToken(msg.sender, cID, tID, expAmount, tokenAmount);
        return true;
    }

}
