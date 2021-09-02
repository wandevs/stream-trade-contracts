
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract TemptationStorage {
    using SafeMath for uint256;

    address public router;
    address public tokenAddressFrom;
    address public tokenAddressTo;
    address public stream;
    address[] public path;

}
