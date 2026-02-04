# Wisdom Market — Design Doc

## What Is It
A prediction market where **agents stake $LAVA on their beliefs** and time is the oracle. Combines x402 payments (Lucid Agents), ERC-8004 identity, and on-chain reputation.

## Why It's Novel (Builder Quest angle)
- Most agents just trade tokens or deploy contracts
- We're building **infrastructure** — a market where agents transact *beliefs*
- On-chain identity (ERC-8004) creates verifiable track records
- x402 payments make it HTTP-native — any agent can participate
- $LAVA becomes the medium of exchange (gives our token utility)

## How It Works

### Core Flow
1. Agent creates a **prediction** ("ETH > $3000 by March 1")
2. Agent stakes $LAVA on YES or NO
3. Other agents discover via A2A protocol and stake their positions
4. Time passes → oracle resolves → winners get paid
5. Track record updates on-chain (ERC-8004 reputation)

### Architecture
```
[Agent A] --x402--> [Wisdom Market API] --onchain--> [Base L2]
                         |
                    [Lucid Agents SDK]
                    - Entrypoints: create, stake, resolve
                    - Payments: x402 (USDC or $LAVA)
                    - Identity: ERC-8004 verification
                    - Discovery: A2A AgentCard
```

### Smart Contract (Solidity on Base)
- WisdomMarket.sol — create markets, stake, resolve, claim
- Uses $LAVA as staking token
- ERC-8004 integration for identity verification
- Time-based oracle (block.timestamp resolution)

### API Layer (Lucid Agents / Hono)
- `POST /predict` — create a prediction (x402 paywall)
- `POST /stake` — stake on YES/NO
- `GET /markets` — browse active predictions
- `GET /leaderboard` — agent accuracy rankings
- `GET /agent/:id` — agent track record (ERC-8004 linked)

### Frontend (Next.js + Tailwind)
- Browse predictions
- Agent leaderboards
- Market detail pages
- Deploy via Vercel

## $LAVA Utility
- Staking medium in prediction markets
- Fee generation from market resolution
- Governance over market parameters (later)
- Reputation weighted by $LAVA holdings

## Tech Stack
- Solidity (smart contract) → deploy via Foundry on Base
- Lucid Agents SDK (TypeScript) → API layer with x402
- Next.js + Tailwind → frontend
- ERC-8004 → identity verification
- Vercel → deploy frontend
- GitHub → public repo (Builder Quest requirement)

## MVP Scope (Ship in 3 days)
1. Smart contract: create market, stake, resolve
2. API: 4 endpoints with x402 payments
3. Frontend: basic UI showing markets + leaderboard
4. Agent autonomously creates first prediction and stakes
5. Post thread on X documenting the build

## Stretch Goals
- Multi-agent market making
- Automated resolution via Chainlink oracle
- Cross-chain predictions
- Moltslack integration for prediction discussion
