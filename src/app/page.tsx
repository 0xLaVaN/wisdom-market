'use client'

import { useState, useEffect } from 'react'

const CONTRACT = '0x10CfC95524ca28C3809A3A188A958fA4B66bfD2F'
const LAVA_TOKEN = '0xbCd8294cCB57baEAa76168E315D4AD56B2439B07'

// Sample wisdom for demo (will be replaced by on-chain data)
const SAMPLE_WISDOM = [
  { id: 0, author: '0xLaVaN', text: 'Seek wealth, not money or status. Wealth is assets that earn while you sleep.', staked: 0 },
  { id: 1, author: '0xLaVaN', text: 'Specific knowledge cannot be trained for. If society can train you, it can replace you.', staked: 0 },
  { id: 2, author: '0xLaVaN', text: 'Code and media are permissionless leverage. The leverage behind the newly rich.', staked: 0 },
]

export default function WisdomMarket() {
  const [wisdoms, setWisdoms] = useState(SAMPLE_WISDOM)
  const [newWisdom, setNewWisdom] = useState('')
  const [connected, setConnected] = useState(false)
  const [account, setAccount] = useState('')

  const connectWallet = async () => {
    if (typeof window !== 'undefined' && (window as any).ethereum) {
      try {
        const accounts = await (window as any).ethereum.request({ method: 'eth_requestAccounts' })
        setAccount(accounts[0])
        setConnected(true)
      } catch (err) {
        console.error('Failed to connect:', err)
      }
    } else {
      alert('Please install MetaMask to interact with Wisdom Market')
    }
  }

  const submitWisdom = async () => {
    if (!newWisdom.trim() || newWisdom.length > 280) return
    
    // Add locally for demo
    setWisdoms([...wisdoms, {
      id: wisdoms.length,
      author: account ? account.slice(0, 8) + '...' : 'Anonymous',
      text: newWisdom,
      staked: 0
    }])
    setNewWisdom('')
    
    // TODO: Call contract submitWisdom()
    alert('Wisdom submitted! (Demo mode - connect wallet for on-chain)')
  }

  return (
    <main style={{ minHeight: '100vh', padding: '1.5rem', maxWidth: '700px', margin: '0 auto' }}>
      {/* Header */}
      <header style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        marginBottom: '2rem',
        paddingBottom: '1rem',
        borderBottom: '1px solid var(--border)'
      }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700 }}>
            🧠 Wisdom Market
          </h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
            Stake $LAVA on wisdom. Best aphorisms rise.
          </p>
        </div>
        <button 
          onClick={connectWallet}
          style={{
            background: connected ? 'var(--green)' : 'var(--accent)',
            padding: '0.6rem 1rem',
            fontSize: '0.85rem'
          }}
        >
          {connected ? `${account.slice(0, 6)}...` : 'Connect'}
        </button>
      </header>

      {/* Submit Wisdom */}
      <section style={{ marginBottom: '2rem' }}>
        <div style={{
          background: 'var(--surface)',
          border: '1px solid var(--border)',
          borderRadius: '0.75rem',
          padding: '1.25rem'
        }}>
          <textarea
            placeholder="Share your wisdom (max 280 chars)..."
            value={newWisdom}
            onChange={(e) => setNewWisdom(e.target.value)}
            maxLength={280}
            style={{
              width: '100%',
              minHeight: '80px',
              resize: 'vertical',
              marginBottom: '0.75rem'
            }}
          />
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem' }}>
              {newWisdom.length}/280
            </span>
            <button onClick={submitWisdom} disabled={!newWisdom.trim()}>
              Submit Wisdom
            </button>
          </div>
        </div>
      </section>

      {/* Wisdom Feed */}
      <section>
        <h2 style={{ fontSize: '1rem', marginBottom: '1rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          Top Wisdom
        </h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {wisdoms.map((w) => (
            <div key={w.id} style={{
              background: 'var(--surface)',
              border: '1px solid var(--border)',
              borderRadius: '0.75rem',
              padding: '1.25rem'
            }}>
              <p style={{ 
                fontSize: '1.1rem', 
                lineHeight: 1.5, 
                marginBottom: '1rem',
                fontStyle: 'italic'
              }}>
                "{w.text}"
              </p>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center',
                color: 'var(--text-muted)',
                fontSize: '0.85rem'
              }}>
                <span>— {w.author}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <span>{w.staked.toLocaleString()} $LAVA staked</span>
                  <button style={{ 
                    padding: '0.4rem 0.8rem', 
                    fontSize: '0.8rem',
                    background: 'var(--blue)'
                  }}>
                    Stake
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Info */}
      <section style={{ marginTop: '2rem' }}>
        <div style={{
          background: 'var(--surface)',
          border: '1px solid var(--accent)',
          borderRadius: '0.75rem',
          padding: '1.25rem'
        }}>
          <h3 style={{ fontSize: '1rem', marginBottom: '0.75rem' }}>How it works</h3>
          <ul style={{ 
            color: 'var(--text-muted)', 
            fontSize: '0.9rem', 
            lineHeight: 1.6,
            paddingLeft: '1.25rem'
          }}>
            <li>Submit wisdom (280 chars max)</li>
            <li>Stake $LAVA on wisdom you believe in</li>
            <li>10% of stakes go to the author</li>
            <li>Top wisdom rises by total staked</li>
            <li>Unstake anytime (author keeps fee)</li>
          </ul>
        </div>
      </section>

      {/* Contract Info */}
      <div style={{
        marginTop: '2rem',
        padding: '1rem',
        background: 'var(--surface)',
        borderRadius: '0.75rem',
        textAlign: 'center',
        border: '1px solid var(--border)'
      }}>
        <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>
          Contract: <a href={`https://basescan.org/address/${CONTRACT}`} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--accent)' }}>
            {CONTRACT.slice(0, 10)}...{CONTRACT.slice(-8)}
          </a>
        </p>
        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          Built for <a href="https://clawd.kitchen" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--accent)' }}>ClawdKitchen</a> by <a href="https://x.com/0xLaVaN" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--accent)' }}>0xLaVaN</a> 🦞
        </p>
      </div>
    </main>
  )
}
