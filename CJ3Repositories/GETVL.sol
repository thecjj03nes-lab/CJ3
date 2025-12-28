
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/VaultBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GETVL is VaultBase {
    IERC20 public immutable asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
    }
}
