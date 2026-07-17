# Volex — Vision & Mission

> _The flight simulator for traders._

## Vision

A world where anyone can become a genuinely skilled trader **before they ever
risk a dollar** — where trading education is hands-on, data-real, and free of the
gambling incentives that wreck retail traders.

## Mission

Volex gives aspiring traders an institutional-grade terminal to **learn, build,
backtest, and prove** trading strategies on real market data with **zero
financial risk** — and a marketplace where the best strategy-builders get
rewarded.

## Positioning

**The flight simulator for traders.** Pilots log hundreds of simulator hours
before they touch a real cockpit. Traders are handed real money on day one and
blow up. Volex is the missing simulator layer: real data, real tooling, real
skill-building — zero real-money risk until you've earned it.

We are **not** a broker. We do not hold customer funds or route real orders.
That keeps us shippable today and legally clean, and it is a deliberate
strategic choice — the money-moving layer comes later, through regulated
partners, from a position of strength.

## Why this is the right bet

1. **It's what the product already is.** We have a paper-trading engine, an AI
   strategy lab, a backtest engine, a scanner, an optimizer, and a
   marketplace/copy-trading scaffold. The education/simulator product is mostly
   built; the brokerage product would need licenses we don't have.
2. **It's legal to ship now** — no broker-dealer registration, no custody of
   client money, no KYC/AML burden at launch.
3. **It's an unowned moat.** TradingView owns charts + community. Robinhood owns
   cheap execution. Nobody owns _"learn to trade with a real engine, then get
   paid for good strategies."_
4. **It has a clean upgrade path** to real execution via a regulated partner,
   once we have skilled users and proven strategies.

## How we get there — the staged path

### Act 1 — Become the best simulator (now → ~6 months)
Resolve our identity everywhere: we are the flight simulator for traders. Then
finish the three things that make the simulation credible:
- **One real chart engine.** Consolidate the custom `CustomPainter` chart layer
  and retire the `fl_chart`-based stand-ins. The chart is the product's face.
- **The Strategy Lab loop:** describe → generate → backtest → paper-trade → see
  honest results.
- **Trust:** accurate paper fills, real market data, no inflated "you'd be up
  400%" numbers. Credibility is the moat in education.

**North-star metric:** users who complete a full
learn → build → backtest → paper-trade loop and return the next week.

### Act 2 — Turn learners into a marketplace (~6–12 months)
Switch on the creator economy already scaffolded (`engine/marketplace/`,
`engine/copy_trading/`, creator dashboard, leaderboard). Skilled paper-traders
publish strategies; others subscribe or copy (in simulation first); we take a
rev-share. This is a second revenue stream and our primary growth loop —
creators bring their own audiences.

**Metric:** published strategies and paying subscribers to them.

### Act 3 — Bridge to real capital, safely (12 months+)
Only now, with skilled users and proven strategies, integrate a **regulated
broker partner** so users who've earned it can graduate from paper to live —
with the training wheels (risk caps, AI Guardian) intact. We never become the
broker; we're the skill-and-strategy layer on top of one.

## How we make money

| Stage | Revenue stream |
|-------|----------------|
| Act 1 | **Subscription** — full Strategy Lab, advanced AI generation, unlimited backtests, more indicators (~$10–20/mo). IAP wiring already exists. |
| Act 2 | **Marketplace rev-share** — a cut of strategy subscription / copy fees. |
| Act 3 | **Broker referral / spread share** — revenue from a regulated partner, no licensing burden on us. |

## Guardrails (what keeps us honest)

- **No real-money execution until Act 3**, and only via a regulated partner.
- **No inflated performance claims.** Backtests and paper results must be
  accurate and clearly labelled as simulated.
- **The product is educational.** Marketing, store listings, and in-app copy
  must reflect that — no "institutional execution" or "liquidity routing"
  language that implies capabilities we don't have.

---

_Last updated: 2026-07-17_
