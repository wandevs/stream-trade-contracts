// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/ICollateralOracle.sol";

contract CollateralOracle is ICollateralOracle {
    function getCollateral(address /*user*/, address /*_token*/, uint256 /*amount*/, uint /*period*/) override external view returns(uint) {
        return 100 ether;
    }
}
