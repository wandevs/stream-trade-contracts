// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStream {
    function healthCheck(uint sessionId) external view returns(bool);

    function getUserAssetSessions(address _user, address _token) external view returns(uint[] memory sessionIds);

    function getUserAssetSessionsCount(address _user, address _token) external view returns(uint);

    function getUserAssetSessionsRange(address _user, address _token, uint start, uint count) external view returns(uint[] memory sessionIds);

    function cleanReceiveSessions(address _token) external;

    function cleanReceiveSessionsRange(address _token, uint start, uint count) external;

    function getUserAssets(address _user) external view returns(address[] memory assets, uint[] memory amounts);

    function deposit(address _token, uint256 _amount) external payable;

    function withdraw(address _token, uint256 amount, bool autoUnwrap) external;

    function transferAsset(address _token, address to, uint amount) external;

    function pendingAmount(uint sessionId) external view returns (uint);

    function getUserRealTimeAsset(address _user, address _token) external view returns (uint);

    function getSessionAddress(uint sessionId) external view returns (address, address);

    function getSessionStartTime(uint sessionId) external view returns (uint);

    function claimSession(uint sessionId) external;

    function getCollateral(address _token, uint256 amount, uint period, uint collateralIndex) external view returns(address, uint);
}
