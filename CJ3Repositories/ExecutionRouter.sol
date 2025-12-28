// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/Errors.sol";

contract ExecutionRouter {
    bool public paused;

    event Routed(address indexed user, address asset, uint256 amount);
    event Reverted(address indexed user, address asset, uint256 amount);

    modifier notPaused() {
        if (paused) revert Errors.ExecutionPaused();
        _;
    }

    function pause() external {
        paused = true;
    }

    function unpause() external {
        paused = false;
    }

    function safeExecute(
        address asset,
        uint256 amount,
        address destination
    ) external notPaused {
        (bool ok,) = destination.call(
            abi.encodeWithSignature("receiveFunds(address,uint256)", asset, amount)
        );

        if (!ok) {
            emit Reverted(msg.sender, asset, amount);
            revert Errors.RouteFailed();
        }

        emit Routed(msg.sender, asset, amount);
    }
}

_____________________

contingency: 30% revenue allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)

