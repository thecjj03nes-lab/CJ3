// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeviceManager {
    mapping(address => uint256) public deviceContribution;

    function reportContribution(address device, uint256 value) external {
        deviceContribution[device] += value;
    }
}
