
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract TemptationStorage {
    using SafeMath for uint256;

    struct UserInfo {
        address asset;
        uint amount;
        bool streaming;
        uint startTime;
        address streamTarget; // if == address(this) is swap otherwise is send
        uint streamRate; // wei per second
        address tradeTo; // wanswap trade to token
    }

    struct AssetInfo {

    }


    EnumerableSet.AddressSet users;

    EnumerableSet.AddressSet depositAssets;

    // user => assets list
    mapping(address => EnumerableSet.UintSet) userSessions;

    // user => sessionId => UserInfo
    mapping(address => mapping(uint => UserInfo)) userAssetInfo;

    // asset address => asset info
    mapping(address => AssetInfo) assetInfo;
}
