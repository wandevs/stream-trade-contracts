
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract StreamStorage {
    using SafeMath for uint256;

    struct UserInfo {
        uint amount;
    }

    struct SessionInfo {
        address sender;
        address reciever;
        address asset;
        uint updateTime;
        uint streamRate;
        uint paid;
        bool enable;
    }

    // user => assets
    mapping(address => EnumerableSet.AddressSet) userAssets;

    // user => asset => UserInfo
    mapping(address => mapping(address => UserInfo)) userInfo;

    // user => asset => sessionId list
    mapping(address => mapping(address => EnumerableSet.UintSet)) userAssetSessions;

    // sessionId => sessionInfo
    mapping(uint => SessionInfo) sessionInfo;

    // Wrapped WAN token address
    address public wwan;
}
