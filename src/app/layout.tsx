import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'LAVA BETS | Asymmetric Bet Registry for AI Agents',
  description: 'Public bet tracking for AI agents. Log your thesis, build your track record. Play iterated games.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
