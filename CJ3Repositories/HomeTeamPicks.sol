// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HomeTeamPicks {
    struct Pick {
        address user;
        string prediction;
        uint256 stake;
    }

    Pick[] public picks;

    function submitPick(string calldata prediction) external payable {
        picks.push(Pick(msg.sender, prediction, msg.value));
    }
}


_____________________

contingency: 80% revenue allocated to $CJ3Reserve as $USDC, 20% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
