// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWanSwapRouter02.sol";
import "./interfaces/IStream.sol";
import "./TemptationStorage.sol";

contract TemptationDelegate is Initializable, AccessControl, TemptationStorage {
    bytes32 public constant OPERATOR_ROLE = keccak256(bytes("OPERATOR_ROLE"));

    event Stake(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event Exchange(uint fromAmount, uint toAmount, uint sessionCount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address[] calldata _path, address _stream)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(OPERATOR_ROLE, _operator);

        IERC20(_tokenAddressTo).approve(_stream, uint(-1));
        IERC20(_tokenAddressFrom).approve(_router, uint(-1));

        router = _router;
        tokenAddressFrom = _tokenAddressFrom;
        tokenAddressTo = _tokenAddressTo;
        stream = _stream;
        path = _path;
    }

    function work() onlyOperator external {
        uint count = getSessionCount();
        rangeWork(0, count);
    }

    function getSessionCount() public view returns (uint) {
        return IStream(stream).getUserAssetSessionsCount(address(this), tokenAddressFrom);
    }

    function rangeWork(uint start, uint count) onlyOperator public {
        uint[] memory sessionIds = IStream(stream).getUserAssetSessionsRange(address(this), tokenAddressFrom, start, count);
        uint length = sessionIds.length;
        if (length == 0) {
            return;
        }
        uint i=0;
        uint sessionId;
        address sender;
        address[] memory senderList = new address[](length);
        uint[] memory senderAmounts = new uint[](length);
        uint totalAmount;
        uint beforeBalance;
        uint afterBalance;
        uint receivedAmount;

        // get token0
        for (i=0; i<count; i++) {
            sessionId = sessionIds[i];
            (sender,) = IStream(stream).getSessionAddress(sessionId);
            senderList[i] = sender;
            beforeBalance = IERC20(tokenAddressFrom).balanceOf(address(this));
            IStream(stream).claimSession(sessionId);
            afterBalance = IERC20(tokenAddressFrom).balanceOf(address(this));
            receivedAmount = afterBalance.sub(beforeBalance);
            senderAmounts[i] = receivedAmount;
            totalAmount = totalAmount.add(receivedAmount);
        }

        if (totalAmount > 0) {
            // swap token0 to token1
            beforeBalance = IERC20(tokenAddressTo).balanceOf(address(this));
            _swapTokensTo(totalAmount, address(this));
            afterBalance = IERC20(tokenAddressTo).balanceOf(address(this));
            receivedAmount = afterBalance.sub(beforeBalance);

            // send token1 to users
            IStream(stream).deposit(tokenAddressTo, receivedAmount);

            for (i=0; i<length; i++) {
                uint amount = senderAmounts[i];
                if (amount > 0) {
                    IStream(stream).transferAsset(tokenAddressTo, senderList[i], receivedAmount.mul(amount).div(totalAmount));
                }
            }
        }

        IStream(stream).cleanReceiveSessionsRange(tokenAddressFrom, start, count);

        emit Exchange(totalAmount, receivedAmount, count);
    }

    function _swapTokensTo(
        uint256 _amount,
        address _to
    ) internal {
        // make the swap
        IWanSwapRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                path,
                _to,
                block.timestamp
            );
    }
}
