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
