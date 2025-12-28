// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CloudMiningNFT is ERC721 {
    uint256 public id;

    constructor() ERC721("Goate Cloud Miner", "GCM") {}

    function mint(address to) external {
        _mint(to, ++id);
    }
}
