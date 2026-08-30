# 🚀 Volex Terminal - Educational Simulator

**Professional Intelligence. Bank-Grade Security. Zero Risk.**

Volex Terminal is a **high-fidelity educational trading simulator** designed for aspiring and professional traders to master the markets without risking capital. Built with Flutter, it delivers a realistic institutional terminal experience.

![Volex Terminal Banner](https://via.placeholder.com/1200x600/000000/00E5FF?text=VOLEX+SIMULATOR)

## ✨ Simulator Features

### ⚡ **Paper Trading Engine**
- **Risk-Free Environment**: Start with $100k virtual balance.
- **Live Market Data**: Real-time price feeds powered by Binance Public Data.
- **Institutional Order Types**: Practice with Market, Limit, Stop-Loss, and Take-Profit orders.

### 🚀 **The Path to Real Capital (Future)**
- **Not a broker**: Volex does not hold funds or execute real-money trades. All trading is simulated.
- **Graduation, later**: Once you've proven your skill, a future release will let you connect a *regulated broker partner* to trade live — with your risk guardrails intact. We stay the skill-and-strategy layer; a licensed partner handles execution.

### 🛡️ **Bank-Grade Security**
- **Privacy Shield**: Visual obfuscation blurs the app content when backgrounded or in app switcher.
- **Secure Storage**: AES-256 encrypted storage for API keys and sensitive tokens.
- **Biometric/PIN Lock**: Multi-factor authentication support via `SecureAuthService`.

### 🧪 **Strategy Studio**
- **Template-Driven**: Build a strategy from a ready-made template and tune its parameters.
- **Backtesting Engine**: Validate strategies against historical data with modelled fees and slippage.

### 📊 **Pro-Level Analytics**
- **Interactive Charts**: Custom-built candlestick charts with technical indicators.
- **Live PnL Tracking**: Real-time profit and loss visualization.

### 💎 **Holographic Command** (New)
- **Volumetric UI**: Glassmorphic components with custom 12px background blur and holographic borders.
- **Quantum Switcher**: High-performance command palette for rapid symbol and screen switching.
- **Tactile Feedback**: Multisensory haptic synthesis for all order executions and critical actions.

### 🧿 **Trade Checks**
- **Revenge Trading Protection**: Rules over your recent trades that flag re-entering too fast after a loss.
- **Overtrading Detection**: Warns when trade frequency or size jumps away from your own baseline.
- **Loss Limits**: A daily loss cap that blocks new positions while still letting you close what is open.

## 📱 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Android Studio / Xcode

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/volex/terminal.git
   cd volex_terminal
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

Volex Terminal follows a **Clean Architecture** approach:

- **Domain Layer**: Pure Dart entities and business logic (Risk Manager, Order Models).
- **Data Layer**: Repositories handling API (Binance, Mock) and Local Storage (Hive).
- **Presentation Layer**: Flutter widgets using Provider for state management.

## 🧪 Testing

Run the full test suite to ensure system stability:

```bash
flutter test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with 💙 by the Volex Team**
