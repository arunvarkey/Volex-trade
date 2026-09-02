# Release checklist — Volex Terminal

The build commands are in [`RELEASE.md`](../RELEASE.md). This file is only the
list of things to confirm before a public Play Store launch, in the order they
block each other.

The previous version of this file ticked off an AI strategy generator, a
RevenueCat integration, a strategy marketplace, KYC ID-document scanning and
$19.99/$199.99 pricing. None of those exist. A checklist that reports work as
done when it was never built is worse than no checklist, because it is the
document you trust on launch day.

---

## What actually ships

A single-purpose product: a trading simulator with virtual money on real
crypto prices, plus an Academy that teaches how to use it.

| Area | State |
|---|---|
| Paper trading (market/limit, stop-loss, take-profit, fees, slippage) | Working, persisted between sessions |
| Charting (candles, indicators, drawings, crosshair) | Working, custom-rendered |
| Backtesting with full metrics | Working, unlimited on every tier |
| Academy — 21 lessons, 63 quiz questions | Complete |
| Journal, XP, streaks | Working |
| Signals from built-in strategies | Working; 10/day free, unlimited on Premium |
| Strategy builder (form over indicator rules) | Working; 3 saved free, unlimited on Premium |
| Live trading / broker or exchange execution | **Does not exist.** Not planned for this release |
| Strategy marketplace payouts, creator tier | **Does not exist** |
| iOS build | Not attempted. Android only for this launch |

Billing is `in_app_purchase` (not RevenueCat). Two SKUs for one tier:
**Premium, $4.99/mo** and **$39.99/yr**.

---

## Blocking — cannot launch without these

- [ ] **Signing key.** `keytool` per `RELEASE.md` §B.1, then `android/key.properties`.
      Back the `.jks` and its password up somewhere you will still have in five
      years — losing it means the app can never be updated, only re-published
      under a new package name.
- [ ] **Contact email in the privacy policy.** `store/privacy-policy.html` still
      reads `REPLACE_WITH_YOUR_EMAIL`. Play requires a working address, and it
      must be one you are willing to publish.
- [ ] **Host the policy.** Any stable public URL. The manifest currently points
      at a GitHub gist; if you keep that, update the gist to match
      `store/privacy-policy.html`, which is newer than what is hosted there.
- [ ] **Play Console developer account** ($25, one time) and identity
      verification. Verification can take days — start it first.
- [ ] **Screenshots.** At least 2, ideally 4–8. Shot list and `adb` command in
      `store/play-listing.md`.
- [ ] **Feature graphic**, 1024x500. Spec in `store/play-listing.md`.
- [ ] **Data safety form.** Answers are in `store/data-safety.md`; they must
      match the hosted privacy policy exactly.
- [ ] **Content rating questionnaire.** Answers and reasoning in
      `store/play-listing.md`. Answer "no" to simulated gambling — there is no
      wager and no prize of value — and set the target audience to 18+.
- [ ] **Device test of the whole loop** on real hardware: install, age gate,
      risk disclosure, onboarding, open a trade with a stop, close it, check
      the balance moved by the right amount, force-quit, relaunch, confirm the
      position and balance survived.

## Before the build

- [ ] `flutter clean && flutter pub get`
- [ ] `flutter analyze --fatal-infos` and `flutter test` — both run in CI on
      every push, so this is a re-check, not the gate.
- [ ] Bump `version:` in `pubspec.yaml`. The `+N` build number must increase on
      every upload or Play rejects the bundle.
- [ ] `flutter build appbundle --release`, then install the equivalent APK on a
      device and use it. A bundle that has never been run is not tested.

## Optional, and deliberately not done

- **Code shrinking.** `minifyEnabled` and `shrinkResources` are `false` in
  `android/app/build.gradle`. ProGuard stripping Firebase reflection classes is
  a classic release-only crash, and this branch has no way to run a release
  build to check. Turn them on only when you can test the resulting APK on a
  device; the app is small enough that the size saving is not worth a crash you
  find in production.
- **Firebase.** The app runs without `google-services.json`. Add one only if you
  want accounts and cloud sync; the free Spark tier covers this app's usage.
- **iOS.** Needs a $99/year Apple Developer account and a Mac to build.

## If subscriptions are not live at launch

Set **In-app purchases: No** in the Play Console and leave the Premium screen
as it is. Tapping Upgrade with no products configured now says Premium is not
buyable yet and that nothing was charged, instead of doing nothing. Declaring
IAP you do not have is a listing mismatch, so leave the declaration off until
the products exist.

### Before turning IAP on

- [ ] **Report in-flight purchase failures to the user.** A purchase that fails
      *after* the Play sheet opens — declined card, cancelled, pending — arrives
      on `purchaseStream` and lands in `SubscriptionService._handlePurchaseError`
      and `_showPendingUI`, both of which only write a log line. The user sees
      nothing. Surface it (a `lastPurchaseError` field plus `notifyListeners`,
      read by the subscription screen) before anyone can actually be charged.
      It is left as-is for now because there is no way to exercise the path
      without live products, and an untested error handler in a payment flow is
      not an improvement.
- [ ] **Confirm both SKUs exist** with the ids in
      `lib/features/subscriptions/models/subscription_tier.dart`
      (`explorer_premium`, `premium_yearly`) — a mismatch is what makes the
      button fail in the first place.
- [ ] **Check what Premium actually lifts still matches the copy.** It is two
      things: signals shown per day (10 → unlimited, capped in the signals
      feed) and saved strategies (3 → unlimited, capped against the local
      strategy repository). Both hold without Firebase. The Firestore daily
      counters in `SubscriptionService` are inert in guest mode — they are not
      what enforces either limit.
