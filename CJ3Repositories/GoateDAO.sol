// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/Errors.sol";

contract GoateDAO {
    struct Proposal {
        string description;
        uint256 yes;
        uint256 no;
        uint256 deadline;
        bool executed;
    }

    Proposal[] public proposals;

    function propose(string calldata desc) external {
        proposals.push(
            Proposal(desc, 0, 0, block.timestamp + 75 days, false)
        );
    }

    function vote(uint256 id, bool support) external payable {
        Proposal storage p = proposals[id];
        if (block.timestamp > p.deadline) revert Errors.InvalidVote();
        if (support) p.yes += msg.value;
        else p.no += msg.value;
    }
}


_____________________

contingency: 70% revenue allocated to $CJ3Reserve as $USDC, 30% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
