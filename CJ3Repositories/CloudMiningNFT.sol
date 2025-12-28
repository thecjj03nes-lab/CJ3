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






_____________________

contingency: 30% allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
