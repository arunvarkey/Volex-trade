# Volex — Execution Roadmap

> Companion to [VISION.md](VISION.md). The vision says *what* and *why*;
> this document says *in what order, to what standard*.
> Nothing gets built that isn't specified here first.

## The process (how every feature ships)

Every feature — no exceptions — moves through five gates:

1. **Plan** — a milestone entry in this file with Goal, Scope, Acceptance
   criteria, and Required tests. If acceptance criteria can't be written,
   the feature isn't understood yet.
2. **Build** — as a self-contained feature module
   (`lib/features/<name>/` or `lib/ui/<area>/`), using design-system
   tokens (`VxColors`/`VxTypography`), singleton services for state,
   no new global coupling.
3. **Test** — unit tests for every money, progress, or math path in
   `test/features/`. Logic that can't be unit-tested gets a manual
   verification checklist in the PR/commit description.
4. **Verify** — run on a real target (device or web preview) and walk the
   acceptance criteria one by one.
5. **Ship** — push through CI (analyze + full test suite). Red CI means
   not shipped, full stop.

**Standing rules**
- No real-money execution paths (see VISION.md guardrails).
- All user-facing copy reflects the simulator identity.
- New screens must handle: loading, empty, and error states.
- First-user experience is sacred: no new feature may add friction before
  the first lesson/trade (progressive disclosure only).

---

## M0 — Engineering foundation  `IN PROGRESS`

**Goal:** every change is machine-verified; the codebase stops accruing debt.

| Item | Acceptance criteria | Status |
|---|---|---|
| CI quality gate on all branches | analyze + full test suite run on every push; red = blocked | ✅ |
| Warning cleanup | `flutter analyze` has 0 warnings; CI flips to `--fatal-warnings` | ✅ (gate is fatal-warnings; also fixed a CI-caught TextDirection compile error in VxProChart) |
| Repair quarantined legacy tests | the 11 tests skipped with `@Skip('Quarantined…')` (dashboard_provider, notifications_screen, backtest timeout, execution_manager) are fixed and un-skipped | ☐ |
| withOpacity migration + zero infos | 0 analyzer issues of any severity; CI at `--fatal-infos` | ✅ (509 withOpacity migrated; Switch/Dropdown/Radio deprecations modernized; gate fully strict) |
| fl_chart retirement | remaining fl_chart screens migrated to VxProChart or explicitly kept with a reason; unused chart widgets deleted | ☐ |

**Required tests:** existing 27 must stay green throughout.

## M1 — Real device & first testers

**Goal:** Volex runs on real hardware and reaches its first outside users.

| Item | Acceptance criteria | Status |
|---|---|---|
| **13+ age gate** | birth-agnostic 13+ confirmation before the app; stores only a derived boolean (no birthdate); under-13 gets a polite block; tested | ✅ |
| Android device run | app boots, all 5 tabs + Academy + Predictions + chart verified on a physical phone; issues logged and fixed | ☐ |
| Release build | `flutter build apk --release` succeeds; app icon, name, version correct | ☐ |
| Play internal testing | listing assets from docs/APP_STORE_ENTRY.md; ≥3 testers installed; crash-free sessions in Crashlytics | ☐ |

**Compliance decisions (need legal review before public launch):**
- Floor is **13+** (chosen): covers students, avoids COPPA's under-13 regime.
- **Store age *rating* risk:** Buzz & Predictions reads as "simulated
  gambling" to Apple/Google reviewers and may force a 17+ rating regardless
  of the 13+ floor. Options tracked: gate/hide Predictions for a lower
  rating, or accept 17+ and ship a **School Mode** build (Predictions off,
  data minimised) for the student/classroom channel.
- **Data minimisation for minors:** review Firebase Analytics/Crashlytics
  defaults; keep opt-in; no ad SDKs (none present).

**Required tests:** no new unit tests; manual device checklist executed twice
(fresh install + upgrade install).

## M2 — Retention core (the daily loop)

**Goal:** a reason to open Volex every day. Headlined by **Volex Daily** —
the daily ritual that unifies streaks, prediction, and learning into one
shareable loop (Predict → Resolve → Rank → Share). This is the retention *and*
acquisition engine: the shareable result card is the growth mechanism.

| Item | Scope | Acceptance criteria | Status |
|---|---|---|---|
| **Volex Daily v1** | 5 deterministic trading-judgment calls/day; instant resolution; streak; shareable card; wrong answers deep-link the relevant lesson | same set for everyone per date; timezone-safe streak (extend/reset/idempotent replay); share text correct; tested | ✅ this commit |
| Volex Daily v2 | layer in real resolving event markets (BTC close, Fed) from a data backend, alongside the judgment calls | resolution idempotent; honest "not yet resolved" state; true global rank | ☐ |
| Lesson quizzes | 3 questions per lesson; must pass (2/3) to mark complete | quiz UI matches lesson reader; progress only on pass; existing completions unaffected | ☐ |
| XP + levels | XP from lessons/backtests/trades/Daily; Novice→Operator→Analyst→Pro; feeds the Daily streak | levels derived from XP; persisted; tested | ☐ |
| Local notifications | daily "your calls are ready" nudge (opt-in), "market resolved" | permission asked in context, never on first launch | ☐ |

**Required tests:** streak date math (rollover, gap, idempotent replay) ✅,
deterministic daily-set generation ✅, share-text formatting ✅; then quiz
gating and XP-from-actions. Target met for v1 (+9 tests).

## M3 — Chart engine v2

**Goal:** VxProChart reaches genuine TradingView-tier depth.

| Item | Acceptance criteria |
|---|---|
| Indicator panes | RSI + MACD in a sub-pane; toggleable; math unit-tested against known values |
| Trade markers | paper-trade entries/exits drawn on the chart at their price/time |
| Drawing tools | trendline + horizontal level, drag to edit, persisted per symbol |

**Required tests:** RSI/MACD math vs reference values; marker positioning math.

## M4 — Monetization readiness

**Goal:** the subscription can actually be bought and measured.

| Item | Acceptance criteria |
|---|---|
| Play Console products | `volex_pro` monthly + yearly configured and testable via internal track |
| Funnel analytics | events: paywall_viewed, trial_started, purchase, restore; visible in Firebase |
| Limit polish | free-tier limits (3 gens / 1 backtest / 10 signals) enforced consistently and communicated in-UI before the wall is hit |

**Required tests:** limit-gating logic unit-tested.

## M5 — Act 2 opens: marketplace

**Goal:** the creator economy from VISION.md, paper-first.

| Item | Acceptance criteria |
|---|---|
| Publish a strategy | from Lab to marketplace with description + backtest stats attached |
| Real leaderboard | ranked by verified paper performance, not self-reported numbers |
| Paper copy-trading | follow a strategy → mirrored simulated fills; clearly labelled |

Specs to be detailed when M2 ships (sequencing rule: retention before
marketplace — an empty marketplace helps no one).

---

## Decision log

- 2026-07: Simulator-first identity locked (VISION.md). Live execution
  deferred to a regulated-partner integration, Act 3.
- 2026-07: Custom chart engine (VxProChart) chosen over fl_chart and over
  embedding web TradingView widgets — owning the chart is the moat.
- 2026-07: Predictions promoted to first-class tab — "everything in one
  app" (charts + events) is the differentiator vs. single-purpose apps.
- 2026-07: CI on all branches; the working branch is no longer ungated.

_Last updated: 2026-07-18_
