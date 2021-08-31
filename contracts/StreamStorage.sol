
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract StreamStorage {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserInfo {
        uint amount;
    }

    struct SessionInfo {
        address sender;
        address receiver;
        address asset;
        uint startTime;
        uint endTime;
        uint updateTime;
        uint streamRate;
        uint paid;
        uint collateralAmount;
        address collateralAsset;
        bool enable;
        bool dead;
    }

    // user => assets
    mapping(address => EnumerableSet.AddressSet) userAssets;

    // user => asset => UserInfo
    mapping(address => mapping(address => UserInfo)) public userInfo;

    // user => asset => sessionId list
    mapping(address => mapping(address => EnumerableSet.UintSet)) userAssetSessions;

    // sessionId => sessionInfo
    mapping(uint => SessionInfo) public sessionInfo;

    // Wrapped WAN token address
    address public wwan;

    address public collateralOracle;
}
