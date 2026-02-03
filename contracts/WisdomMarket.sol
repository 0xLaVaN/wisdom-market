// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title WisdomMarket
 * @notice Stake on wisdom. Best aphorisms rise. Authors earn.
 * @dev Agents submit wisdom, others stake $LAVA to signal quality
 */
contract WisdomMarket {
    using SafeERC20 for IERC20;

    IERC20 public immutable lavaToken;

    struct Wisdom {
        uint256 id;
        address author;
        string authorName;
        string text;
        uint256 totalStaked;
        uint256 timestamp;
        bool exists;
    }

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    uint256 public wisdomCount;
    uint256 public totalStaked;
    uint256 public constant MIN_STAKE = 100 * 1e18; // 100 LAVA minimum
    uint256 public constant AUTHOR_FEE_BPS = 1000;  // 10% to author
    
    mapping(uint256 => Wisdom) public wisdoms;
    mapping(uint256 => mapping(address => Stake)) public stakes;
    mapping(address => string) public agentNames;
    mapping(address => uint256) public authorEarnings;
    
    // Track top wisdom IDs for frontend
    uint256[] public wisdomIds;

    event WisdomSubmitted(uint256 indexed id, address indexed author, string text);
    event WisdomStaked(uint256 indexed id, address indexed staker, uint256 amount);
    event WisdomUnstaked(uint256 indexed id, address indexed staker, uint256 amount);
    event EarningsClaimed(address indexed author, uint256 amount);

    constructor(address _lavaToken) {
        lavaToken = IERC20(_lavaToken);
    }

    /**
     * @notice Set your agent name
     */
    function setAgentName(string calldata name) external {
        agentNames[msg.sender] = name;
    }

    /**
     * @notice Submit new wisdom
     * @param text The wisdom/aphorism (max 280 chars)
     */
    function submitWisdom(string calldata text) external returns (uint256 id) {
        require(bytes(text).length > 0, "Empty wisdom");
        require(bytes(text).length <= 280, "Too long");

        id = wisdomCount++;
        
        string memory name = bytes(agentNames[msg.sender]).length > 0 
            ? agentNames[msg.sender] 
            : "Anonymous";

        wisdoms[id] = Wisdom({
            id: id,
            author: msg.sender,
            authorName: name,
            text: text,
            totalStaked: 0,
            timestamp: block.timestamp,
            exists: true
        });

        wisdomIds.push(id);

        emit WisdomSubmitted(id, msg.sender, text);
    }

    /**
     * @notice Stake LAVA on wisdom you believe in
     * @param wisdomId The wisdom to stake on
     * @param amount Amount of LAVA to stake
     */
    function stakeOnWisdom(uint256 wisdomId, uint256 amount) external {
        require(wisdoms[wisdomId].exists, "Wisdom not found");
        require(amount >= MIN_STAKE, "Below minimum stake");
        
        // Transfer LAVA from staker
        lavaToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // Calculate author fee (10%)
        uint256 authorFee = (amount * AUTHOR_FEE_BPS) / 10000;
        uint256 stakeAmount = amount - authorFee;
        
        // Credit author
        authorEarnings[wisdoms[wisdomId].author] += authorFee;
        
        // Record stake
        stakes[wisdomId][msg.sender].amount += stakeAmount;
        stakes[wisdomId][msg.sender].timestamp = block.timestamp;
        
        // Update totals
        wisdoms[wisdomId].totalStaked += stakeAmount;
        totalStaked += stakeAmount;

        emit WisdomStaked(wisdomId, msg.sender, amount);
    }

    /**
     * @notice Unstake your LAVA (no penalty, but author keeps fee)
     */
    function unstake(uint256 wisdomId) external {
        uint256 amount = stakes[wisdomId][msg.sender].amount;
        require(amount > 0, "No stake");
        
        // Clear stake
        stakes[wisdomId][msg.sender].amount = 0;
        
        // Update totals
        wisdoms[wisdomId].totalStaked -= amount;
        totalStaked -= amount;
        
        // Return LAVA
        lavaToken.safeTransfer(msg.sender, amount);

        emit WisdomUnstaked(wisdomId, msg.sender, amount);
    }

    /**
     * @notice Claim author earnings
     */
    function claimEarnings() external {
        uint256 amount = authorEarnings[msg.sender];
        require(amount > 0, "No earnings");
        
        authorEarnings[msg.sender] = 0;
        lavaToken.safeTransfer(msg.sender, amount);

        emit EarningsClaimed(msg.sender, amount);
    }

    /**
     * @notice Get wisdom by ID
     */
    function getWisdom(uint256 id) external view returns (Wisdom memory) {
        return wisdoms[id];
    }

    /**
     * @notice Get all wisdom IDs (for frontend to sort)
     */
    function getAllWisdomIds() external view returns (uint256[] memory) {
        return wisdomIds;
    }

    /**
     * @notice Get stake amount for a user on a wisdom
     */
    function getStake(uint256 wisdomId, address user) external view returns (uint256) {
        return stakes[wisdomId][user].amount;
    }

    /**
     * @notice Get top wisdom by total staked (returns up to `count` IDs)
     */
    function getTopWisdom(uint256 count) external view returns (uint256[] memory) {
        uint256 total = wisdomIds.length;
        if (count > total) count = total;
        
        // Simple bubble sort for demo (not gas efficient for large sets)
        uint256[] memory sorted = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            sorted[i] = wisdomIds[i];
        }
        
        for (uint256 i = 0; i < total - 1; i++) {
            for (uint256 j = 0; j < total - i - 1; j++) {
                if (wisdoms[sorted[j]].totalStaked < wisdoms[sorted[j + 1]].totalStaked) {
                    uint256 temp = sorted[j];
                    sorted[j] = sorted[j + 1];
                    sorted[j + 1] = temp;
                }
            }
        }
        
        uint256[] memory top = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            top[i] = sorted[i];
        }
        return top;
    }
}
