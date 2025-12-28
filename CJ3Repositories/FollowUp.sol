// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FollowUp {
    struct Post {
        address author;
        string content;
        uint256 timestamp;
    }

    Post[] public posts;

    function publish(string calldata content) external {
        posts.push(Post(msg.sender, content, block.timestamp));
    }
}


_____________________

contingency: 50% revenue allocated to $CJ3Reserve as $USDC, 50% to sdk/api user;
subscription fee: $25/ a month OR +5% revenue allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
