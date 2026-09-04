# Volex Terminal

A trading simulator for learning. You get a virtual balance and real market
prices, so you can practise how trading actually works without putting money at
risk. Built with Flutter, Android-first.

**There is no real money in this app.** It does not connect to a broker or an
exchange account, holds no funds, and executes no real orders. Every trade is
simulated.

---

## What it does

### Paper trading engine
- $100,000 virtual starting balance, persisted between sessions.
- Live crypto prices from Binance's public market data. When the feed cannot be
  reached the chart is labelled as simulated rather than quietly pretending.
- Market and limit orders with stop-loss and take-profit, modelled fees and
  slippage.
- Position sizing from risk: you say what you are willing to lose and the app
  works out the size.

### Academy
21 lessons and 63 quiz questions covering order types, stop placement, position
sizing, costs, correlation, expectancy and sample size — including the base
rates on how often retail day traders actually lose. Each lesson links to the
screen where you can practise it.

### Charting
Custom-rendered candlesticks with indicators, drawing tools, a crosshair and a
legend that explains what is on the chart.

### Strategy builder and backtesting
Build a strategy from a template, tune its parameters, and backtest it against
historical data with modelled fees and slippage. Results come with the full
metric set — win rate, profit factor, max drawdown, Sharpe, Sortino, Calmar —
each with a plain-English explanation. Backtesting is unlimited on every tier.

### Journal and trade checks
Record why you entered a trade and how you felt, then see how often you traded
while anxious, greedy or chasing a loss. Threshold rules over your recent
history flag re-entering too fast after a loss, trade frequency or size jumping
away from your own baseline, and a daily loss cap that blocks new positions
while still letting you close what is open.

### On-device security
Biometric or PIN app lock, encrypted local storage for tokens, and a privacy
shield that blurs content in the app switcher.

---

## What it deliberately does not do

Listed here because trading apps routinely claim these and this one does not:

- **No live or real-money trading.** No broker integration, no exchange keys.
  The screen that used to collect them now offers to delete anything an older
  build saved.
- **No AI.** Signals, trade checks and the strategy builder are indicator rules
  and thresholds evaluated on candles. There is no model anywhere in the app.
- **No 24/7 automation.** The strategy runner polls while the app is open and
  stops when it is not.
- **No invented numbers.** Empty states say "no data yet". The leaderboard stays
  empty until there are verified results. Marketplace figures are labelled as
  reported by the publisher.
- **No strategy marketplace payouts.** Publishing records a listing on this
  device; nothing is bought or sold, and the rules themselves are not shipped,
  so a listed strategy cannot be run directly.

Premium ($4.99/mo or $39.99/yr, via `in_app_purchase`) lifts exactly two
limits: signals per day (10 → unlimited) and saved strategies (3 → unlimited).
Nothing else is gated.

---

## Running it

Requires the Flutter SDK (3.x) and Android Studio.

```bash
git clone https://github.com/arunvarkey/Volex-trade.git
cd Volex-trade
flutter pub get
flutter run
```

Firebase is optional — the app boots and runs fully without
`google-services.json`. Add one only if you want accounts and cloud sync.

Release builds: **[`RELEASE.md`](RELEASE.md)**.
Launch blockers: **[`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md)**.
Store copy: **[`store/play-listing.md`](store/play-listing.md)**.

## Architecture

- **Domain** — pure Dart entities and rules (orders, positions, risk manager).
- **Data** — repositories over Binance's public API and local storage (Hive,
  SharedPreferences).
- **Presentation** — Flutter widgets, Provider for state, go_router for
  navigation, GetIt for dependency injection.

## Tests

```bash
flutter analyze --fatal-infos
flutter test
```

Both run in CI on every push.

## License

MIT — see [LICENSE](LICENSE).
