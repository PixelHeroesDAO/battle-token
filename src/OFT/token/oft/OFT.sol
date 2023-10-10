// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

//import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "solady/tokens/ERC20.sol";
import "./IOFT.sol";
import "./OFTCore.sol";
import "./OFTStorage.sol";

// override decimal() function is needed
contract OFT is FacetInitializable, OFTCore, ERC20, IOFT {
    function __OFT_init(string memory _name, string memory _symbol, address _lzEndpoint) internal onlyInitializing {
        __LzApp_init_unchained(_lzEndpoint);
        __OFT_init_unchained(_name, _symbol, _lzEndpoint);
    }

    function __OFT_init_unchained(string memory _name, string memory _symbol, address _lzEndpoint) internal onlyInitializing {
        OFTStorage.layout().name = _name;
        OFTStorage.layout().symbol = _symbol;
    }

    function name() public virtual override view returns (string memory) {
        return OFTStorage.layout().name;
    }

    function symbol() public virtual override view returns (string memory) {
        return OFTStorage.layout().symbol;
    }

    /*
    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCoreUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IOFTUpgradeable).interfaceId || interfaceId == type(IERC20Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    */

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _amount) internal virtual override returns(uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns(uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function totalSupply() 
        public 
        view 
        virtual 
        override(ERC20, IERC20Upgradeable)
        returns (uint256 result) 
    {
        return ERC20.totalSupply();
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override(ERC20, IERC20Upgradeable)
        returns (uint256 result) 
    {
        return ERC20.balanceOf(owner);
    }
    function allowance(address owner, address spender)
        public
        view
        virtual
        override(ERC20, IERC20Upgradeable)
        returns (uint256 result)
    {
        return ERC20.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) 
        public 
        virtual 
        override(ERC20, IERC20Upgradeable)
        returns (bool) 
    {
        return ERC20.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) 
        public 
        virtual 
        override(ERC20, IERC20Upgradeable)
        returns (bool) 
    {
        return ERC20.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) 
        public 
        virtual 
        override(ERC20, IERC20Upgradeable)
        returns (bool) 
    {
        return ERC20.transferFrom(from, to , amount);
    }

}
