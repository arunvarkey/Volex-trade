# Growth and retention — an engineering plan

Written against what the code actually does, September 2026. The ordering is
deliberate: each tier is worthless until the one above it is done.

---

## The finding that matters most

**Volex Daily draws 5 questions a day from a pool of 16.**

`DailyService._callsPerDay = 5`, `DailyQuestionBank.all.length == 16`, selected
by a per-day seeded shuffle. So a user sees repeats on day 2 and has seen the
entire pool by day 4. After that, the streak we ask them to protect is a streak
of re-answering questions they have already answered.

This is the retention engine, and it has three days of fuel. Nothing else on
this list matters as much.

For scale: learners who reach a 7-day Duolingo streak are ~2.4x more likely to
return the next day. That mechanic works because there is always new content
behind it. Ours runs out before the habit forms.

**Fix:** 300+ questions — 60 days without repetition at 5/day. They are
generatable from material that already exists: 21 Academy lessons, 63 quiz
questions, the glossary's 48 terms, and real historical candles ("here is a
chart at 09:00, where would your stop go?"). Target 300 before launch, then
~20/month.

---

## Tier 0 — There are no users to retain

The app is not on the store and has never run on a device. Every number below
is zero until that changes. Two store facts worth knowing now:

- Any app with **financial features must complete the Financial features
  declaration** in Play Console. A no-real-money simulator is not a financial
  *product*, but it plainly has financial features. Fill the form; do not
  assume the educational exemption covers it.
- **New personal developer accounts now require identity verification**, which
  takes days. The "must register as an Organization" rule targets developers
  *providing* financial services — banking, stock trading, custody. A paper
  simulator should not trigger it, and comparable simulators ship under
  individual accounts. Worth confirming early rather than discovering at
  submission.

---

## Tier 1 — You cannot improve what you cannot see

Seventeen `logEvent` calls across ten event names: `app_opened`, `app_paused`,
`app_resumed`, `order_placed`, `limit_order_placed`, `trade_executed`,
`strategy_started`, `strategy_stopped`, and two `ai_guardian_*`.

Six of those ten measure trading. **None measures learning, retention, or the
activation funnel.** We could ship every change below and be unable to tell
whether any of them worked.

The minimum instrumentation, roughly in funnel order:

| Event | Answers |
|---|---|
| `onboarding_step` (index) | Where do people quit before seeing the app? |
| `activation_first_trade` | Did they reach the core action at all? |
| `daily_started` / `daily_completed` (score, streak) | Is the loop working? |
| `lesson_completed` (id, seconds) | Which lessons get abandoned? |
| `glossary_searched` (term, found) | What vocabulary are we missing? |
| `paywall_viewed` / `purchase_failed` (reason) | Where does money leak? |

Plus user properties — `streak_bucket`, `lessons_done`, `days_since_install` —
because Firebase gives cohort retention for free once users are segmentable.

**The one number to watch:** D7 retention. Category medians sit near 26% D1,
13% D7, 7% D30; finance is a little better at D1 (~30%) and ~12% by D30; edtech
is at the weak end. If D7 lands above 15% the loop works and volume is a
marketing problem. Below 8% and more users would just churn faster.

---

## Tier 2 — The retention architecture

### The constraint that makes Volex different from Duolingo

Duolingo can safely maximise "come back and do the thing," because in language
learning more practice means more skill. **In trading it inverts.** The Academy
now cites the base rates itself: Barber & Odean on overtrading, Chague et al.
on ~97% of day traders losing over time. More trading produces worse outcomes.

So the loop cannot reward *trading*. XP for placing a trade with a stop is
already capped at three awards a day for this reason. The daily judgment call
is the correct habit to build: it is repeatable, it is bite-sized, it rewards
thinking, and it carries no position risk.

This is not only the honest design. It is the effective one — trading is a poor
daily habit mechanically, because a trade takes hours to resolve and a question
takes twenty seconds.

There is also a regulatory edge here. Robinhood paid $70M to FINRA over
gamification and related failures; the FCA's PS22/10 restricts refer-a-friend
incentives in trading apps. Volex holds no money and executes nothing, so the
exposure is lower — but "engagement mechanics on a trading app" is a shape
regulators now recognise. Rewarding learning rather than volume keeps us on the
right side of it.

### Three things to build

