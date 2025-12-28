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
