// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WisdomMarket.sol";

contract WisdomMarketTest is Test {
    WisdomMarket public market;
    
    address creator = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);
    address resolver = address(0x4);
    
    function setUp() public {
        market = new WisdomMarket();
        vm.deal(creator, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(resolver, 1 ether);
    }
    
    // ─── Market Creation ─────────────────────────────────────────────────
    
    function test_createMarket() public {
        vm.prank(creator);
        uint256 id = market.createMarket(
            "Compound interest applies to relationships",
            "Evaluate: do maintained relationships yield increasing returns?",
            block.timestamp + 30 days,
            address(0)
        );
        
        assertEq(id, 0);
        assertEq(market.nextMarketId(), 1);
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertEq(m.proposition, "Compound interest applies to relationships");
        assertEq(m.creator, creator);
        assertEq(m.resolver, creator);
        assertTrue(m.state == WisdomMarket.MarketState.Active);
    }
    
    function test_createMarketWithInitialStake() public {
        vm.prank(creator);
        market.createMarket{value: 0.1 ether}(
            "Code and media are permissionless leverage",
            "Has permissionless creation of code/content generated more wealth than capital-gated industries?",
            block.timestamp + 30 days,
            address(0)
        );
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertEq(m.totalForStake, 0.1 ether);
        assertEq(m.stakersCount, 1);
    }
    
    function test_createMarketWithCustomResolver() public {
        vm.prank(creator);
        market.createMarket(
            "Test proposition",
            "Context",
            block.timestamp + 30 days,
            resolver
        );
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertEq(m.resolver, resolver);
    }
    
    function test_RevertWhen_createMarketTooSoon() public {
        vm.prank(creator);
        vm.expectRevert("Resolution too soon");
        market.createMarket(
            "Too soon",
            "",
            block.timestamp + 1 hours,
            address(0)
        );
    }
    
    function test_RevertWhen_createMarketEmpty() public {
        vm.prank(creator);
        vm.expectRevert("Empty proposition");
        market.createMarket("", "", block.timestamp + 30 days, address(0));
    }
    
    // ─── Staking ─────────────────────────────────────────────────────────
    
    function test_stakeForAndAgainst() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        
        vm.prank(bob);
        market.stakeAgainst{value: 0.5 ether}(0);
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertEq(m.totalForStake, 1 ether);
        assertEq(m.totalAgainstStake, 0.5 ether);
        assertEq(m.stakersCount, 2);
        
        (uint256 forPct, uint256 againstPct) = market.getOdds(0);
        assertEq(forPct, 66);
        assertEq(againstPct, 34);
    }
    
    function test_multipleStakesSameUser() public {
        _createDefaultMarket();
        
        vm.startPrank(alice);
        market.stakeFor{value: 0.5 ether}(0);
        market.stakeFor{value: 0.5 ether}(0);
        vm.stopPrank();
        
        WisdomMarket.Stake memory s = market.getStake(0, alice);
        assertEq(s.forAmount, 1 ether);
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertEq(m.stakersCount, 1);
    }
    
    function test_RevertWhen_stakeBelowMinimum() public {
        _createDefaultMarket();
        vm.prank(alice);
        vm.expectRevert("Below minimum stake");
        market.stakeFor{value: 0.00001 ether}(0);
    }
    
    function test_RevertWhen_stakeAfterResolution() public {
        _createDefaultMarket();
        vm.warp(block.timestamp + 31 days);
        vm.prank(alice);
        vm.expectRevert("Staking closed");
        market.stakeFor{value: 1 ether}(0);
    }
    
    // ─── Resolution ──────────────────────────────────────────────────────
    
    function test_resolveTrue() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        vm.prank(bob);
        market.stakeAgainst{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days);
        
        vm.prank(creator);
        market.resolve(0, WisdomMarket.Outcome.True);
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertTrue(m.state == WisdomMarket.MarketState.Resolved);
        assertTrue(m.outcome == WisdomMarket.Outcome.True);
    }
    
    function test_resolveFalseAndClaim() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        vm.prank(bob);
        market.stakeAgainst{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days);
        vm.prank(creator);
        market.resolve(0, WisdomMarket.Outcome.False);
        
        uint256 bobBefore = bob.balance;
        vm.prank(bob);
        market.claim(0);
        uint256 bobAfter = bob.balance;
        
        // Pool = 2 ETH, fee = 0.02 ETH, bob gets 1.98 ETH
        assertEq(bobAfter - bobBefore, 1.98 ether);
        assertEq(market.getPendingPayout(0, alice), 0);
    }
    
    function test_resolveAmbiguous() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        vm.prank(bob);
        market.stakeAgainst{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days);
        vm.prank(creator);
        market.resolve(0, WisdomMarket.Outcome.Ambiguous);
        
        uint256 alicePayout = market.getPendingPayout(0, alice);
        uint256 bobPayout = market.getPendingPayout(0, bob);
        
        assertEq(alicePayout, 0.99 ether);
        assertEq(bobPayout, 0.99 ether);
    }
    
    function test_RevertWhen_resolveTooEarly() public {
        _createDefaultMarket();
        vm.prank(creator);
        vm.expectRevert("Too early");
        market.resolve(0, WisdomMarket.Outcome.True);
    }
    
    function test_RevertWhen_resolveNotResolver() public {
        _createDefaultMarket();
        vm.warp(block.timestamp + 30 days);
        vm.prank(alice);
        vm.expectRevert("Not resolver");
        market.resolve(0, WisdomMarket.Outcome.True);
    }
    
    function test_RevertWhen_doubleResolve() public {
        _createDefaultMarket();
        vm.warp(block.timestamp + 30 days);
        vm.prank(creator);
        market.resolve(0, WisdomMarket.Outcome.True);
        vm.prank(creator);
        vm.expectRevert("Not active");
        market.resolve(0, WisdomMarket.Outcome.False);
    }
    
    // ─── Expiration ──────────────────────────────────────────────────────
    
    function test_markExpired() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days + 8 days);
        
        market.markExpired(0);
        
        WisdomMarket.Market memory m = market.getMarket(0);
        assertTrue(m.state == WisdomMarket.MarketState.Expired);
        assertTrue(m.outcome == WisdomMarket.Outcome.Ambiguous);
    }
    
    function test_claimAfterExpiry() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        vm.prank(bob);
        market.stakeAgainst{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days + 8 days);
        market.markExpired(0);
        
        uint256 aliceBefore = alice.balance;
        vm.prank(alice);
        market.claim(0);
        assertEq(alice.balance - aliceBefore, 0.99 ether);
    }
    
    // ─── Insights ────────────────────────────────────────────────────────
    
    function test_shareInsight() public {
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        
        vm.prank(alice);
        market.shareInsight(0, "This compounds because trust reduces transaction costs exponentially.");
    }
    
    function test_RevertWhen_shareInsightWithoutStake() public {
        _createDefaultMarket();
        vm.prank(alice);
        vm.expectRevert("Stake first");
        market.shareInsight(0, "No skin in the game");
    }
    
    // ─── Admin ───────────────────────────────────────────────────────────
    
    function test_withdrawFees() public {
        // Transfer ownership to an EOA so it can receive ETH
        address payable feeRecipient = payable(address(0x999));
        vm.deal(feeRecipient, 0);
        market.transferOwnership(feeRecipient);
        
        _createDefaultMarket();
        
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        vm.prank(bob);
        market.stakeAgainst{value: 1 ether}(0);
        
        vm.warp(block.timestamp + 30 days);
        vm.prank(creator);
        market.resolve(0, WisdomMarket.Outcome.True);
        
        assertEq(market.protocolFees(), 0.02 ether);
        
        vm.prank(feeRecipient);
        market.withdrawFees();
        assertEq(feeRecipient.balance, 0.02 ether);
    }
    
    // ─── Odds ────────────────────────────────────────────────────────────
    
    function test_oddsEmptyMarket() public {
        _createDefaultMarket();
        (uint256 forPct, uint256 againstPct) = market.getOdds(0);
        assertEq(forPct, 50);
        assertEq(againstPct, 50);
    }
    
    function test_oddsOneHundredPercent() public {
        _createDefaultMarket();
        vm.prank(alice);
        market.stakeFor{value: 1 ether}(0);
        
        (uint256 forPct, uint256 againstPct) = market.getOdds(0);
        assertEq(forPct, 100);
        assertEq(againstPct, 0);
    }
    
    // ─── Helpers ─────────────────────────────────────────────────────────
    
    function _createDefaultMarket() internal returns (uint256) {
        vm.prank(creator);
        return market.createMarket(
            "Compound interest applies to relationships",
            "Evaluate: do maintained relationships yield increasing returns over 30 days?",
            block.timestamp + 30 days,
            address(0)
        );
    }
}
