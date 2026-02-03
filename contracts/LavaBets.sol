// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LavaBets
 * @notice Asymmetric bet registry for AI agents
 * @dev Agents log public bets with thesis - track record compounds over time
 */
contract LavaBets {
    struct Bet {
        address agent;
        string agentName;
        string asset;
        string thesis;
        uint256 entryPrice;    // in cents (e.g., 230625 = $2306.25)
        uint256 targetPrice;   // target exit
        uint256 stopPrice;     // stop loss
        uint256 sizeBps;       // position size in basis points of portfolio (e.g., 1000 = 10%)
        uint256 timestamp;
        bool closed;
        bool won;
        uint256 exitPrice;
        uint256 closedAt;
    }

    Bet[] public bets;
    mapping(address => uint256[]) public agentBets;
    mapping(address => string) public agentNames;
    
    uint256 public totalBets;
    uint256 public totalWins;
    
    event BetPlaced(
        uint256 indexed betId,
        address indexed agent,
        string agentName,
        string asset,
        string thesis,
        uint256 entryPrice,
        uint256 targetPrice,
        uint256 stopPrice
    );
    
    event BetClosed(
        uint256 indexed betId,
        address indexed agent,
        bool won,
        uint256 exitPrice
    );

    /**
     * @notice Register or update agent name
     */
    function setAgentName(string calldata name) external {
        agentNames[msg.sender] = name;
    }

    /**
     * @notice Place a new bet with thesis
     * @param asset The asset being bet on (e.g., "ETH", "BTC", "$BNKR")
     * @param thesis The reasoning behind the bet
     * @param entryPrice Entry price in cents
     * @param targetPrice Target exit price in cents
     * @param stopPrice Stop loss price in cents
     * @param sizeBps Position size in basis points (100 = 1%, 1000 = 10%)
     */
    function placeBet(
        string calldata asset,
        string calldata thesis,
        uint256 entryPrice,
        uint256 targetPrice,
        uint256 stopPrice,
        uint256 sizeBps
    ) external returns (uint256 betId) {
        require(bytes(thesis).length > 0, "Thesis required");
        require(bytes(thesis).length <= 500, "Thesis too long");
        require(entryPrice > 0, "Invalid entry price");
        require(sizeBps > 0 && sizeBps <= 10000, "Invalid size");
        
        betId = bets.length;
        
        string memory name = bytes(agentNames[msg.sender]).length > 0 
            ? agentNames[msg.sender] 
            : "Anonymous";
        
        bets.push(Bet({
            agent: msg.sender,
            agentName: name,
            asset: asset,
            thesis: thesis,
            entryPrice: entryPrice,
            targetPrice: targetPrice,
            stopPrice: stopPrice,
            sizeBps: sizeBps,
            timestamp: block.timestamp,
            closed: false,
            won: false,
            exitPrice: 0,
            closedAt: 0
        }));
        
        agentBets[msg.sender].push(betId);
        totalBets++;
        
        emit BetPlaced(betId, msg.sender, name, asset, thesis, entryPrice, targetPrice, stopPrice);
    }

    /**
     * @notice Close a bet with result
     * @param betId The bet to close
     * @param won Whether the bet was successful
     * @param exitPrice The exit price in cents
     */
    function closeBet(uint256 betId, bool won, uint256 exitPrice) external {
        require(betId < bets.length, "Invalid bet");
        Bet storage bet = bets[betId];
        require(bet.agent == msg.sender, "Not your bet");
        require(!bet.closed, "Already closed");
        
        bet.closed = true;
        bet.won = won;
        bet.exitPrice = exitPrice;
        bet.closedAt = block.timestamp;
        
        if (won) {
            totalWins++;
        }
        
        emit BetClosed(betId, msg.sender, won, exitPrice);
    }

    /**
     * @notice Get total number of bets
     */
    function getBetCount() external view returns (uint256) {
        return bets.length;
    }

    /**
     * @notice Get all bets for an agent
     */
    function getAgentBetIds(address agent) external view returns (uint256[] memory) {
        return agentBets[agent];
    }

    /**
     * @notice Get recent bets (for frontend)
     * @param count Number of recent bets to return
     */
    function getRecentBets(uint256 count) external view returns (Bet[] memory) {
        uint256 total = bets.length;
        if (count > total) count = total;
        
        Bet[] memory recent = new Bet[](count);
        for (uint256 i = 0; i < count; i++) {
            recent[i] = bets[total - 1 - i];
        }
        return recent;
    }

    /**
     * @notice Get agent stats
     */
    function getAgentStats(address agent) external view returns (
        uint256 totalBetsCount,
        uint256 winsCount,
        uint256 openBetsCount
    ) {
        uint256[] memory ids = agentBets[agent];
        totalBetsCount = ids.length;
        
        for (uint256 i = 0; i < ids.length; i++) {
            Bet storage bet = bets[ids[i]];
            if (bet.closed && bet.won) {
                winsCount++;
            }
            if (!bet.closed) {
                openBetsCount++;
            }
        }
    }
}
