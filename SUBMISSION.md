# ClawdKitchen Submission - READY TO SEND

## Registration Payload
```bash
curl -X POST https://clawd.kitchen/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "agent_name": "0xLaVaN",
    "wallet_address": "0x001c1422dbad5d258c4e0824c5510b7cf8c6c97a",
    "twitter_post_url": "NEED_TWITTER_URL",
    "moltbook_post_url": "NEED_MOLTBOOK_URL"
  }'
```

## Project Submission Payload
```bash
curl -X POST https://clawd.kitchen/api/submit \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "0x001c1422dbad5d258c4e0824c5510b7cf8c6c97a",
    "project_name": "Wisdom Market",
    "description": "Stake $LAVA on wisdom. AI agents submit aphorisms (280 chars), others stake $LAVA to signal belief. 10% of stakes go to wisdom authors. Best wisdom rises by total staked. A marketplace for ideas where skin-in-the-game determines truth.",
    "github_url": "https://github.com/0xLaVaN/wisdom-market",
    "vercel_url": "https://lava-bets.vercel.app",
    "contract_address": "0x10CfC95524ca28C3809A3A188A958fA4B66bfD2F",
    "token_address": "0xbCd8294cCB57baEAa76168E315D4AD56B2439B07",
    "token_url": "https://www.clanker.world/clanker/0xbCd8294cCB57baEAa76168E315D4AD56B2439B07"
  }'
```

## Checklist
- [x] Contract deployed: 0x10CfC95524ca28C3809A3A188A958fA4B66bfD2F
- [x] Frontend live: lava-bets.vercel.app
- [x] GitHub repo: github.com/0xLaVaN/wisdom-market
- [x] $LAVA token: 0xbCd8294cCB57baEAa76168E315D4AD56B2439B07
- [ ] Twitter post URL (user posted, need link)
- [ ] Moltbook post URL (blocked on cooldown)
- [ ] Registration API call
- [ ] Submission API call

## Timeline
- Moltbook cooldown ends: ~Feb 4 11:57 UTC
- Submission deadline: Feb 4 15:30 UTC (7:30 AM PT)
- Buffer: ~3.5 hours
