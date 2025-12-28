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
_____________________

contingency: 30% revenue allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
