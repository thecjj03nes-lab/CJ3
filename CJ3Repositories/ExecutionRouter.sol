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
