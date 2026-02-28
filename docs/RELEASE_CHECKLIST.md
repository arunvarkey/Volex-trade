# ✅ VOLEX TERMINAL - FINAL RELEASE CHECKLIST

## 🛠️ TECHNICAL PRE-FLIGHT
- [ ] **API Keys:** Ensure Binance API keys are removed from source and strictly handled via SecureStorage.
- [ ] **Firebase:** Download productive `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
- [ ] **Initialization:** Test that `ServiceLocator.setupServices()` handles slow connections without crashing.
- [ ] **Clean Build:** Run `flutter clean` and `flutter pub get`

## 🎨 ASSET PREPARATION
- [ ] **App Icon:** Generate all project icon sizes (Asset Studio or similar).
- [ ] **Screenshots:**
    - 6.5" iPhone (iPhone 15 Pro Max)
    - 5.5" iPhone (Legacy compatibility)
    - Tablet screenshots (if supported)
- [ ] **Feature Graphic:** 1024x500 for Google Play.

### 2. Feature Completion
- [x] **Simulator Module**:
    - [x] AI Strategy Generator (Template -> Config -> Generate).
    - [x] Backtesting Engine (Result Charts, Metrics).
    - [x] Paper Trading (Persistence, Models).
- [x] **Monetization**:
    - [x] Paywall Screen (UI & Logical Flow).
    - [x] Subscription Service (RevenueCat Integration).
    - [x] Entitlement Check (Premium vs Free).
- [x] **Legal & Compliance**:
    - [x] Risk Disclosure Screen (Mandatory on First Launch).
    - [x] Terms of Service & Privacy Policy Links.

## ⚖️ LEGAL & COMPLIANCE
- [x] **Privacy Policy:** Upload `PRIVACY_POLICY.md` content to your website.
- [ ] **Terms of Service:** Upload `TERMS_OF_SERVICE.md` content.
- [ ] **KYC Compliance:** Ensure the scanner correctly processes ID documents for the requested region.

## 💰 MONETIZATION
- [x] **Store Configuration:** Verify Entitlements (Pro/Elite) in RevenueCat or Play Console.
- [ ] **Pricing:** Confirm regional pricing for Monthly ($19.99) vs Yearly ($199.99) plans.

## 🚀 SUBMISSION TRACK
- [ ] **Internal Testing:** Distribute to 5-10 trusted traders.
- [ ] **Play Store:** Create "Release Track" and upload AAB.
- [ ] **App Store:** Create "New Version" in App Store Connect and upload via Xcode.
