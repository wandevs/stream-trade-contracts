// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./TemptationStorage.sol";

contract TemptationDelegate is
    Initializable,
    AccessControl,
    TemptationStorage
{
    event Stake(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _tokenAddress)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        erc20Token = ERC20(_tokenAddress);
    }

    function name() external view returns (string memory) {
        return erc20Token.name();
    }

    function symbol() external view returns (string memory) {
        return erc20Token.symbol();
    }

    function decimals() external view returns (uint8) {
        return erc20Token.decimals();
    }

    function totalSupply() external view returns (uint256) {
        return erc20Token.totalSupply();
    }

    function balanceOf(address account) external view returns (uint256) {
        return erc20Token.balanceOf(account);
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return erc20Token.allowance(owner, spender);
    }

    function mint(address account, uint256 value)
        public
        onlyAdmin
        returns (bool)
    {
        erc20Token.safeTransfer(account, value);
        return true;
    }

    function burn(address account, uint256 value)
        public
        onlyAdmin
        returns (bool)
    {
        erc20Token.safeTransferFrom(account, address(this), value);
        return true;
    }

    function getStakersCount()
        external
        view
        returns (uint256)
    {
        return stakers.length();
    }

    function getStakerAmount(address _user)
        external
        view
        returns (uint256)
    {
        return stakersAmount[_user];
    }

    function getStakers(uint start, uint length)
        external
        view
        returns (address[] memory)
    {
        address[] memory stakerAddress = new address[](length);
        for (uint i=0; i<length; i++) {
            stakerAddress[i] = stakers.at(i + start);
        }
        return stakerAddress;
    }

    function stake(uint256 amount) external {
        erc20Token.safeTransferFrom(msg.sender, address(this), amount);
        stakers.add(msg.sender);
        stakersAmount[msg.sender] = stakersAmount[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit Stake(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        uint balance = erc20Token.balanceOf(address(this));
        require(amount <= balance, "Pool balance not enough");
        stakersAmount[msg.sender] = stakersAmount[msg.sender].sub(amount);
        if (stakersAmount[msg.sender] == 0) {
            stakers.remove(msg.sender);
        }
        totalStaked = totalStaked.sub(amount);
        erc20Token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}
