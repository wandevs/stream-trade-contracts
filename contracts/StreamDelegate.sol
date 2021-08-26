// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./interfaces/IWWAN.sol";
import "./interfaces/ICollateralOracle.sol";
import "./interfaces/IStream.sol";
import "./StreamStorage.sol";

contract StreamDelegate is
    Initializable,
    AccessControl,
    IStream,
    StreamStorage
{
    using SafeERC20 for IERC20;

    uint public constant COLLATERAL_WASP = 100 ether;

    event Deposit(address indexed user, address indexed token, uint amount);

    event Withdraw(address indexed user, address indexed token, uint amount);

    event StartStream(address indexed from, address indexed to, address indexed token, uint amount, uint period);

    event StopStream(address indexed from, address indexed to, address indexed token);

    event RemoveStream(address indexed from, address indexed to, address indexed token);

    event DepositExhausted(address indexed from, address indexed token, uint indexed sessionId);

    event Transfer(address indexed from, address indexed to, uint amount);

    event TimeOut(address indexed from, address indexed to, uint indexed sessionId);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _wwan, address _wasp, address _collateralOracle)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        wwan = _wwan;
        wasp = _wasp;
        collateralOracle = _collateralOracle;
    }

    receive() external payable {
        require(msg.sender == address(wwan), "Only support value from WWAN"); // only accept WAN via fallback from the WWAN contract
    }

    function updateAssetReceive(address _user, address asset) internal {
        uint sessionCount;
        uint sessionId;
        uint m;
        uint pending;

        sessionCount = userAssetSessions[_user][asset].length();
        for (m=0; m<sessionCount; m++) {
            sessionId = userAssetSessions[_user][asset].at(m);
            SessionInfo storage sInfo = sessionInfo[sessionId];
            if (sInfo.receiver == _user) {
                require(sInfo.asset == asset, "session asset not correct");
                UserInfo storage senderInfo = userInfo[sInfo.sender][asset];
                UserInfo storage receiverInfo = userInfo[sInfo.receiver][asset];
                pending = pendingAmount(sessionId);
                if (senderInfo.amount >= pending) {
                    senderInfo.amount = senderInfo.amount.sub(pending);
                    if (block.timestamp >= sInfo.endTime) {
                        // end time arrive
                        sInfo.enable = false;
                        emit TimeOut(sInfo.sender, sInfo.receiver, sessionId);
                    }
                } else {
                    pending = senderInfo.amount;
                    senderInfo.amount = 0;
                    // run out of balance, Confiscate collateral
                    sInfo.dead = true;
                    sInfo.enable = false;
                    burnWasp(sInfo.collateralAmount);
                    delete sInfo.collateralAmount;
                    delete sInfo.collateralAsset;
                    emit DepositExhausted(sInfo.sender, sInfo.asset, sessionId);
                }
                sInfo.paid = sInfo.paid.add(pending);
                receiverInfo.amount = receiverInfo.amount.add(pending);
                uint updateTime = block.timestamp;
                if (updateTime >= sInfo.endTime) {
                    updateTime = sInfo.endTime;
                }
                sInfo.updateTime = updateTime;
            }
        }
    }

    function updateReceive(address _user) internal {
        uint assetLength = userAssets[_user].length();
        address asset;
        uint i;
        
        for (i=0; i<assetLength; i++) {
            asset = userAssets[_user].at(i);
            updateAssetReceive(_user, asset);
        }
    }

    function healthCheck(uint sessionId) public override view returns(bool) {
        SessionInfo storage sInfo = sessionInfo[sessionId];
        address asset = sInfo.asset;
        if (sInfo.enable) {
            UserInfo storage senderInfo = userInfo[sInfo.sender][asset];
            uint pending = pendingAmount(sessionId);
            if (senderInfo.amount >= pending) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    function getUserAssets(address _user) public override view returns(address[] memory assets, uint[] memory amounts) {
        uint length = userAssets[_user].length();
        assets = new address[](length);
        amounts = new uint[](length);
        uint i;
        for (i=0; i<length; i++) {
            assets[i] = userAssets[_user].at(i);
            amounts[i] = userInfo[_user][assets[i]].amount;
        }
    }

    function getUserAssetSessions(address _user, address _token) public override view returns(uint[] memory sessionIds) {
        address token = _token;
        if (token == address(0)) {
            token = wwan;
        }
        uint length = userAssetSessions[_user][token].length();
        sessionIds = new uint[](length);
        uint i;
        for (i=0; i<length; i++) {
            sessionIds[i] = userAssetSessions[_user][token].at(i);
        }
    }

    function getUserAssetSessionsCount(address _user, address _token) external override view returns(uint) {
        address token = _token;
        if (token == address(0)) {
            token = wwan;
        }
        return userAssetSessions[_user][token].length();
    }

    function getUserAssetSessionsRange(address _user, address _token, uint start, uint count) external override view returns(uint[] memory sessionIds) {
        address token = _token;
        if (token == address(0)) {
            token = wwan;
        }
        uint length = userAssetSessions[_user][token].length();
        require((start + count) <= length, "out of range");
        sessionIds = new uint[](count);
        uint i;
        for (i=0; i<count; i++) {
            sessionIds[i] = userAssetSessions[_user][token].at(start + i);
        }
    }

    function cleanReceiveSessions(address _token) external override {
        address token = _token;
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        address _user = _msgSender();
        uint length = userAssetSessions[_user][token].length();
        uint i;
        uint sessionId;
        for (i=0; i<length; i++) {
            sessionId = userAssetSessions[_user][token].at(i);
            SessionInfo storage si = sessionInfo[i];
            if (!si.enable && si.receiver == _user) {
                userAssetSessions[_user][token].remove(sessionId);
            }
        }
    }

    function deposit(address _token, uint256 _amount) public override payable {
        address token = _token;
        uint256 amount = _amount;
        address user = _msgSender();
        if (token == address(0)) { // token is wan
            amount = msg.value;
            token = wwan;
            IWWAN(wwan).deposit{value: amount}();
        } else {
            IERC20(token).safeTransferFrom(user, address(this), amount);
        }
        updateReceive(user);
        userAssets[user].add(token);
        userInfo[user][token].amount = userInfo[user][token].amount.add(amount);
        emit Deposit(user, token, amount);
    }

    function withdraw(address _token, uint256 amount, bool autoUnwrap) public override {
        address token = _token;
        address user = _msgSender();
        updateReceive(user);
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint realAmount = getUserRealTimeAsset(user, token);
        require(amount <= realAmount, "amount too large");
        userInfo[user][token].amount = userInfo[user][token].amount.sub(amount);
        
        if (token == wwan && autoUnwrap) {
            IWWAN(wwan).withdraw(amount);
            msg.sender.transfer(amount);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }
        emit Withdraw(user, token, amount);
    }

    function startStream(address _token, uint256 amount, address to, uint period) public {
        address token = _token;
        address user = _msgSender();
        if (token == address(0)) { // token is wan
            token = wwan;
        }

        require(period >= 600 && period <= (3600*24*365), "expired out of range");
        require(amount.div(period) > 0, "amount too little");

        // each session need deposit some WASP for collateral
        uint collateralAmount = takeCollateral(user, token, amount, period);

        updateReceive(user);
        
        uint currentAmount = getUserRealTimeAsset(user, token);
        require(currentAmount > 0, "deposit not enough");
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        SessionInfo storage sInfo = sessionInfo[sessionId];
        require(!sInfo.enable, "exist session");
        sInfo.sender = user;
        sInfo.receiver = to;
        sInfo.asset = token;
        sInfo.startTime = block.timestamp;
        sInfo.updateTime = block.timestamp;
        sInfo.endTime = block.timestamp + period;
        sInfo.streamRate = amount.div(period);
        sInfo.enable = true;
        //collateral 
        sInfo.collateralAsset = wasp;
        sInfo.collateralAmount = collateralAmount;

        userAssetSessions[user][token].add(sessionId);
        userAssetSessions[to][token].add(sessionId);
        userAssets[to].add(token);

        emit StartStream(user, to, _token, amount, period);
    }

    function isWorking(address _user, address _token, address to) public view returns(bool) {
        address token = _token;
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint sessionId = uint(keccak256(abi.encode(_user, to, token)));      
        SessionInfo storage sInfo = sessionInfo[sessionId];
        return sInfo.enable;
    }

    function takeCollateral(address user, address _token, uint256 amount, uint period) internal returns(uint) {
        uint collateralAmount = ICollateralOracle(collateralOracle).getCollateral(user, _token, amount, period);
        IERC20(wasp).safeTransferFrom(user, address(this), collateralAmount);
        return collateralAmount;
    }

    function stopStream(address _token, address to) public {
        address token = _token;
        address user = _msgSender();
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        SessionInfo storage sInfo = sessionInfo[sessionId];
        sInfo.enable = false;
        sInfo.endTime = block.timestamp;
        if (!sInfo.dead) {
            IERC20(sInfo.collateralAsset).safeTransfer(user, sInfo.collateralAmount);
            delete sInfo.collateralAmount;
            delete sInfo.collateralAsset;
        }

        emit StopStream(user, to, _token);
    }

    function transferAsset(address _token, address to, uint amount) public override {
        address asset = _token;
        if (asset == address(0)) { // token is wan
            asset = wwan;
        }

        address from = _msgSender();
        updateAssetReceive(from, _token);
        UserInfo storage uf = userInfo[from][asset];
        require(amount <= uf.amount, "User asset not enough");
        UserInfo storage ut = userInfo[to][asset];
        uf.amount = uf.amount.sub(amount);
        ut.amount = ut.amount.add(amount);
        userAssets[to].add(asset);
        emit Transfer(from, to, amount);
    }

    function removeStream(address user, address _token, address to) public onlyAdmin {
        address token = _token;
        if (token == address(0)) { // token is wan
            token = wwan;
        }
        uint sessionId = uint(keccak256(abi.encode(user, to, token)));
        userAssetSessions[user][token].remove(sessionId);
        SessionInfo storage sInfo = sessionInfo[sessionId];
        if (!sInfo.dead) {
            IERC20(sInfo.collateralAsset).safeTransfer(user, sInfo.collateralAmount);
            delete sInfo.collateralAmount;
            delete sInfo.collateralAsset;
        }
        delete sessionInfo[sessionId];
        emit RemoveStream(user, to, _token);
    }

    function pendingAmount(uint sessionId) public override view returns (uint) {
        SessionInfo storage sInfo = sessionInfo[sessionId];

        uint calcTime = block.timestamp;
        if (calcTime >= sInfo.endTime) {
            calcTime = sInfo.endTime;
        }

        if (calcTime > sInfo.updateTime) {
            return sInfo.streamRate.mul(calcTime - sInfo.updateTime);
        }
        return 0;
    }

    function claimSession(uint sessionId) external override {
        SessionInfo storage sInfo = sessionInfo[sessionId];
        require(sInfo.receiver == _msgSender(), "Only available for receiver");
        address asset = sInfo.asset;
        uint pending = pendingAmount(sessionId);
        if (pending > 0) {
            UserInfo storage senderInfo = userInfo[sInfo.sender][asset];
            if (senderInfo.amount >= pending) {
                senderInfo.amount = senderInfo.amount.sub(pending);
                if (block.timestamp >= sInfo.endTime) {
                    // end time arrive
                    sInfo.enable = false;
                    emit TimeOut(sInfo.sender, sInfo.receiver, sessionId);
                }
            } else {
                pending = senderInfo.amount;
                senderInfo.amount = 0;
                // run out of balance, Confiscate collateral
                sInfo.dead = true;
                sInfo.enable = false;
                burnWasp(sInfo.collateralAmount);
                delete sInfo.collateralAmount;
                delete sInfo.collateralAsset;
                emit DepositExhausted(sInfo.sender, sInfo.asset, sessionId);
            }
            sInfo.paid = sInfo.paid.add(pending);
            uint updateTime = block.timestamp;
            if (updateTime >= sInfo.endTime) {
                updateTime = sInfo.endTime;
            }
            sInfo.updateTime = updateTime;
            IERC20(asset).safeTransfer(sInfo.receiver, pending);
        }
    }

    function burnWasp(uint amount) internal {
        address burnAddress = address(0x1);
        IERC20(wasp).transfer(burnAddress, amount);
    }

    function getUserRealTimeAsset(address _user, address _token) public override view returns (uint) {
        address asset = _token;
        if (asset == address(0)) { // token is wan
            asset = wwan;
        }

        UserInfo storage ui = userInfo[_user][asset];
        uint amount = ui.amount;
        uint sessionCount = userAssetSessions[_user][asset].length();
        uint pending;
        uint sessionId;
        uint m;
        for (m=0; m<sessionCount; m++) {
            sessionId = userAssetSessions[_user][asset].at(m);
            SessionInfo storage sInfo = sessionInfo[sessionId];
            if (sInfo.enable) {
                pending = pendingAmount(sessionId);
                if (_user == sInfo.sender) {
                    if (amount > pending) {
                        amount = amount.sub(pending);
                    }
                } else {
                    UserInfo storage senderInfo = userInfo[sInfo.sender][asset];
                    if (senderInfo.amount > pending) {
                        amount = amount.add(pending);
                    } else {
                        amount = amount.add(senderInfo.amount);
                    }
                }
            }
        }
        return amount;
    }

    function getSessionAddress(uint sessionId) external override view returns (address, address) {
        SessionInfo storage si = sessionInfo[sessionId];
        return (si.sender, si.receiver);
    }
}
