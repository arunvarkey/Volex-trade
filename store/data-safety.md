# Google Play Data Safety form — answers

Derived from an audit of what the code actually does, not from what a template
suggests. Play cross-checks these declarations against observed app behaviour,
and a mismatch is a policy violation, so each answer below cites where it comes
from.

**Important:** these answers describe the app **with Firebase configured**. Until
`android/app/google-services.json` exists, Firebase is not initialised at all and
the app collects nothing — but declare the intended shipping state, not the
current one.

---

## Data collection and sharing

| Category | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| **Email address** | Yes | No | Optional | Account management, app functionality |
| **User IDs** | Yes | No | Optional | Account management |
| **Photos** | No* | No | Optional | — |
| **App interactions** | Yes | No | Optional | Analytics |
| **Crash logs** | Yes | No | Optional | Diagnostics |
| **Diagnostics** | Yes | No | Optional | Diagnostics |
| **Purchase history** | Yes | No | Optional | App functionality |
| Location | **No** | — | — | — |
| Contacts | **No** | — | — | — |
| Financial info (payment) | **No** | — | — | Google handles all payment data |
| Personal identifiers for ads | **No** | — | — | — |

\* **Photos:** the app requests image access to let you pick a profile avatar
(`image_picker`, used in `profile_service.dart`). The image stays on the device.
Declare as collected **only if** you enable profile-photo sync to Firebase. As
shipped, answer **No** and be ready to explain that the permission is for local
selection only.

---

## Answers to the specific prompts

**Does your app collect or share any of the required user data types?**
→ Yes.

**Is all of the user data collected by your app encrypted in transit?**
→ **Yes.** All network calls use HTTPS (`api.binance.com`, Firebase SDKs).
There are no plaintext HTTP endpoints in the codebase.

**Do you provide a way for users to request that their data is deleted?**
→ **Yes.** Uninstalling removes all local data; account deletion is by email
request, stated in the privacy policy. (A stronger answer is an in-app delete
button — worth adding before the account system goes live.)

**Is your data collection required or optional?**
→ **Optional.** The app runs fully as a guest with no account and no upload.

---

## Sensitive permissions declared

| Permission | Why | Play declaration needed |
|---|---|---|
| `INTERNET` | Market data, Firebase | No |
| `POST_NOTIFICATIONS` | Price alerts | No |
| `WAKE_LOCK` | Scheduled local notifications | No |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | App lock | No |
| `com.android.vending.BILLING` | Subscriptions via `in_app_purchase` | No |

`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` and the foreground-service permissions
were **removed** from the manifest. Both are declared-use permissions requiring
justification forms, and neither had a real use — the foreground service they
backed was never started. Do not add them back without a use that survives
review.

---

## Financial features declaration

Play asks whether the app provides financial services. The honest position:

- **Is this a trading or investment app?** It is a **simulator**. It does not
  execute real trades, hold funds, or connect to a brokerage.
- **Does it give financial advice?** No. Signals and AI suggestions are labelled
  educational throughout, and the app shows a risk disclosure before first use.
- **Do you need a financial services licence declaration?** Not for a simulator
  with no real money. **This changes completely if live trading is ever enabled**
  — that would likely require licensing documentation, and in many markets a
  regulator registration number, before Play will publish it.

Keep the store listing free of profit claims, performance figures, or "signals"
language. The listing copy in `play-listing.md` is written with that in mind.
