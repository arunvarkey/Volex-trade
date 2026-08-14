# Backend setup — 100% free (Firebase Spark tier)

The app runs today **without** any backend (synthetic data + guest mode). This
guide turns on the **real** backend — accounts, cloud sync, analytics — using
Google Firebase's **free Spark plan**. No credit card, no cost.

> The code already auto-detects Firebase: drop the config file in and the
> login/signup/cloud features light up automatically. Remove it and the app
> falls back to Firebase-free guest mode. Nothing else to wire.

---

## What you get (free tier limits are generous)
- **Auth** — email/password + Google sign-in (unlimited users)
- **Cloud Firestore** — strategy/signal history sync (1 GiB stored, 50k reads/day)
- **Analytics** — free and unlimited

## What it does NOT cost
Spark plan is free forever within those limits. You only ever pay if you
upgrade to Blaze — which we do not need.

---

## Steps (~5 minutes, one time)

1. Go to <https://console.firebase.google.com> → **Add project** → name it
   `volex` (accept defaults; you can disable Google Analytics or leave it on —
   both free).

2. In the project, click the **Android** icon to add an Android app:
   - **Android package name:** `com.antigravity.volextrade`
     (must match exactly — it's the app's applicationId)
   - Nickname/SHA-1: optional, skip for now.

3. Download the generated **`google-services.json`**.

4. Put it here in the repo:
   ```
   android/app/google-services.json
   ```

5. Enable the sign-in methods you want:
   Firebase Console → **Build → Authentication → Get started** →
   **Sign-in method** → enable **Email/Password** (and **Google** if you want
   one-tap).

6. (Optional) Create the Firestore database:
   Firebase Console → **Build → Firestore Database → Create database** →
   **Start in test mode** (fine for now; we lock rules down before public
   launch).

7. Rebuild the app:
   ```
   flutter run
   ```
   The Android build auto-applies the Google-Services plugin (it's gated on the
   file existing), and on boot the app initializes Firebase and shows the real
   **login / signup** flow instead of guest mode.

---

## iOS (later, optional)
Same idea: add an **iOS** app in the Firebase console with bundle id
`com.antigravity.volextrade`, download `GoogleService-Info.plist`, and place it
in `ios/Runner/`. Not needed for Android testing.

## Verifying it worked
- App boot log shows `🔥 Firebase Connected!` (not the "guest session" path).
- You can create an account and it persists across restarts.
- `git status` should show `android/app/google-services.json` as untracked —
  **do not commit it** (it's environment config; keep it local or in secrets).

## What's still mocked after this (needs a paid key — skip for now)
- **AI strategy generation** uses a demo generator unless an LLM API key is
  wired (costs money). Everything else — data, backtest, paper-trading, signals
  — is real.
