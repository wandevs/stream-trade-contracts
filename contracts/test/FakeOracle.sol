// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract FakeOracle {
    function getValue(bytes32 /*key*/) external view returns(uint) {
        address(this);
        return 1 ether;
    }
}
