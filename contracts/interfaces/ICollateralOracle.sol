// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICollateralOracle {
    function getCollateral(address user, address _token, uint256 amount, uint period) external view returns(uint);
}

