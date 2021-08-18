
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract TemptationStorage {
    using SafeERC20 for ERC20;
    ERC20 public erc20Token;

    using SafeMath for uint256;

    EnumerableSet.AddressSet stakers;

    // user => amount
    mapping(address => uint) public stakersAmount;

    uint public totalStaked;
}
