// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract TradeCarManager is Initializable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private cars;
    address public streamTank;

    struct CarInfo {
        string name;
        address fromToken;
        address toToken;
        address tradeAddress; //car address
    }

    // carAddress
    mapping(address => CarInfo) public carInfo;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _stream)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        streamTank = _stream;
    }

    function addCar(address _car, string calldata _name, address _fromToken, address _toToken) external onlyAdmin {
        cars.add(_car);
        carInfo[_car].name = _name;
        carInfo[_car].fromToken = _fromToken;
        carInfo[_car].toToken = _toToken;
        carInfo[_car].tradeAddress = _car;
    }

    function removeCar(address _car) external onlyAdmin {
        cars.remove(_car);
    }

    function configStreamTank(address _tank) external onlyAdmin {
        streamTank = _tank;
    }

    function getCars() external view returns(address[] memory) {
        address[] memory _cars = new address[](cars.length());
        for (uint i=0; i<cars.length(); i++) {
            _cars[i] = cars.at(i);
        }
        return _cars;
    }

    function getCarsInfo() external view returns(string[] memory _name, address[] memory _fromToken, address[] memory _toToken, address[] memory _tradeAddress) {
        _name = new string[](cars.length());
        _fromToken = new address[](cars.length());
        _toToken = new address[](cars.length());
        _tradeAddress = new address[](cars.length());
        for (uint i=0; i<cars.length(); i++) {
            address car = cars.at(i);
            _name[i] = carInfo[car].name;
            _fromToken[i] = carInfo[car].fromToken;
            _toToken[i] = carInfo[car].toToken;
            _tradeAddress[i] = carInfo[car].tradeAddress;
        }
    }
}
