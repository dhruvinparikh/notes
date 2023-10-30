// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LZRWABridge} from "../src/LZRWABridge.sol";
import {RWA} from "src/RWA.sol";
import {LZEndpointMock} from "layerzero-solidity-examples/contracts/lzApp/mocks/LZEndpointMock.sol";
import {LzLib} from "layerzero-solidity-examples/contracts/lzApp/libs/LzLib.sol";

error LZRWABridge__DailyLimitReached();
error LZRWABridge__ZeroAddress();
error LZRWABridge__AlreadyRegistered();
error LZRWABridge__NotRegistered();
error LZRWABridge__ZeroAmount();
error LZRWABridge__UnknownPacketType();
error LZRWABridge__InsufficientPendingAmount();

contract LZRWABridgeTest is Test {
    uint16 constant localChainId = 0;
    uint16 constant remoteChainId = 1;

    LZEndpointMock localEndpointMock;
    LZEndpointMock remoteEndpointMock;

    RWA localRWA;
    RWA remoteRWA;

    LZRWABridge localLZRWABridge;
    LZRWABridge remoteLZRWABridge;

    address recipient = makeAddr("alice");

    /// @notice A packet type used to identify messages requesting minting of RWAs
    uint8 public constant PT_MINT = 0;

    /// @notice A packet type used to identify messages requesting burning of remote RWAs
    uint8 public constant PT_BURN = 1;

    event RegisterRWA(
        address localRWA,
        uint16 remoteChainId,
        address remoteRWA
    );

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

    event BridgeRWA(
        address localRWA,
        address remoteRWA,
        uint16 remoteChainId,
        address to,
        uint amount
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event MintPending(address to, address localRWA, uint256 amount);

    function setUp() public {
        // stub
        localEndpointMock = new LZEndpointMock(localChainId);
        remoteEndpointMock = new LZEndpointMock(remoteChainId);

        // RWA
        localRWA = new RWA("rwa", "rwa", 6, address(this), 0);
        remoteRWA = new RWA("rwa", "rwa", 6, address(this), 0);

        // RWA Bridge
        localLZRWABridge = new LZRWABridge(address(localEndpointMock));
        remoteLZRWABridge = new LZRWABridge(address(remoteEndpointMock));

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        localEndpointMock.setDestLzEndpoint(
            address(remoteLZRWABridge),
            address(remoteEndpointMock)
        );
        remoteEndpointMock.setDestLzEndpoint(
            address(localLZRWABridge),
            address(localEndpointMock)
        );

        localRWA.grantRole(localRWA.MINTER_ROLE(), address(this));
        localRWA.grantRole(localRWA.BURNER_ROLE(), address(localLZRWABridge));
        remoteRWA.grantRole(
            remoteRWA.MINTER_ROLE(),
            address(remoteLZRWABridge)
        );

        localLZRWABridge.setTrustedRemote(
            remoteChainId,
            abi.encodePacked(
                address(remoteLZRWABridge),
                address(localLZRWABridge)
            )
        );

        remoteLZRWABridge.setTrustedRemote(
            localChainId,
            abi.encodePacked(
                address(localLZRWABridge),
                address(remoteLZRWABridge)
            )
        );

        localLZRWABridge.registerRWA(
            address(localRWA),
            remoteChainId,
            address(remoteRWA)
        );

        localLZRWABridge.setDailyLimit(
            address(localRWA),
            remoteChainId,
            100000000000
        );

        localLZRWABridge.setMaxPerTx(
            address(localRWA),
            remoteChainId,
            100000000
        );

        remoteLZRWABridge.registerRWA(
            address(localRWA),
            localChainId,
            address(remoteRWA)
        );

        remoteLZRWABridge.setApprovalThresholds(
            localChainId,
            address(localRWA),
            60000000
        );
    }

    function testSendLocalRWA() external {
        LzLib.CallParams memory _callParams = LzLib.CallParams({
            refundAddress: payable(address(this)),
            zroPaymentAddress: address(0)
        });
        localRWA.mint(address(this), 100000000);

        bytes memory _payload = abi.encode(
            PT_BURN,
            remoteRWA,
            recipient,
            50000000
        );

        (uint256 estimateFee, ) = localEndpointMock.estimateFees(
            remoteChainId,
            address(this),
            _payload,
            false,
            localEndpointMock.defaultAdapterParams()
        );

        vm.expectEmit(true, true, true, true, address(localRWA));
        emit Transfer(address(this), address(0), 50000000);
        vm.expectEmit(true, true, true, true, address(localLZRWABridge));
        emit BridgeRWA(
            address(localRWA),
            address(remoteRWA),
            remoteChainId,
            recipient,
            50000000
        );
        localLZRWABridge.bridge{value: estimateFee}(
            address(localRWA),
            remoteChainId,
            50000000,
            recipient,
            _callParams,
            bytes("")
        );

        assertEq(remoteRWA.balanceOf(recipient), 50000000);
    }

    // registerRWA, revert not owner
    function testRevertRegisterRWANotOwner() external {
        vm.prank(address(recipient));
        vm.expectRevert("Ownable: caller is not the owner");
        localLZRWABridge.registerRWA(
            address(localRWA),
            remoteChainId,
            address(remoteRWA)
        );
    }

    // registerRWA , localRWA revert LZRWABridge_ZeroAddress
    function testRevertRegisterRWALocalRWAZeroAddress() external {
        vm.expectRevert(LZRWABridge__ZeroAddress.selector);
        localLZRWABridge.registerRWA(
            address(0),
            remoteChainId,
            address(remoteRWA)
        );
    }

    // registerRWA, remoteRWA revert  LZRWABridge_ZeroAddress
    function testRevertRegisterRWARemoteRWAZeroAddress() external {
        vm.expectRevert(LZRWABridge__ZeroAddress.selector);
        localLZRWABridge.registerRWA(
            address(localRWA),
            remoteChainId,
            address(0)
        );
    }

    // registerRWA, revert LZRWABridge_AlreadyRegistered
    function testRevertRegisterRWAAlreadyRegistered() external {
        vm.expectRevert(LZRWABridge__AlreadyRegistered.selector);
        localLZRWABridge.registerRWA(
            address(localRWA),
            remoteChainId,
            address(remoteRWA)
        );
    }

    // registerRWA, assert RegisterRWA
    function testRegisterRWA() external {
        vm.expectEmit(true, true, true, true, address(localLZRWABridge));
        emit RegisterRWA(address(1), remoteChainId, address(2));
        localLZRWABridge.registerRWA(address(1), remoteChainId, address(2));
        assertEq(
            localLZRWABridge.localToRemote(address(1), remoteChainId),
            address(2)
        );
    }

    // setDailyLimit. revert not owner
    function testRevertSetDailyLimitNotOwner() external {
        vm.prank(recipient);
        vm.expectRevert("Ownable: caller is not the owner");
        localLZRWABridge.setDailyLimit(address(localRWA), remoteChainId, 100);
    }

    // setDailyLimit, revert localRWA revert LZRWABridge_ZeroAddress
    function testRevertSetDailyLimitLocalRWAZeroAddress() external {
        vm.expectRevert(LZRWABridge__ZeroAddress.selector);
        localLZRWABridge.setDailyLimit(address(0), remoteChainId, 100);
    }

    // setDailyLimit, revert LZRWABridge_NotRegistered
    function testRevertSetDailyLimitNotRegistered() external {
        vm.expectRevert(LZRWABridge__NotRegistered.selector);
        localLZRWABridge.setDailyLimit(address(1), remoteChainId, 100);
    }

    // setDailyLimit, assert DailyLimit
    function testSetDailyLimit() external {
        vm.expectEmit(true, true, true, true, address(localLZRWABridge));
        emit DailyLimit(address(localRWA), remoteChainId, 100);
        localLZRWABridge.setDailyLimit(address(localRWA), remoteChainId, 100);
        assertEq(
            localLZRWABridge.dailyLimit(remoteChainId, address(localRWA)),
            100
        );
    }

    // setMaxPerTx, revert not owner
    function testRevertSetMaxPerTxNotOwner() external {
        vm.prank(recipient);
        vm.expectRevert("Ownable: caller is not the owner");
        localLZRWABridge.setMaxPerTx(address(localRWA), remoteChainId, 100);
    }

    // setMaxPerTx, revert LZRWABridge_ZeroAddress
    function testRevertSetMaxperTxLocalRWAZeroAddress() external {
        vm.expectRevert(LZRWABridge__ZeroAddress.selector);
        localLZRWABridge.setMaxPerTx(address(0), remoteChainId, 100);
    }

    // setMaxPerTx, revert LZRWABridge_NotRegistered
    function testRevertSetMaxPerTxNotRegistered() external {
        vm.expectRevert(LZRWABridge__NotRegistered.selector);
        localLZRWABridge.setMaxPerTx(address(1), remoteChainId, 100);
    }

    // setMaxPerTx, assert MaxPerTx
    function testSetMaxPerTx() external {
        vm.expectEmit(true, true, true, true, address(localLZRWABridge));
        emit MaxPerTx(address(localRWA), remoteChainId, 100);
        localLZRWABridge.setMaxPerTx(address(localRWA), remoteChainId, 100);
        assertEq(
            localLZRWABridge.maxPerTx(remoteChainId, address(localRWA)),
            100
        );
    }

    // setApprovalThresolds, revert not owner
    function testRevertSetApprovalThresholdNotOwner() external {
        vm.prank(recipient);
        vm.expectRevert("Ownable: caller is not the owner");
        remoteLZRWABridge.setApprovalThresholds(
            localChainId,
            address(remoteRWA),
            100
        );
    }

    // setApprovalThresholds, remoteRWA ZeroAddress
    function testRevertSetApprovalThresholdsRemoteRWAZeroAddress() external {
        vm.expectRevert(LZRWABridge__ZeroAddress.selector);
        remoteLZRWABridge.setApprovalThresholds(localChainId, address(0), 100);
    }

    // setApprovalThresholds, not registered
    function testRevertSetApprovalThresholdsNotRegistered() external {
        vm.expectRevert(LZRWABridge__NotRegistered.selector);
        remoteLZRWABridge.setApprovalThresholds(
            remoteChainId,
            address(remoteRWA),
            100
        );
    }

    // setApprovalThresolds, assert SetApprovalThreshold
    function testSetApprovalThresholds() external {
        remoteLZRWABridge.registerRWA(
            address(remoteRWA),
            localChainId,
            address(localRWA)
        );
        vm.expectEmit(true, true, true, true, address(remoteLZRWABridge));
        emit SetApprovalThreshold(localChainId, address(remoteRWA), 100);
        remoteLZRWABridge.setApprovalThresholds(
            localChainId,
            address(remoteRWA),
            100
        );
        assertEq(
            remoteLZRWABridge.approvalThresholds(
                localChainId,
                address(remoteRWA)
            ),
            100
        );
    }

    // approveMint, revert not owner
    function testRevertApproveMintNotOwner() external {
        vm.prank(recipient);
        vm.expectRevert("Ownable: caller is not the owner");
        remoteLZRWABridge.approveMint(recipient, address(remoteRWA), 100);
    }

    // approveMint, revert LZRWABridge__InsufficientPendingAmount
    function testRevertApproveMint() external {
        vm.expectRevert(LZRWABridge__InsufficientPendingAmount.selector);
        remoteLZRWABridge.approveMint(recipient, address(remoteRWA), 100);
    }

    // approveMint, assert mint Transfer event
    function testBridgeApproveMint() external {
        LzLib.CallParams memory _callParams = LzLib.CallParams({
            refundAddress: payable(address(this)),
            zroPaymentAddress: address(0)
        });
        localRWA.mint(address(this), 100000000);

        bytes memory _payload = abi.encode(
            PT_BURN,
            remoteRWA,
            recipient,
            61000000
        );

        (uint256 estimateFee, ) = localEndpointMock.estimateFees(
            remoteChainId,
            address(this),
            _payload,
            false,
            localEndpointMock.defaultAdapterParams()
        );

        vm.expectEmit(true, true, true, true, address(remoteLZRWABridge));
        emit MintPending(recipient, address(remoteRWA), 61000000);

        localLZRWABridge.bridge{value: estimateFee}(
            address(localRWA),
            remoteChainId,
            61000000,
            recipient,
            _callParams,
            bytes("")
        );

        assertEq(
            remoteLZRWABridge.pendingMints(recipient, address(remoteRWA)),
            61000000
        );

        vm.expectEmit(true, true, true, true, address(remoteRWA));
        emit Transfer(address(0), recipient, 61000000);

        remoteLZRWABridge.approveMint(recipient, address(remoteRWA), 61000000);
    }

    // bridge , revert exceed daily limit
    function testRevertBridgeExceedDailyimit() external {
        localLZRWABridge.setDailyLimit(address(localRWA), remoteChainId, 50);
        LzLib.CallParams memory _callParams = LzLib.CallParams({
            refundAddress: payable(address(this)),
            zroPaymentAddress: address(0)
        });
        localRWA.mint(address(this), 100000000);

        bytes memory _payload = abi.encode(
            PT_BURN,
            remoteRWA,
            recipient,
            61000000
        );

        (uint256 estimateFee, ) = localEndpointMock.estimateFees(
            remoteChainId,
            address(this),
            _payload,
            false,
            localEndpointMock.defaultAdapterParams()
        );

        vm.expectRevert(LZRWABridge__DailyLimitReached.selector);

        localLZRWABridge.bridge{value: estimateFee}(
            address(localRWA),
            remoteChainId,
            61000000,
            recipient,
            _callParams,
            bytes("")
        );
    }

    function testRevertBridgeExceedBucketLimit() external {
        localLZRWABridge.setMaxPerTx(address(localRWA), remoteChainId, 50);
        LzLib.CallParams memory _callParams = LzLib.CallParams({
            refundAddress: payable(address(this)),
            zroPaymentAddress: address(0)
        });
        localRWA.mint(address(this), 100000000);

        bytes memory _payload = abi.encode(
            PT_BURN,
            remoteRWA,
            recipient,
            61000000
        );

        (uint256 estimateFee, ) = localEndpointMock.estimateFees(
            remoteChainId,
            address(this),
            _payload,
            false,
            localEndpointMock.defaultAdapterParams()
        );

        vm.expectRevert(LZRWABridge__DailyLimitReached.selector);

        localLZRWABridge.bridge{value: estimateFee}(
            address(localRWA),
            remoteChainId,
            61000000,
            recipient,
            _callParams,
            bytes("")
        );
    }

    receive() external payable {}
}
