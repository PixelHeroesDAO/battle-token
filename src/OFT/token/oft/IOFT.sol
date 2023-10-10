// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IOFTCore.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20Upgradeable {

}
