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

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "no access");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "no access");
        _;
    }

    function initialize(address _admin, address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address _stream)
        external
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(OPERATOR_ROLE, _operator);

        IERC20(_tokenAddressTo).approve(_stream, uint(-1));

        router = _router;
        tokenAddressFrom = _tokenAddressFrom;
        tokenAddressTo = _tokenAddressTo;
        stream = _stream;
    }

    function work() onlyOperator external {
        uint[] memory sessionIds = IStream(stream).getUserAssetSessions(address(this), tokenAddressFrom);
        uint i=0;
        uint sessionId;
        address sender;
        uint pendingAmount;
        address[] memory senderList = new address[](sessionIds.length);
        uint[] memory senderAmounts = new uint[](sessionIds.length);
        uint totalAmount;
        uint beforeBalance;
        uint afterBalance;
        uint receivedAmount;

        // get token0
        for (i=0; i<sessionIds.length; i++) {
            sessionId = sessionIds[i];
            (sender,) = IStream(stream).getSessionAddress(sessionId);
            senderList[i] = sender;
            pendingAmount = IStream(stream).pendingAmount(sessionId);
            if (pendingAmount > 0) {
                beforeBalance = IERC20(tokenAddressFrom).balanceOf(address(this));
                IStream(stream).withdraw(tokenAddressFrom, pendingAmount, false);
                afterBalance = IERC20(tokenAddressFrom).balanceOf(address(this));
                receivedAmount = afterBalance.sub(beforeBalance);
                senderAmounts[i] = receivedAmount;
                totalAmount = totalAmount.add(receivedAmount);
            }
        }

        // swap token0 to token1
        beforeBalance = IERC20(tokenAddressTo).balanceOf(address(this));
        _swapTokens(tokenAddressFrom, tokenAddressTo, totalAmount);
        afterBalance = IERC20(tokenAddressTo).balanceOf(address(this));
        receivedAmount = afterBalance.sub(beforeBalance);

        // send token1 to users
        IStream(stream).deposit(tokenAddressTo, receivedAmount);

        for (i=0; i<sessionIds.length; i++) {
            uint amount = senderAmounts[i];
            IStream(stream).transferAsset(tokenAddressTo, senderList[i], receivedAmount.mul(amount).div(totalAmount));
        }

        IStream(stream).cleanReceiveSessions(tokenAddressFrom);
    }

    /**
     * @dev swap tokens to this address
     * @param _tokenAddressFrom address of from token
     * @param _tokenAddressTo address of to token
     * @param _amount amount of tokens
     */
    function _swapTokens(
        address _tokenAddressFrom,
        address _tokenAddressTo,
        uint256 _amount
    ) internal {
        _swapTokensTo(
            _tokenAddressFrom,
            _tokenAddressTo,
            _amount,
            address(this)
        );
    }

    /**
     * @dev swap tokens
     * @param _tokenAddressFrom address of from token
     * @param _tokenAddressTo address of to token
     * @param _amount amount of tokens
     */
    function _swapTokensTo(
        address _tokenAddressFrom,
        address _tokenAddressTo,
        uint256 _amount,
        address _to
    ) internal {
        address[] memory path = new address[](3);
        path[0] = _tokenAddressFrom;
        // path[1] = IWanSwapRouter02(router).WETH();
        // path[2] = _tokenAddressTo;
        path[1] = _tokenAddressTo;

        IERC20(_tokenAddressFrom).approve(router, _amount);

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
