# Google Play listing — Volex Terminal

Copy-paste ready. Character limits noted; Play rejects over-length fields.

---

## App name (30 char max)

```
Volex: Trading Simulator
```

24 chars. Leads with the category, not the brand, because nobody is searching
for "Volex". Deliberately does **not** say "signals", "AI" or "profit" — finance
apps get extra scrutiny and those words invite it.

---

## Short description (80 char max)

```
Practice trading with virtual money on real market prices. Learn without risk.
```

77 chars.

---

## Full description (4000 char max)

```
Volex Terminal is a trading simulator. You get a virtual balance and real market
prices, so you can learn how trading actually works without putting money at risk.

Everything here is paper trading. There is no real money in the app, and it does
not connect to a broker or an exchange account.


WHAT YOU CAN DO

• Trade a virtual balance against live crypto prices from public market data
• Place market and limit orders with stop-loss and take-profit levels
• Size positions from your risk, not from a guess — the app does the maths
• Watch open positions update live, with fees applied like a real exchange
• Review every trade you have made, saved between sessions


LEARN AS YOU GO

The built-in Academy covers the basics in short lessons: how orders work, what a
stop-loss is for, how much to risk per trade, and why most beginners lose money.
Each lesson links to the part of the app where you can practise it immediately.

A trading journal lets you record why you entered a trade and how you felt, then
shows how often you traded while anxious, greedy or chasing a loss. The patterns
are usually more useful than the P&L.


TEST STRATEGIES

Backtest a strategy against historical data with modelled fees and slippage, and
read a full breakdown: win rate, profit factor, max drawdown, Sharpe, Sortino and
Calmar. Every metric has a plain-English explanation attached.


HONEST BY DESIGN

The app will not show you numbers it has not calculated. Empty states say
"no data yet" rather than filling the screen with impressive-looking figures. If
the live price feed cannot be reached, the chart is labelled as simulated data
instead of quietly pretending to be live.


IMPORTANT

Volex Terminal is educational software. It is not investment advice and not a
recommendation to buy or sell anything. Simulated results have real limits: they
cannot reproduce every cost, or how a live market would react to your orders.
Past performance, real or simulated, does not predict future results.

Trading real cryptocurrency carries a high risk of loss. Never trade money you
cannot afford to lose, and seek advice from a qualified financial adviser if you
are unsure.
```

~1,950 chars.

---

## Contact details (required by Play)

- **Support email:** `dailyvolex@gmail.com` — must match the address in the
  privacy policy, and must be monitored: Play expects account-deletion requests
  sent there to be actioned.
- **Website / phone:** optional, and better left blank than filled with a
  domain you do not own.

---

## Category and tags

- **Category:** Finance (Education is defensible, but Finance matches user intent
  and the store's own classification of trading tools)
- **Tags:** trading, simulator, investing, education, cryptocurrency
- **Contains ads:** No
- **In-app purchases:** Yes (once subscription products are live; No until then)

---

## Content rating questionnaire

Answer honestly — a wrong answer here is a policy violation, and it is checked.

| Question | Answer |
|---|---|
| Violence, sexual content, profanity, drugs | No to all |
| Simulated gambling | **No** — there is no wagering and no prize of value. |
| Users can purchase digital goods | Yes, if subscriptions are live |
| Shares user location | No |
| Allows user-to-user communication | No |

Expected outcome: **PEGI 3 / ESRB Everyone** on content alone. Set the target
audience to **18+** in the Play Console regardless: the app is Finance-category
with in-app purchases and analytics, and declaring an adult audience keeps it
out of the Families policy, whose extra obligations there is no reason to take
on. The in-app age gate and the risk disclosure both ask for 18+, so the store
declaration should agree with them.

---

## Screenshots needed

Play requires **at least 2**; 4–8 is much better. Phone screenshots must be
16:9 or 9:16, minimum 320px on the short side.

Suggested order — lead with what makes the app credible:

1. **Chart with an open position** — shows live P&L and the stop/target levels
2. **Trade ticket** — risk-based sizing, stop-loss, and the visible fee line
3. **Backtest results** — the metrics grid, which is the most "serious tool" screen
4. **Academy lesson** — shows it teaches, not just simulates
5. **Journal** — the differentiator most trading apps do not have
6. **Portfolio** — balance and position history

Capture on a real device with `adb`:

```
adb exec-out screencap -p > shot1.png
```

Avoid: empty states, placeholder text, or anything showing a $0.00 balance.

---

## Feature graphic (1024 x 500, required)

Dark background `#0A0E14`, the app icon's chart mark on the left, and to the
right:

> **Volex Terminal**
> Practice trading. Virtual money, real prices.

No screenshots inside the feature graphic — Play discourages it and it reads
poorly at small sizes.
