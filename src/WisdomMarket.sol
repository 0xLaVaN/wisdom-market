// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title WisdomMarket
 * @author 0xLaVaN
 * @notice Prediction markets for mental models, not events.
 * 
 * Polymarket resolves because events happen.
 * Wisdom Market resolves because patterns prove true over time.
 * 
 * Stake on propositions like:
 *   "Compound interest applies to relationships"
 *   "Code and media are permissionless leverage"
 *   "Specific knowledge cannot be trained for"
 * 
 * Time is the oracle. Community validates through skin in the game.
 */
contract WisdomMarket {
    // ─── Types ───────────────────────────────────────────────────────────
    
    enum MarketState { Active, Resolving, Resolved, Expired }
    enum Outcome { Unresolved, True, False, Ambiguous }
    
    struct Market {
        string proposition;          // The wisdom being tested
        string context;              // Why this matters / how to evaluate
        address creator;             // Who proposed it
        uint256 createdAt;           // When it was created
        uint256 resolutionTime;      // When it can be resolved
        uint256 totalForStake;       // Total ETH staked FOR
        uint256 totalAgainstStake;   // Total ETH staked AGAINST
        uint256 stakersCount;        // Number of unique stakers
        MarketState state;
        Outcome outcome;
        address resolver;            // Who resolved it (0x0 = creator)
    }
    
    struct Stake {
        uint256 forAmount;           // Amount staked FOR
        uint256 againstAmount;       // Amount staked AGAINST
        bool claimed;                // Whether winnings were claimed
    }
    
    // ─── State ───────────────────────────────────────────────────────────
    
    uint256 public nextMarketId;
    uint256 public constant MIN_STAKE = 0.0001 ether;
    uint256 public constant MIN_RESOLUTION_PERIOD = 1 days;
    uint256 public constant MAX_RESOLUTION_PERIOD = 365 days;
    uint256 public constant RESOLUTION_WINDOW = 7 days;    // Time after resolutionTime to resolve
    uint256 public constant PROTOCOL_FEE_BPS = 100;        // 1% protocol fee
    
    address public owner;
    uint256 public protocolFees;
    
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => Stake)) public stakes;
    
    // ─── Events ──────────────────────────────────────────────────────────
    
    event MarketCreated(
        uint256 indexed marketId,
        string proposition,
        address indexed creator,
        uint256 resolutionTime
    );
    
    event Staked(
        uint256 indexed marketId,
        address indexed staker,
        bool isFor,
        uint256 amount
    );
    
    event MarketResolved(
        uint256 indexed marketId,
        Outcome outcome,
        address indexed resolver
    );
    
    event Claimed(
        uint256 indexed marketId,
        address indexed staker,
        uint256 amount
    );
    
    event WisdomShared(
        uint256 indexed marketId,
        address indexed sharer,
        string insight
    );
    
    // ─── Modifiers ───────────────────────────────────────────────────────
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier marketExists(uint256 marketId) {
        require(marketId < nextMarketId, "Market does not exist");
        _;
    }
    
    // ─── Constructor ─────────────────────────────────────────────────────
    
    constructor() {
        owner = msg.sender;
    }
    
    // ─── Core Functions ──────────────────────────────────────────────────
    
    /**
     * @notice Create a new wisdom market
     * @param proposition The mental model / wisdom being tested
     * @param context How to evaluate this — what would prove it true/false?
     * @param resolutionTime When this can be resolved (unix timestamp)
     * @param resolver Optional custom resolver (0x0 = creator resolves)
     */
    function createMarket(
        string calldata proposition,
        string calldata context,
        uint256 resolutionTime,
        address resolver
    ) external payable returns (uint256 marketId) {
        require(bytes(proposition).length > 0, "Empty proposition");
        require(bytes(proposition).length <= 280, "Proposition too long");
        require(
            resolutionTime >= block.timestamp + MIN_RESOLUTION_PERIOD,
            "Resolution too soon"
        );
        require(
            resolutionTime <= block.timestamp + MAX_RESOLUTION_PERIOD,
            "Resolution too far"
        );
        
        marketId = nextMarketId++;
        
        Market storage m = markets[marketId];
        m.proposition = proposition;
        m.context = context;
        m.creator = msg.sender;
        m.createdAt = block.timestamp;
        m.resolutionTime = resolutionTime;
        m.state = MarketState.Active;
        m.outcome = Outcome.Unresolved;
        m.resolver = resolver == address(0) ? msg.sender : resolver;
        
        emit MarketCreated(marketId, proposition, msg.sender, resolutionTime);
        
        // Creator can seed the market with an initial stake
        if (msg.value > 0) {
            _stake(marketId, true, msg.value);
        }
    }
    
    /**
     * @notice Stake FOR a proposition being true
     */
    function stakeFor(uint256 marketId) external payable marketExists(marketId) {
        _stake(marketId, true, msg.value);
    }
    
    /**
     * @notice Stake AGAINST a proposition
     */
    function stakeAgainst(uint256 marketId) external payable marketExists(marketId) {
        _stake(marketId, false, msg.value);
    }
    
    /**
     * @notice Resolve a market after resolution time
     * @param outcome True, False, or Ambiguous
     */
    function resolve(uint256 marketId, Outcome outcome) 
        external 
        marketExists(marketId) 
    {
        Market storage m = markets[marketId];
        require(m.state == MarketState.Active, "Not active");
        require(block.timestamp >= m.resolutionTime, "Too early");
        require(
            block.timestamp <= m.resolutionTime + RESOLUTION_WINDOW,
            "Resolution window passed"
        );
        require(msg.sender == m.resolver, "Not resolver");
        require(
            outcome == Outcome.True || 
            outcome == Outcome.False || 
            outcome == Outcome.Ambiguous,
            "Invalid outcome"
        );
        
        m.state = MarketState.Resolved;
        m.outcome = outcome;
        
        // Calculate protocol fee
        uint256 totalPool = m.totalForStake + m.totalAgainstStake;
        uint256 fee = (totalPool * PROTOCOL_FEE_BPS) / 10000;
        protocolFees += fee;
        
        emit MarketResolved(marketId, outcome, msg.sender);
    }
    
    /**
     * @notice Mark market as expired if resolver didn't act
     */
    function markExpired(uint256 marketId) external marketExists(marketId) {
        Market storage m = markets[marketId];
        require(m.state == MarketState.Active, "Not active");
        require(
            block.timestamp > m.resolutionTime + RESOLUTION_WINDOW,
            "Still in resolution window"
        );
        
        m.state = MarketState.Expired;
        m.outcome = Outcome.Ambiguous;
    }
    
    /**
     * @notice Claim winnings after resolution
     */
    function claim(uint256 marketId) external marketExists(marketId) {
        Market storage m = markets[marketId];
        require(
            m.state == MarketState.Resolved || m.state == MarketState.Expired,
            "Not resolved"
        );
        
        Stake storage s = stakes[marketId][msg.sender];
        require(!s.claimed, "Already claimed");
        require(s.forAmount > 0 || s.againstAmount > 0, "No stake");
        
        s.claimed = true;
        
        uint256 payout = _calculatePayout(marketId, msg.sender);
        require(payout > 0, "No payout");
        
        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "Transfer failed");
        
        emit Claimed(marketId, msg.sender, payout);
    }
    
    /**
     * @notice Share an insight about a proposition (on-chain commentary)
     * @dev Insights are events — free to post, permanently on-chain
     */
    function shareInsight(uint256 marketId, string calldata insight) 
        external 
        marketExists(marketId) 
    {
        require(bytes(insight).length > 0 && bytes(insight).length <= 560, "Invalid length");
        // Must have skin in the game to comment
        Stake storage s = stakes[marketId][msg.sender];
        require(s.forAmount > 0 || s.againstAmount > 0, "Stake first");
        
        emit WisdomShared(marketId, msg.sender, insight);
    }
    
    // ─── View Functions ──────────────────────────────────────────────────
    
    function getMarket(uint256 marketId) 
        external 
        view 
        marketExists(marketId) 
        returns (Market memory) 
    {
        return markets[marketId];
    }
    
    function getStake(uint256 marketId, address staker) 
        external 
        view 
        returns (Stake memory) 
    {
        return stakes[marketId][staker];
    }
    
    function getOdds(uint256 marketId) 
        external 
        view 
        marketExists(marketId) 
        returns (uint256 forPct, uint256 againstPct) 
    {
        Market storage m = markets[marketId];
        uint256 total = m.totalForStake + m.totalAgainstStake;
        if (total == 0) return (50, 50);
        forPct = (m.totalForStake * 100) / total;
        againstPct = 100 - forPct;
    }
    
    function getPendingPayout(uint256 marketId, address staker)
        external
        view
        returns (uint256)
    {
        Market storage m = markets[marketId];
        if (m.state != MarketState.Resolved && m.state != MarketState.Expired) return 0;
        Stake storage s = stakes[marketId][staker];
        if (s.claimed) return 0;
        return _calculatePayout(marketId, staker);
    }
    
    // ─── Internal ────────────────────────────────────────────────────────
    
    function _stake(uint256 marketId, bool isFor, uint256 amount) internal {
        Market storage m = markets[marketId];
        require(m.state == MarketState.Active, "Market not active");
        require(block.timestamp < m.resolutionTime, "Staking closed");
        require(amount >= MIN_STAKE, "Below minimum stake");
        
        Stake storage s = stakes[marketId][msg.sender];
        
        // Track unique stakers
        if (s.forAmount == 0 && s.againstAmount == 0) {
            m.stakersCount++;
        }
        
        if (isFor) {
            s.forAmount += amount;
            m.totalForStake += amount;
        } else {
            s.againstAmount += amount;
            m.totalAgainstStake += amount;
        }
        
        emit Staked(marketId, msg.sender, isFor, amount);
    }
    
    function _calculatePayout(uint256 marketId, address staker) 
        internal 
        view 
        returns (uint256) 
    {
        Market storage m = markets[marketId];
        Stake storage s = stakes[marketId][staker];
        
        uint256 totalPool = m.totalForStake + m.totalAgainstStake;
        uint256 fee = (totalPool * PROTOCOL_FEE_BPS) / 10000;
        uint256 payoutPool = totalPool - fee;
        
        if (m.outcome == Outcome.Ambiguous) {
            // Refund proportionally (minus fee)
            uint256 userTotal = s.forAmount + s.againstAmount;
            return (userTotal * payoutPool) / totalPool;
        } else if (m.outcome == Outcome.True) {
            // FOR stakers win
            if (s.forAmount == 0) return 0;
            return (s.forAmount * payoutPool) / m.totalForStake;
        } else if (m.outcome == Outcome.False) {
            // AGAINST stakers win
            if (s.againstAmount == 0) return 0;
            return (s.againstAmount * payoutPool) / m.totalAgainstStake;
        }
        
        return 0;
    }
    
    // ─── Admin ───────────────────────────────────────────────────────────
    
    function withdrawFees() external onlyOwner {
        uint256 amount = protocolFees;
        protocolFees = 0;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
