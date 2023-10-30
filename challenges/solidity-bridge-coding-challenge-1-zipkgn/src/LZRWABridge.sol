// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {NonblockingLzApp} from "layerzero-solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import {LzLib} from "layerzero-solidity-examples/contracts/lzApp/libs/LzLib.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./RWA.sol";

error LZRWABridge__DailyLimitReached();
error LZRWABridge__ZeroAddress();
error LZRWABridge__AlreadyRegistered();
error LZRWABridge__NotRegistered();
error LZRWABridge__ZeroAmount();
error LZRWABridge__UnknownPacketType();
error LZRWABridge__InsufficientPendingAmount();

/// refer  https://github.com/LayerZero-Labs/wrapped-asset-bridge/blob/13c8582fc6492ff78966647c6ebd5913c192d602/contracts/WrappedTokenBridge.sol
/// refer https://layerzero.gitbook.io/docs/evm-guides/layerzero-integration-checklist
/// refer https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
contract LZRWABridge is NonblockingLzApp, ReentrancyGuard, Pausable {
    /// @notice A packet type used to identify messages requesting minting of RWAs
    uint8 public constant PT_MINT = 0;

    /// @notice RWA that can be bridged
    /// @dev [local RWA] => [remote chain] => [remote RWA]
    mapping(address => mapping(uint16 => address)) public localToRemote;

    /// @notice Total value bridged per RWA and remote chains per day
    /// @dev [remote chain] => [local RWA] => [day] => [bridged amount]
    mapping(uint16 => mapping(address => mapping(uint256 => uint256)))
        public totalSpentPerDay;

    /// @notice daily limit per RWA and remote chains
    /// @dev [remote chain] => [local RWA] => [limit]
    mapping(uint16 => mapping(address => uint)) public dailyLimit;

    /// @notice max transfer amount per transaction per remoteChain per local RWA
    /// @dev [remote chain] => [local RWA] =>  [amount]
    mapping(uint16 => mapping(address => uint256)) public maxPerTx;

    /// @notice approval threshold while receiving RWA from remoteChain
    /// @dev [local chain] => [remote RWA] =>  [amount]
    mapping(uint16 => mapping(address => uint256)) public approvalThresholds;

    /// @notice pending Mints from remoteChain
    /// @dev [recipient] => [local RWA] =>  [amount]
    mapping(address => mapping(address => uint256)) public pendingMints;

    event BridgeRWA(
        address localRWA,
        address remoteRWA,
        uint16 remoteChainId,
        address to,
        uint amount
    );
    event RegisterRWA(
        address localRWA,
        uint16 remoteChainId,
        address remoteRWA
    );
    event MintPending(address to, address localRWA, uint256 amount);

    event DailyLimit(
        address localRWA,
        uint16 remoteChainId,
        uint256 dailyLimit
    );
    event MaxPerTx(address localRWA, uint16 remoteChainId, uint256 maxPerTx);
    event SetApprovalThreshold(
        uint16 srcChainId,
        address remoteRWA,
        uint256 amount
    );

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    /// @notice Approve linkages between remote chain , localRWA and remoteRWA
    /// @dev only owner can map localRWA and to its remote counterpart identified via chain id
    function registerRWA(
        address _localRWA,
        uint16 _remoteChainId,
        address _remoteRWA
    ) external onlyOwner {
        if (_localRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (_remoteRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (!(localToRemote[_localRWA][_remoteChainId] == address(0)))
            revert LZRWABridge__AlreadyRegistered();

        localToRemote[_localRWA][_remoteChainId] = _remoteRWA;
        emit RegisterRWA(_localRWA, _remoteChainId, _remoteRWA);
    }

    /// @notice set daily limit of token transfer between source and destination chains
    /// @dev only owner can set daily limit of token transfer to remote chain
    function setDailyLimit(
        address _localRWA,
        uint16 _remoteChainId,
        uint256 _dailyLimit
    ) external onlyOwner {
        if (_localRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (localToRemote[_localRWA][_remoteChainId] == address(0))
            revert LZRWABridge__NotRegistered();

        dailyLimit[_remoteChainId][_localRWA] = _dailyLimit;
        emit DailyLimit(_localRWA, _remoteChainId, _dailyLimit);
    }

    /// @notice set bucket limit for bridging tokens
    /// @dev only owner can set max amount per tx while bridging tokens
    function setMaxPerTx(
        address _localRWA,
        uint16 _remoteChainId,
        uint256 _maxPerTx
    ) external onlyOwner {
        if (_localRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (localToRemote[_localRWA][_remoteChainId] == address(0))
            revert LZRWABridge__NotRegistered();

        maxPerTx[_remoteChainId][_localRWA] = _maxPerTx;
        emit MaxPerTx(_localRWA, _remoteChainId, _maxPerTx);
    }

    /// @notice configure the amount on destination beyond which second approval is required
    /// @dev only owner can set threshold amount for a RWA on destination chain
    function setApprovalThresholds(
        uint16 _srcChainId,
        address _remoteRWA,
        uint256 _amount
    ) external onlyOwner {
        if (_remoteRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (localToRemote[_remoteRWA][_srcChainId] == address(0))
            revert LZRWABridge__NotRegistered();
        approvalThresholds[_srcChainId][_remoteRWA] = _amount;
        emit SetApprovalThreshold(_srcChainId, _remoteRWA, _amount);
    }

    /// @notice Manual approval of cross chain token transfer
    /// @dev the owner can approve the pending mint if exceeds threshold
    function approveMint(
        address _recipient,
        address _rwa,
        uint256 _amount
    ) public onlyOwner {
        if (pendingMints[_recipient][_rwa] < _amount)
            revert LZRWABridge__InsufficientPendingAmount();
        pendingMints[_recipient][_rwa] -= _amount;
        RWA(_rwa).mint(_recipient, _amount);
    }

    /// @notice Bridges `localRWA` to the remote chain
    /// @dev Burns RWAs and sends LZ message to the remote chain to mint RWAs
    function bridge(
        address _localRWA,
        uint16 _remoteChainId,
        uint256 _amount,
        address _to,
        LzLib.CallParams calldata _callParams,
        bytes memory _adapterParams
    ) external payable nonReentrant whenNotPaused {
        if (_localRWA == address(0)) revert LZRWABridge__ZeroAddress();
        if (_to == address(0)) revert LZRWABridge__ZeroAddress();
        if (_amount == 0) revert LZRWABridge__ZeroAmount();

        address _remoteRWA = localToRemote[_localRWA][_remoteChainId];
        if (_remoteRWA == address(0)) revert LZRWABridge__ZeroAddress();

        if (!withinLimit(_remoteChainId, _localRWA, _amount))
            revert LZRWABridge__DailyLimitReached();

        totalSpentPerDay[_remoteChainId][_localRWA][getCurrentDay()] += _amount;

        RWA(_localRWA).burn(msg.sender, _amount);

        bytes memory _payload = abi.encode(PT_MINT, _localRWA, _to, _amount);
        _lzSend(
            _remoteChainId,
            _payload,
            _callParams.refundAddress,
            _callParams.zroPaymentAddress,
            _adapterParams,
            msg.value
        );

        emit BridgeRWA(_localRWA, _remoteRWA, _remoteChainId, _to, _amount);
    }

    /// @notice Receives RWAs  from the remote chain
    /// @dev Mints RWAs in response to LZ message from the remote chain
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal virtual override {
        (uint8 _packetType, address _remoteRWA, address _to, uint _amount) = abi
            .decode(_payload, (uint8, address, address, uint));
        if (_packetType != PT_MINT) revert LZRWABridge__UnknownPacketType();

        address _localRWA = localToRemote[_remoteRWA][_srcChainId];
        if (_localRWA == address(0)) revert LZRWABridge__ZeroAddress();

        if (_amount > approvalThresholds[_srcChainId][_remoteRWA]) {
            pendingMints[_to][_localRWA] += _amount;
            emit MintPending(_to, _localRWA, _amount);
        } else {
            RWA(_localRWA).mint(_to, _amount);
        }
    }

    /// Refer : https://github.com/omni/tokenbridge-contracts/blob/908a48107919d4ab127f9af07d44d47eac91547e/contracts/upgradeable_contracts/erc20_to_native/ForeignBridgeErcToNative.sol#L64

    /// @notice Checks whether the amount to transfer do not exceed daily and bucket limit
    /// @dev return true is amount of tokens to bridge is within daily and maxPerTx limit per chain per token
    function withinLimit(
        uint16 _remoteChainId,
        address _localRWA,
        uint256 _amount
    ) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay[_remoteChainId][_localRWA][
            getCurrentDay()
        ] + _amount;
        return
            dailyLimit[_remoteChainId][_localRWA] >= nextLimit &&
            _amount <= maxPerTx[_remoteChainId][_localRWA];
    }

    /// @notice Get the current time in terms of days
    /// @dev return the number of days elapsed since epoch
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
}
