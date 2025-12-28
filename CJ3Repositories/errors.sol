// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error Unauthorized();
    error InvalidAmount();
    error AllocationMismatch();
    error ExecutionPaused();
    error InvalidVote();
    error InsufficientBalance();
    error RouteFailed();
}
