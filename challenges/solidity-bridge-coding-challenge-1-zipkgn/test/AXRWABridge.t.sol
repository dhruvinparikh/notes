// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AXRWABridge} from "../src/AXRWABridge.sol";
import {RWA} from "src/RWA.sol";
import {MockGateway} from "axelar-solidity-sdk/contracts/test/mocks/MockGateway.sol";

/// refer : https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/fee271da28500034ad406e11194335c28628ce66/test/GMP/GMP.js
contract AXRWABridgeTest is Test {
    RWA localRWA;
    RWA remoteRWA;

    AXRWABridge localAXRWABridge;
    AXRWABridge remoteAXRWABridge;

    MockGateway localGateway;
    MockGateway remoteGateway;

    function setUp() public {
        // RWA
        localRWA = new RWA("rwa", "rwa", 6, address(this), 0);
        remoteRWA = new RWA("rwa", "rwa", 6, address(this), 0);

        // deploy stub
        localGateway = new MockGateway();
        remoteGateway = new MockGateway();

        // RWA bridge
        localAXRWABridge = new AXRWABridge(address(localGateway),address(0),address(remoteRWA));
        remoteAXRWABridge = new AXRWABridge(address(remoteGateway),address(0),address(localRWA));

        // deploy proxy
    }
}
