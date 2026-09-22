# Changelog

## [1.1.0+11] — unreleased

The theme of this release is removing everything the app claimed but did not
do. Several of the entries below are deletions, and that is the point: a
simulator's only asset is that its numbers and its descriptions are true.

### Honesty
- **Removed every AI claim.** Signals, trade checks and the strategy builder
  are indicator rules and thresholds evaluated on candles — there is no model
  in the app and never was. The "AI Guardian" is now called trade checks, the
  signals feed no longer advertises "real-time AI opportunities" in any
  language, and the strategy builder no longer says it drafts strategies from
  plain language.
- **Published strategies no longer run someone else's logic.** The registry
  used to hand back a Bollinger+RSI strategy for *any* published listing, so
  running one executed rules that were not the ones named on screen, and the
  resulting trades and backtest figures were attributed to a strategy that
  never ran. Listings now return a strategy that takes no trades and says why,
  and both the marketplace and the add confirmation say it up front.
- **Exchange API keys are no longer collected.** The setup screen stored a real
  Binance key and secret and reported "Exchange connected successfully";
  nothing in the app ever read them back. It now explains that there is no live
  trading and offers to delete anything an earlier build saved.
- **Removed paywalls for features that do not exist.** Premium had been selling
  advanced analytics, custom watchlists, export and priority support, none of
  which are implemented. Premium now lists only what it genuinely lifts.
- **Marketplace and leaderboard no longer show invented performance.** Seeded
  listings with figures like "+312.5% return, 98% win rate, $99/month" are
  gone; the leaderboard stays empty until there are verified results; reported
  figures are labelled as reported; the "$X/mo" price tag on a free local list
  is gone.
- **"24/7 automated strategies" is now "while the app is open"**, which is what
  the runner actually does.

### Features
- **Backtesting is unlimited on every tier.** It was capped at one a day on the
  free plan — gating the exact activity the Academy spends four lessons telling
  people to do.
- **Academy expanded to 21 lessons and 63 quiz questions**, adding base rates
  on retail day-trading outcomes, the arithmetic of trading costs, correlation,
  expectancy with worked examples, and why a handful of results is noise.
- **Glossary** — 48 terms, searchable by definition as well as by name, at
  `/glossary`.
- **Feature intros** — a what/when/caution card on the screens users found
  opaque, dismissible per feature.
- **"What's on this chart"** legend sheet explaining every mark on the chart.

### Fixes
- Chart: cached series with fingerprint-based invalidation, clipped drawing,
  price scale that accounts for visible indicator values, comparison-based
  repaint, and a semantic label for screen readers.
- Trade ticket: risk-based sizing is now covered by widget tests that drive the
  real sheet and check the loss at the stop arithmetically.
- Engine: a full open-to-close test suite holding the invariant
  `balance = start − open fee − close fee + realized`, derived from actual fill
  prices rather than the mark price.
- A failed purchase now says so. With products unconfigured in the Play
  Console, the Upgrade button did nothing at all.
- Release builds no longer log the signed-in user's UID; `AppLogger` drops to
  warnings and above in release.
- XP for placing a trade with a stop is capped at three awards a day, so the
  reward is for the habit rather than for volume.
- Dropped Android permissions the app does not use, and an exported background
  service that nothing ever started.

---

## [1.1.0+2] — 2026-02-01
- **Fix**: Resolved WebSocket "Invalid close code 1001" error.
- **Fix**: Manual Firebase configuration to work around Android resource
  loading failures.
- **Improved**: Reduced console noise by silencing verbose socket logs.

## [1.0.0+1] — 2026-01-21
- Strategy engine loop and logging optimised.
- Risk manager with a global kill-switch.
- Real-time charting and analytics.

> Earlier entries in this file also listed "Full-Auto Live Execution", a
> "Strategy Marketplace & Creator Dashboard" and "Cloud Sync & Offline Mode" as
> shipped features. None of them existed. They have been removed rather than
> left in the record, because a changelog that reports unbuilt work is the
> document you check when you are trying to find out what is real.
