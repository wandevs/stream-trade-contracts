// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStream {
    //function getCollateral(address user, address _token, uint256 amount, uint period) external view returns(uint);
    function healthCheck(uint sessionId) external view returns(bool);

    function getUserAssetSessions(address _user, address _token) external view returns(uint[] memory sessionIds);

    function cleanReceiveSessions(address _token) external;

    function getUserAssets(address _user) external view returns(address[] memory assets, uint[] memory amounts);

    function deposit(address _token, uint256 _amount) external payable;

    function withdraw(address _token, uint256 amount) external;

    function transferAsset(address _token, address to, uint amount) external;

    function pendingAmount(uint sessionId) external view returns (uint);

    function getUserRealTimeAsset(address _user, address _token) external view returns (uint);

    function getSessionAddress(uint sessionId) external view returns (address, address);
}
