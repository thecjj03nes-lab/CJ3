ZeropointPhoneServices - unlimited wifi, phone call, and text messaging1 $ZPP = $51 $ZPP = 1 month of service
// SPDX-License-Identifier: MITpragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";import "@openzeppelin/contracts/access/Ownable.sol";
contract ZeropointPhoneService is ERC20, Ownable {    uint256 public constant SUBSCRIPTION_COST = 5 * 10**18; // $5 in $ZPP    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    struct Subscription {        bool active;        uint256 expiry;    }
    mapping(address => Subscription) public subscriptions;
    constructor(address initialOwner) ERC20("ZeropointPhoneService", "ZPP") Ownable(initialOwner) {        _mint(initialOwner, 1000000 * 10**18);    }
    function subscribe(address user) external {        require(balanceOf(user) >= SUBSCRIPTION_COST, "Insufficient $ZPP");        _burn(user, SUBSCRIPTION_COST);        subscriptions[user] = Subscription(true, block.timestamp + SUBSCRIPTION_DURATION);    }
    function checkSubscription(address user) external view returns (bool, uint256) {        Subscription memory sub = subscriptions[user];        return (sub.active && sub.expiry > block.timestamp, sub.expiry);    }
    function mint(address to, uint256 amount) external onlyOwner {        _mint(to, amount);    }
    function burn(uint256 amount) external {        _burn(msg.sender, amount);    }}
