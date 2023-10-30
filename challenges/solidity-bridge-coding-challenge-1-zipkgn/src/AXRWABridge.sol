// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {IAxelarGateway} from "axelar-solidity-sdk/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelar-solidity-sdk/contracts/interfaces/IAxelarGasService.sol";
import {AxelarExecutable} from "axelar-solidity-sdk/contracts/executable/AxelarExecutable.sol";
import {Upgradable} from "axelar-solidity-sdk/contracts/upgradable/Upgradable.sol";
import {StringToAddress, AddressToString} from "axelar-solidity-sdk/contracts/libs/AddressString.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "./RWA.sol";

error AXRWABridge__DailyLimitReached();
error AXRWABridge_ZeroAddress();
error AXRWABridge_AlreadyRegistered();
error AXRWABridge_NotRegistered();
error AXRWABridge_ZeroAmount();
error AXRWABridge__UnknownPacketType();
error AXRWABridge__InsufficientPendingAmount();
error AXRWABridge__AlreadyInitialized();

/// Refer : https://github.com/axelarnetwork/axelar-examples/blob/b844030a5cdcf63085bc95def3bd1d5217b48de1/examples/evm/cross-chain-token/ERC20CrossChain.sol

contract AXRWABridge is
    AxelarExecutable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Upgradable
{
    using StringToAddress for string;
    using AddressToString for address;

    /// @notice A packet type used to identify messages requesting minting of RWAs
    uint8 public constant PT_MINT = 0;

    IAxelarGasService public immutable gasService;

    address public immutable destinationAddress;

    /// @notice RWA that can be bridged
    /// @dev [local RWA] => [remote chain hash] => [remote RWA]
    mapping(address => mapping(bytes32 => address)) public localToRemote;

    /// @notice Total value bridged per RWA and remote chains per day
    /// @dev [remote chain hash] => [local RWA] => [day] => [bridged amount]
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256)))
        public totalSpentPerDay;

    /// @notice daily limit per RWA and remote chains
    /// @dev [remote chain hash] => [local RWA] => [limit]
    mapping(bytes32 => mapping(address => uint)) public dailyLimit;

    /// @notice max transfer amount per transaction per remoteChain per local RWA
    /// @dev [remote chain hash] => [local RWA] =>  [amount]
    mapping(bytes32 => mapping(address => uint256)) public maxPerTx;

    /// @notice approval threshold while receiving RWA from remoteChain
    /// @dev [local chain hash] => [remote RWA] =>  [amount]
    mapping(bytes32 => mapping(address => uint256)) public approvalThresholds;

    /// @notice pending Mints from remoteChain
    /// @dev [recipient] => [local RWA] =>  [amount]
    mapping(address => mapping(address => uint256)) public pendingMints;

    event FalseSender(string sourceChain, string sourceAddress);
    event MintPending(address to, address localRWA, uint256 amount);
    event RegisterRWA(
        address localRWA,
        string remoteChainId,
        address remoteRWA
    );
    event DailyLimit(address localRWA, string remoteChain, uint256 dailyLimit);
    event MaxPerTx(address localRWA, string remoteChain, uint256 maxPerTx);
    event SetApprovalThreshold(
        string srcChainId,
        address remoteRWA,
        uint256 amount
    );

    constructor(
        address _gateway,
        address _gasReceiver,
        address _destinationAddress
    ) AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasReceiver);
        destinationAddress = _destinationAddress;
    }

    function _setup(bytes calldata) internal override {
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    /// @notice Approve linkages between remote chain , localRWA and remoteRWA
    /// @dev only owner can map localRWA and to its remote counterpart identified via chain id
    function registerRWA(
        address _localRWA,
        string calldata _remoteChain,
        address _remoteRWA
    ) external onlyOwner {
        if (_localRWA == address(0)) revert AXRWABridge_ZeroAddress();
        if (_remoteRWA == address(0)) revert AXRWABridge_ZeroAddress();
        bytes32 _remoteChainHash = keccak256(abi.encodePacked(_remoteChain));
        if (!(localToRemote[_localRWA][_remoteChainHash] == address(0)))
            revert AXRWABridge_AlreadyRegistered();

        localToRemote[_localRWA][_remoteChainHash] = _remoteRWA;
        emit RegisterRWA(_localRWA, _remoteChain, _remoteRWA);
    }

    /// @notice set daily limit of token transfer between source and destination chains
    /// @dev only owner can set daily limit of token transfer to remote chain
    function setDailyLimit(
        address _localRWA,
        string calldata _remoteChain,
        uint256 _dailyLimit
    ) external onlyOwner {
        if (_localRWA == address(0)) revert AXRWABridge_ZeroAddress();
        bytes32 _remoteChainHash = keccak256(abi.encodePacked(_remoteChain));
        if (localToRemote[_localRWA][_remoteChainHash] == address(0))
            revert AXRWABridge_NotRegistered();

        dailyLimit[_remoteChainHash][_localRWA] = _dailyLimit;
        emit DailyLimit(_localRWA, _remoteChain, _dailyLimit);
    }

    /// @notice set bucket limit for bridging tokens
    /// @dev only owner can set max amount per tx while bridging tokens
    function setMaxPerTx(
        address _localRWA,
        string calldata _remoteChain,
        uint256 _maxPerTx
    ) external onlyOwner {
        if (_localRWA == address(0)) revert AXRWABridge_ZeroAddress();
        bytes32 _remoteChainHash = keccak256(abi.encodePacked(_remoteChain));
        if (localToRemote[_localRWA][_remoteChainHash] == address(0))
            revert AXRWABridge_NotRegistered();

        maxPerTx[_remoteChainHash][_localRWA] = _maxPerTx;
        emit MaxPerTx(_localRWA, _remoteChain, _maxPerTx);
    }

    /// @notice configure the amount on destination beyond which second approval is required
    /// @dev only owner can set threshold amount for a RWA on destination chain
    function setApprovalThresholds(
        string calldata _srcChain,
        address _remoteRWA,
        uint256 _amount
    ) external onlyOwner {
        approvalThresholds[keccak256(abi.encodePacked(_srcChain))][
            _remoteRWA
        ] = _amount;

        emit SetApprovalThreshold(_srcChain, _remoteRWA, _amount);
    }

    /// @notice Manual approval of cross chain token transfer
    /// @dev the owner can approve the pending mint if exceeds threshold
    function approveMint(
        address _recipient,
        address _rwa,
        uint256 _amount
    ) public onlyOwner {
        if (pendingMints[_recipient][_rwa] < _amount)
            revert AXRWABridge__InsufficientPendingAmount();
        pendingMints[_recipient][_rwa] -= _amount;
        RWA(_rwa).mint(_recipient, _amount);
    }

    /// @notice Bridges `localRWA` to the remote chain
    /// @dev Burns RWAs and sends AX message to the remote chain to mint RWAs
    function bridge(
        address _localRWA,
        string calldata _remoteChain,
        uint256 _amount,
        address _to
    ) external payable nonReentrant whenNotPaused {
        if (_localRWA == address(0)) revert AXRWABridge_ZeroAddress();
        if (_to == address(0)) revert AXRWABridge_ZeroAddress();
        if (_amount == 0) revert AXRWABridge_ZeroAmount();
        if (msg.value == 0) revert AXRWABridge_ZeroAmount();

        bytes32 _remoteChainHash = keccak256(abi.encodePacked(_remoteChain));

        address _remoteRWA = localToRemote[_localRWA][_remoteChainHash];

        if (_remoteRWA == address(0)) revert AXRWABridge_ZeroAddress();

        if (!withinLimit(_remoteChainHash, _localRWA, _amount))
            revert AXRWABridge__DailyLimitReached();

        totalSpentPerDay[_remoteChainHash][_localRWA][
            getCurrentDay()
        ] += _amount;

        RWA(_localRWA).burn(msg.sender, _amount);
        bytes memory payload = abi.encode(PT_MINT, _localRWA, _to, _amount);
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _remoteChain,
            destinationAddress.toString(),
            payload,
            msg.sender
        );
        gateway.callContract(
            _remoteChain,
            destinationAddress.toString(),
            payload
        );
    }

    /// @notice Receives RWAs  from the remote chain
    /// @dev Mints RWAs in response to LZ message from the remote chain
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        if (_sourceAddress.toAddress() != address(this)) {
            emit FalseSender(_sourceChain, _sourceAddress);
            return;
        }
        (
            uint8 _packetType,
            address _remoteRWA,
            address _to,
            uint256 _amount
        ) = abi.decode(_payload, (uint8, address, address, uint256));

        if (_packetType != PT_MINT) revert AXRWABridge__UnknownPacketType();

        bytes32 _remoteChainHash = keccak256(abi.encodePacked(_sourceChain));

        address _localRWA = localToRemote[_remoteRWA][_remoteChainHash];

        if (_localRWA == address(0)) revert AXRWABridge_ZeroAddress();

        if (_amount > approvalThresholds[_remoteChainHash][_remoteRWA]) {
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
        bytes32 _remoteChainHash,
        address _localRWA,
        uint256 _amount
    ) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay[_remoteChainHash][_localRWA][
            getCurrentDay()
        ] + _amount;
        return
            dailyLimit[_remoteChainHash][_localRWA] >= nextLimit &&
            _amount <= maxPerTx[_remoteChainHash][_localRWA];
    }

    /// @notice Get the current time in terms of days
    /// @dev return the number of days elapsed since epoch
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("AXRWABridge");
    }
}
