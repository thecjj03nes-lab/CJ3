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
