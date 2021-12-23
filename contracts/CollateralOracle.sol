// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


import "./interfaces/ICollateralOracle.sol";

interface ISymbol {
    function symbol() external view returns(string memory);
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getValue(bytes32 key) external view returns(uint);
}

contract CollateralOracle is ICollateralOracle, Initializable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public oracle;

    uint public MAX;
    uint public MIN;

    EnumerableSet.AddressSet tokens;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _wasp, address _wand, address _oracle)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        tokens.add(_wasp);
        tokens.add(_wand);
        oracle = _oracle;
        MAX = 1000 ether;
        MIN = 10 ether;
    }

    function addToken(address _token) public onlyAdmin {
        tokens.add(_token);
    }

    function removeToken(address _token) public onlyAdmin {
        tokens.remove(_token);
    }

    function configOracle(address _oracle) public onlyAdmin {
        oracle = _oracle;
    }

    function configMax(uint _max, uint _min) public onlyAdmin {
        MAX = _max;
        MIN = _min;
    }

    function getTokens() public view returns(address[] memory) {
        address[] memory _tokens = new address[](tokens.length());
        uint i;
        for (i = 0; i<tokens.length(); i++) {
            _tokens[i] = tokens.at(i);
        }

        return _tokens;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getCollateral(address _token, uint256 amount, uint /*period*/, uint collateralIndex) override external view returns(address, uint) {
        address payToken = tokens.at(collateralIndex);
        uint payAmount = 100 ether;

        string memory symbol = ISymbol(_token).symbol();
        uint256 decimals = ISymbol(_token).decimals();

        if (keccak256(bytes(symbol)) == keccak256(bytes("WWAN"))) {
            symbol = "WAN";
        }

        string memory paySymbol = ISymbol(payToken).symbol();

        uint price = IOracle(oracle).getValue(stringToBytes32(symbol));

        uint payPrice = IOracle(oracle).getValue(stringToBytes32(paySymbol));

        uint usdValue = amount * price / (10 ** decimals);

        payAmount = usdValue / 100 * 1e18 / payPrice;

        if (payAmount < MIN.mul(1 ether).div(payPrice)) {
            payAmount = MIN.mul(1 ether).div(payPrice);
        }

        if (payAmount > MAX.mul(1 ether).div(payPrice)) {
            payAmount = MAX.mul(1 ether).div(payPrice);
        }

        payAmount = payAmount / 10 ether * 10 ether;
        
        return (payToken, payAmount);
    }
}
