// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WisdomMarket
 * @notice Prediction market where agents stake tokens on beliefs. Time is the oracle.
 * @dev Built by 0xLaVaN (ERC-8004 Agent #1284) for Base Builder Quest
 */
contract WisdomMarket is Ownable {
    using SafeERC20 for IERC20;

    enum MarketStatus { Active, Resolved, Expired }
    enum Position { Yes, No }

    struct Market {
        string question;
        address creator;
        uint256 resolutionTime;
        uint256 yesPool;
        uint256 noPool;
        MarketStatus status;
        Position outcome;
        uint256 createdAt;
    }

    struct Stake {
        uint256 yesAmount;
        uint256 noAmount;
        bool claimed;
    }

    IERC20 public stakingToken; // $LAVA
    uint256 public marketCount;
    uint256 public protocolFeeBps = 200; // 2%
    uint256 public minStake = 1e18; // 1 token minimum
    uint256 public accumulatedFees;

    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => Stake)) public stakes;
    
    // ERC-8004 identity tracking
    mapping(address => uint256) public agentWins;
    mapping(address => uint256) public agentLosses;
    mapping(address => uint256) public agentTotalStaked;

    event MarketCreated(uint256 indexed id, string question, address creator, uint256 resolutionTime);
    event Staked(uint256 indexed id, address indexed agent, Position position, uint256 amount);
    event MarketResolved(uint256 indexed id, Position outcome);
    event Claimed(uint256 indexed id, address indexed agent, uint256 payout);

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }

    function createMarket(
        string calldata question,
        uint256 resolutionTime,
        Position initialPosition,
        uint256 initialStake
    ) external returns (uint256 marketId) {
        require(resolutionTime > block.timestamp, "Resolution must be future");
        require(resolutionTime <= block.timestamp + 90 days, "Max 90 day markets");
        require(initialStake >= minStake, "Below minimum stake");

        marketId = marketCount++;
        
        markets[marketId] = Market({
            question: question,
            creator: msg.sender,
            resolutionTime: resolutionTime,
            yesPool: 0,
            noPool: 0,
            status: MarketStatus.Active,
            outcome: Position.Yes, // default, irrelevant until resolved
            createdAt: block.timestamp
        });

        // Creator must stake on their prediction
        _stake(marketId, initialPosition, initialStake);

        emit MarketCreated(marketId, question, msg.sender, resolutionTime);
    }

    function stake(uint256 marketId, Position position, uint256 amount) external {
        require(markets[marketId].status == MarketStatus.Active, "Market not active");
        require(block.timestamp < markets[marketId].resolutionTime, "Market expired");
        require(amount >= minStake, "Below minimum stake");

        _stake(marketId, position, amount);
    }

    function _stake(uint256 marketId, Position position, uint256 amount) internal {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        if (position == Position.Yes) {
            markets[marketId].yesPool += amount;
            stakes[marketId][msg.sender].yesAmount += amount;
        } else {
            markets[marketId].noPool += amount;
            stakes[marketId][msg.sender].noAmount += amount;
        }

        agentTotalStaked[msg.sender] += amount;

        emit Staked(marketId, msg.sender, position, amount);
    }

    function resolve(uint256 marketId, Position outcome) external onlyOwner {
        Market storage market = markets[marketId];
        require(market.status == MarketStatus.Active, "Already resolved");
        require(block.timestamp >= market.resolutionTime, "Too early");

        market.status = MarketStatus.Resolved;
        market.outcome = outcome;

        emit MarketResolved(marketId, outcome);
    }

    function claim(uint256 marketId) external {
        Market storage market = markets[marketId];
        require(market.status == MarketStatus.Resolved, "Not resolved");
        
        Stake storage s = stakes[marketId][msg.sender];
        require(!s.claimed, "Already claimed");
        s.claimed = true;

        uint256 winningPool;
        uint256 losingPool;
        uint256 userWinningStake;

        if (market.outcome == Position.Yes) {
            winningPool = market.yesPool;
            losingPool = market.noPool;
            userWinningStake = s.yesAmount;
        } else {
            winningPool = market.noPool;
            losingPool = market.yesPool;
            userWinningStake = s.noAmount;
        }

        if (userWinningStake == 0) {
            // Loser — update stats
            agentLosses[msg.sender]++;
            return;
        }

        // Winner gets proportional share of losing pool (minus fee)
        uint256 fee = (losingPool * protocolFeeBps) / 10000;
        accumulatedFees += fee;
        uint256 distributable = losingPool - fee;
        
        uint256 payout = userWinningStake + (distributable * userWinningStake / winningPool);
        
        agentWins[msg.sender]++;
        stakingToken.safeTransfer(msg.sender, payout);

        emit Claimed(marketId, msg.sender, payout);
    }

    // View functions
    function getMarket(uint256 id) external view returns (Market memory) {
        return markets[id];
    }

    function getStake(uint256 marketId, address agent) external view returns (Stake memory) {
        return stakes[marketId][agent];
    }

    function getAgentStats(address agent) external view returns (
        uint256 wins, uint256 losses, uint256 totalStaked, uint256 accuracy
    ) {
        wins = agentWins[agent];
        losses = agentLosses[agent];
        totalStaked = agentTotalStaked[agent];
        accuracy = (wins + losses) > 0 ? (wins * 10000) / (wins + losses) : 0;
    }

    // Admin
    function withdrawFees() external onlyOwner {
        uint256 fees = accumulatedFees;
        accumulatedFees = 0;
        stakingToken.safeTransfer(owner(), fees);
    }

    function setProtocolFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 500, "Max 5%");
        protocolFeeBps = newFeeBps;
    }
}
