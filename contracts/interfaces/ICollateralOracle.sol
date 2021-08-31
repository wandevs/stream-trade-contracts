// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICollateralOracle {
    function getCollateral(address _token, uint256 amount, uint period, uint collateralIndex) external view returns(address, uint);
}

