// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/Errors.sol";

abstract contract VaultBase {
    uint256 public constant BPS = 10_000;

    function _validateAllocations(uint256[] memory bps) internal pure {
        uint256 sum;
        for (uint256 i; i < bps.length; i++) sum += bps[i];
        if (sum != BPS) revert Errors.AllocationMismatch();
    }
}
