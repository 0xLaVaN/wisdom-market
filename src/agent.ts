import { createAgent } from '@lucid-agents/core'
import { http } from '@lucid-agents/http'
import { payments } from '@lucid-agents/payments'
import { z } from 'zod'

const LAVA_ADDRESS = '0xbcd8294ccb57baeaa76168e315d4ad56b2439b07'
const ERC8004_AGENT_ID = 1284

const agent = createAgent({
  name: 'wisdom-market',
  description: 'Prediction market where AI agents stake $LAVA on beliefs. Time is the oracle. Built by 0xLaVaN (ERC-8004 #1284).',
  version: '0.1.0',
})
  .use(http({ port: 3000 }))
  .use(payments({ 
    address: process.env.WALLET_ADDRESS || '0x11F5397F191144894cD907A181ED61A7bf5634dE',
    network: 'base'
  }))

// Browse active prediction markets
agent.entrypoint({
  name: 'markets',
  description: 'Browse active prediction markets with current odds',
  input: z.object({
    status: z.enum(['active', 'resolved', 'all']).default('active'),
    limit: z.number().min(1).max(50).default(10),
  }),
  output: z.object({
    markets: z.array(z.object({
      id: z.number(),
      question: z.string(),
      yesPool: z.string(),
      noPool: z.string(),
      yesOdds: z.number(),
      noOdds: z.number(),
      resolutionTime: z.string(),
      creator: z.string(),
    })),
    total: z.number(),
  }),
  handler: async ({ input }) => {
    // TODO: Read from contract
    return {
      markets: [],
      total: 0,
    }
  }
})

// Get agent accuracy leaderboard
agent.entrypoint({
  name: 'leaderboard',
  description: 'Agent prediction accuracy rankings linked to ERC-8004 identity',
  input: z.object({
    limit: z.number().min(1).max(100).default(20),
  }),
  output: z.object({
    agents: z.array(z.object({
      address: z.string(),
      erc8004Id: z.number().optional(),
      wins: z.number(),
      losses: z.number(),
      accuracy: z.number(),
      totalStaked: z.string(),
    })),
  }),
  handler: async ({ input }) => {
    // TODO: Read from contract events
    return { agents: [] }
  }
})

// Create a prediction market (paid endpoint)
agent.entrypoint({
  name: 'predict',
  description: 'Create a new prediction market. Requires $LAVA stake.',
  input: z.object({
    question: z.string().min(10).max(500),
    resolutionTime: z.string().describe('ISO 8601 timestamp for when this resolves'),
    position: z.enum(['yes', 'no']),
    stakeAmount: z.string().describe('Amount of $LAVA to stake (in wei)'),
  }),
  output: z.object({
    marketId: z.number(),
    txHash: z.string(),
    question: z.string(),
  }),
  price: { amount: '0.001', currency: 'USDC' }, // Small fee to prevent spam
  handler: async ({ input }) => {
    // TODO: Submit tx to WisdomMarket contract
    return {
      marketId: 0,
      txHash: '0x...',
      question: input.question,
    }
  }
})

// Stake on an existing market (paid endpoint)
agent.entrypoint({
  name: 'stake',
  description: 'Stake $LAVA on YES or NO for an existing prediction market',
  input: z.object({
    marketId: z.number(),
    position: z.enum(['yes', 'no']),
    amount: z.string().describe('Amount of $LAVA to stake (in wei)'),
  }),
  output: z.object({
    txHash: z.string(),
    newYesOdds: z.number(),
    newNoOdds: z.number(),
  }),
  price: { amount: '0.0005', currency: 'USDC' },
  handler: async ({ input }) => {
    // TODO: Submit tx to WisdomMarket contract
    return {
      txHash: '0x...',
      newYesOdds: 0.5,
      newNoOdds: 0.5,
    }
  }
})

// Get agent stats (free)
agent.entrypoint({
  name: 'agent-stats',
  description: 'Get prediction track record for any agent address, linked to ERC-8004',
  input: z.object({
    address: z.string(),
  }),
  output: z.object({
    address: z.string(),
    erc8004Id: z.number().optional(),
    wins: z.number(),
    losses: z.number(),
    accuracy: z.number(),
    totalStaked: z.string(),
    recentPredictions: z.array(z.object({
      marketId: z.number(),
      question: z.string(),
      position: z.string(),
      outcome: z.string().optional(),
      correct: z.boolean().optional(),
    })),
  }),
  handler: async ({ input }) => {
    // TODO: Read from contract
    return {
      address: input.address,
      wins: 0,
      losses: 0,
      accuracy: 0,
      totalStaked: '0',
      recentPredictions: [],
    }
  }
})

export default agent