1. **Scheduled reminders.** `flutter_local_notifications` is already a
   dependency and there is exactly one `show()` call — nothing is ever
   scheduled. A daily reminder at the hour that user normally plays is the
   single cheapest retention feature available. Two types, like Duolingo's:
   a streak-at-risk nudge, and a comeback nudge after lapse. Local
   notifications need no server and no Firebase.

2. **Streak freeze.** Losing a streak is a churn cliff — people uninstall
   rather than restart from zero. Grant one freeze a week, apply it silently,
   and tell the user retroactively that they were covered.

3. **A reason to open on day 30.** Twenty-one lessons is roughly 76 minutes of
   content. Once finished there is nothing new. The Daily question bank is the
   answer to this too, which is why it is Tier 2's dependency.

---

## Tier 3 — Distribution without a budget

No money means no paid acquisition. That leaves exactly three levers.

1. **The share loop.** `share_plus` is already a dependency. The Wordle
   mechanic is the only zero-budget loop that has repeatedly taken an app from
   nothing to millions: a spoiler-free, visually distinctive daily result.

   > Volex Daily #263 — 4/5
   > 🟩🟩🟥🟩🟩

   This needs **deep links**, which the app does not have (`app_links` is not a
   dependency and the manifest declares no `VIEW` intent filter). Without them a
   shared result is a dead string. With them it opens that day's challenge, or
   the Play listing for someone who does not have the app. Build the deep link
   before the share text; a share loop that lands on a generic store page
   converts badly.

2. **Ratings.** `in_app_review` is not a dependency. Rating count and average
   are ASO ranking inputs. Prompt after a *good* moment — a 5/5 Daily, a
   finished lesson — never on launch, never after a loss.

3. **ASO.** The listing copy in `store/play-listing.md` is already written to
   avoid the words that draw scrutiny. Title leads with the category rather
   than the brand, which is right — nobody searches "Volex."

---

## Tier 4 — The market question

The app is crypto-only, via Binance's public API. That is what makes it free to
run, and it is a real constraint on reach: industry commentary through 2026
points to declining engagement in crypto-adjacent apps.

The largest pool of new retail traders wanting exactly this product is India,
and Indian equities are the obvious expansion. The blocker is data cost —
crypto market data is free and public; NSE/BSE real-time data is licensed and
is not. A defensible middle path is delayed or end-of-day Indian equity data
for the *learning* content (lessons, Daily questions, backtests) while live
simulation stays on crypto. Learning does not need a real-time tick.

---

## What "advanced technology" would and would not fix

Nothing on the usual list moves any needle above. There is no model to add that
invents 300 questions we can trust, no framework that makes an empty question
bank deep, and no architecture that substitutes for measuring D7.

The two places where engineering quality does convert to users:

- **Install size** affects install conversion measurably. Ship an app bundle,
  not a universal APK; Play then serves per-device splits.
- **Cold start and jank** affect D1. Worth profiling once the app runs on a
  real device — and it has not run on one yet.

Both are worth doing. Neither is worth doing before Tier 1.

---

## Order of work

1. Build, install, test on a device. Merge.
2. Play Console account + financial features declaration. Ship to internal
   testing.
3. Instrumentation (Tier 1). Ship.
4. Daily question bank to 300. Scheduled reminders. Streak freeze.
5. Deep links, then the share loop. `in_app_review`.
6. Read D7 after four weeks. Decide Tier 4 on data, not on instinct.

Steps 1–3 are not growth work and will feel like a detour. They are the only
reason steps 4–6 will be anything other than guessing.

---

## Sources

- [Mobile App Retention Benchmarks by Industry (2026) — UXCam](https://uxcam.com/blog/mobile-app-retention-benchmarks/)
- [Day-1, Day-7, Day-30 Retention Benchmarks by App Category in 2026 — SEM Nexus](https://semnexus.com/day-1-day-7-day-30-retention-benchmarks-app-category-2026)
- [Duolingo Streaks: How the Mechanic Drives 2x Daily Retention](https://duolingo.deconstructoroffun.com/mechanics/streaks)
- [How Duolingo reignited user growth — Lenny's Newsletter](https://www.lennysnewsletter.com/p/how-duolingo-reignited-user-growth)
- [Financial Services — Play Console Help](https://support.google.com/googleplay/android-developer/answer/9876821)
- [Provide information for the Financial features declaration — Play Console Help](https://support.google.com/googleplay/android-developer/answer/13849271)
- [Preview: Play Console Requirements — Play Console Help](https://support.google.com/googleplay/android-developer/answer/17125096)
