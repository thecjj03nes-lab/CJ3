// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/VaultBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FinancialPool is VaultBase {
    IERC20 public immutable usdc;

    constructor(IERC20 _usdc) {
        usdc = _usdc;
    }

    function allocate(uint256 amount) external {
        usdc.transferFrom(msg.sender, address(this), amount);
    }
}


_____________________

contingency: 30% revenue allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
