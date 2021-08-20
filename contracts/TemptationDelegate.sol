// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./TemptationStorage.sol";

contract TemptationDelegate is
    Initializable,
    AccessControl,
    TemptationStorage
{
    event Stake(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

}
