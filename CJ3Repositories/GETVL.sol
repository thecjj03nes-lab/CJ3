
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


_____________________

contingency: 50% revenue allocated to $CJ3Reserve as $USDC, 50% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
