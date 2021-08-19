// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./interfaces/IWWAN.sol";
import "./StreamStorage.sol";

contract StreamDelegate is
    Initializable,
    AccessControl,
    StreamStorage
{
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, address indexed token, uint amount);

    event Withdraw(address indexed user, address indexed token, uint amount);

    event StartStream(address indexed from, address indexed to, address indexed token, uint streamRate);

    event StopStream(address indexed from, address indexed to, address indexed token, uint streamRate);

    event RemoveStream(address indexed from, address indexed to, address indexed token, uint streamRate);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _wwan)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    receive() external payable {
        require(msg.sender == address(wwan), "Only support value from WWAN"); // only accept WAN via fallback from the WWAN contract
    }

    function update(address _user) public {
        uint assetLength = userAssets[_user].length();
        uint sessionCount;
        address asset;
        uint sessionId;
        uint i;
        uint m;
        uint pending;
        
        for (i=0; i<assetLength; i++) {
            asset = userAssets[_user].at(i);
            sessionCount = userAssetSessions[_user][asset].length();
            for (m=0; m<sessionCount; m++) {
                sessionId = userAssetSessions[_user][asset].at(m);
                SessionInfo storage sInfo = sessionInfo[sessionId];
                if (sInfo.enable) {
                    UserInfo storage si = userInfo[sInfo.sender][asset];
                    UserInfo storage ri = userInfo[sInfo.reciever][asset];
                    pending = pendingAmount(sessionId);
                    if (_user == sInfo.sender && ui.amount >= pending) {

                    }
                }
            }
        }
    }

    function healthCheck(uint sessionId) public view returns(bool) {
        return true;
    }

    function deposit(address _token, uint256 _amount) public {
        address token = _token;
        uint256 amount = _amount;
        uint256 user = _msgSender();
        if (token == address(0)) { // token is wan
            IWWAN(wwan).deposit{value: amounts[0]}();
            token = wwan;
            amount = msg.value;
        } else {
            IERC20(token).safeTransferFrom(user, address(this), amount);
        }

        update(user);
        userAssets[user].add(token);
        userInfo[user][token].amount = userInfo[user][token].amount.add(amount);
        emit Deposit(user, token, amount);
    }

    function withdraw(address _token, uint256 amount) public {
        address token = _token;
        uint256 user = _msgSender();
        update(user);
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint currentAmount = userInfo[user][token].amount;
        require(amount <= currentAmount, "amount too large");
        userInfo[user][token].amount = userInfo[user][token].amount.sub(amount);

        if (userInfo[user][token].amount == 0) {
            userAssets[user].remove(token);
        }
        
        if (token == wwan) {
            IWWAN(wwan).withdraw(amount);
            msg.sender.transfer(amount);
        } else {
            IERC20(token).safeTransferFrom(address(this), user, amount);
        }
        emit Withdraw(user, token, amount);
    }

    function startStream(address _token, uint256 streamRate, address to) public {
        address token = _token;
        uint256 user = _msgSender();
        update(user);
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint currentAmount = userInfo[user][token].amount;
        require(currentAmount > 0, "deposit not enough");
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        SessionInfo storage sInfo = sessionInfo[sessionId];
        sInfo.sender = user;
        sInfo.reciever = to;
        sInfo.asset = token;
        sInfo.startTime = block.timestamp;
        sInfo.streamRate = streamRate;
        sInfo.enable = true;

        userAssetSessions[user][token].add(sessionId);
        userAssetSessions[to][token].add(sessionId);

        emit StartStream(user, to, _token, streamRate);
    }

    function stopStream(address _token, address to) public {
        update();
        address token = _token;
        uint256 user = _msgSender();
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        SessionInfo storage sInfo = sessionInfo[sessionId];
        sInfo.enable = false;

        emit StopStream(user, to, _token, 0);
    }

    function removeStream(address _token, address to) public {
        update();
        address token = _token;
        uint256 user = _msgSender();
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        userAssetSessions[user][token].remove(sessionId);
        delete sessionInfo[sessionId];

        emit RemoveStream(user, to, _token, 0);
    }

    function pendingAmount(uint sessionId) public view returns (uint) {
        SessionInfo storage sInfo = sessionInfo[sessionId];
        return sInfo.streamRate.mul(block.timestamp - sInfo.updateTime);
    }
}
