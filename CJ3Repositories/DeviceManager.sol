// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeviceManager {
    mapping(address => uint256) public deviceContribution;

    function reportContribution(address device, uint256 value) external {
        deviceContribution[device] += value;
    }
}
_____________________

contingency: 30% revenue allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
