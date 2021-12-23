// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWanSwapRouter02.sol";
import "./interfaces/IStream.sol";

contract TradeCar is Initializable, AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    address public router;
    address public tokenAddressFrom;
    address public tokenAddressTo;
    address public stream;
    address[] public path;

    // user => historyIds
    mapping(address => EnumerableSet.UintSet) private userHistory;

    struct HistoryInfo {
        address sellToken;
        address buyToken;
        uint sellAmount;
        uint buyAmount;
        uint startTime;
    }

    // historyId => historyInfo
    mapping(uint => HistoryInfo) public historyInfo;

    bytes32 public constant OPERATOR_ROLE = keccak256(bytes("OPERATOR_ROLE"));

    event Stake(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event Exchange(uint fromAmount, uint toAmount, uint sessionCount);

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address[] calldata _path, address _stream)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _operator);
        _setupRole(OPERATOR_ROLE, _operator);

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
        
        // for stack too deep
        {
            uint i=0;
            uint sessionId;
            address sender;
            address[] memory senderList = new address[](length);
            uint[] memory senderAmounts = new uint[](length);
            uint totalAmount;
            uint beforeBalance;
            uint afterBalance;
            uint receivedAmount;
            uint _startTime;
            uint _payAmount;

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

                _startTime = IStream(stream).getSessionStartTime(sessionId);
                saveSellHistory(sender, _startTime, sessionId, tokenAddressFrom, tokenAddressTo, receivedAmount);
            }

            if (totalAmount > 0) {
                // swap token0 to token1
                beforeBalance = IERC20(tokenAddressTo).balanceOf(address(this));
                _swapTokensTo(totalAmount, address(this));
                afterBalance = IERC20(tokenAddressTo).balanceOf(address(this));
                receivedAmount = afterBalance.sub(beforeBalance);

                IERC20(tokenAddressTo).approve(stream, receivedAmount);
                // send token1 to users
                IStream(stream).deposit(tokenAddressTo, receivedAmount);

                for (i=0; i<length; i++) {
                    if (senderAmounts[i] > 0) {
                        _payAmount = receivedAmount.mul(senderAmounts[i]).div(totalAmount);
                        IStream(stream).transferAsset(tokenAddressTo, senderList[i], _payAmount);
                        
                        _startTime = IStream(stream).getSessionStartTime(sessionIds[i]);
                        saveBuyHistory(senderList[i], _startTime, sessionIds[i], _payAmount);
                    }
                }
            }
        }
        
        IStream(stream).cleanReceiveSessionsRange(tokenAddressFrom, start, count);
    }

    function getHistoryCount(address _user) public view returns (uint) {
        return userHistory[_user].length();
    }

    function getHistoryIds(address _user, uint _offset, uint _count) public view returns (uint[] memory) {
        uint[] memory ret = new uint[](_count);
        for (uint i=0; i<_count; i++) {
            ret[i] = userHistory[_user].at(_offset + i);
        }
    }

    function _swapTokensTo(
        uint256 _amount,
        address _to
    ) internal {
        IERC20(tokenAddressFrom).approve(router, _amount);
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

    function saveSellHistory(address _user, uint _startTime, uint _sessionId, address _sellToken, address _buyToken, uint _sellAmount) private {
        uint historyId = uint(keccak256(abi.encode(_sessionId, _startTime)));
        userHistory[_user].add(historyId);
        HistoryInfo storage info = historyInfo[historyId];
        if (info.startTime == 0) {
            info.startTime = _startTime;
        }

        if (info.sellToken == address(0)) {
            info.sellToken = _sellToken;
        }

        if (info.buyToken == address(0)) {
            info.buyToken = _buyToken;
        }

        info.sellAmount += _sellAmount;
    }

    function saveBuyHistory(address _user, uint _startTime, uint _sessionId, uint _buyAmount) private {
        uint historyId = uint(keccak256(abi.encode(_sessionId, _startTime)));
        userHistory[_user].add(historyId);
        HistoryInfo storage info = historyInfo[historyId];
        info.buyAmount += _buyAmount;
    }

}
