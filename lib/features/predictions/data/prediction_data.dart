import '../models/prediction_models.dart';

/// Curated, simulated event markets and buzz. All outcomes are hypothetical and
/// for risk-free practice only — nothing here is a real market or a prediction.
///
/// Prices are illustrative implied probabilities (cents). This is the seed set;
/// a later phase can stream live markets/news in behind the same models.
class PredictionData {
  PredictionData._();

  static const List<EventMarket> markets = [
    // ── Politics / policy ─────────────────────────────────────────────
    EventMarket(
      id: 'm_fed_cut',
      question: 'Fed cuts rates at the next FOMC meeting?',
      context:
          'Markets are split as inflation cools but the labour market stays hot. '
          'A cut would ripple through crypto and equities alike.',
      category: MarketCategory.macro,
      yesPrice: 58,
      change24h: 4,
      volume: 1840000,
      closesLabel: 'Next FOMC',
    ),
    EventMarket(
      id: 'm_gov_shutdown',
      question: 'US government shutdown before year end?',
      context:
          'Budget brinkmanship is back in the headlines. Traders price the odds '
          'of a shutdown as negotiations stall.',
      category: MarketCategory.politics,
      yesPrice: 34,
      change24h: -6,
      volume: 920000,
      closesLabel: 'Dec 31',
    ),
    EventMarket(
      id: 'm_tiktok_ban',
      question: 'TikTok forced to divest or ban upheld this year?',
      context:
          'Legal challenges continue. A ruling either way is a major tech and '
          'political flashpoint.',
      category: MarketCategory.politics,
      yesPrice: 47,
      change24h: 2,
      volume: 610000,
      closesLabel: 'This year',
    ),

    // ── Crypto ────────────────────────────────────────────────────────
    EventMarket(
      id: 'm_btc_100k',
      question: 'Bitcoin above \$100,000 this quarter?',
      context:
          'ETF inflows and the halving narrative keep bulls loud. Bears point to '
          'macro headwinds and thin liquidity.',
      category: MarketCategory.crypto,
      yesPrice: 41,
      change24h: 7,
      volume: 3120000,
      closesLabel: 'End of quarter',
    ),
    EventMarket(
      id: 'm_eth_flip',
      question: 'Ethereum outperforms Bitcoin this month?',
      context:
          'The classic ETH/BTC ratio trade. Rotation into altcoins would favour '
          'Yes; a risk-off flight to BTC favours No.',
      category: MarketCategory.crypto,
      yesPrice: 38,
      change24h: -3,
      volume: 740000,
      closesLabel: 'End of month',
    ),
    EventMarket(
      id: 'm_sol_ath',
      question: 'Solana hits a new all-time high this year?',
      context:
          'High-beta favourite of the last cycle. A strong risk-on tape could '
          'send it printing new highs.',
      category: MarketCategory.crypto,
      yesPrice: 29,
      change24h: 5,
      volume: 480000,
      closesLabel: 'This year',
    ),

    // ── Tech / business ───────────────────────────────────────────────
    EventMarket(
      id: 'm_ai_ipo',
      question: 'A major AI lab files to IPO this year?',
      context:
          'The market is desperate for a pure-play AI listing. Any S-1 filing '
          'resolves this Yes.',
      category: MarketCategory.tech,
      yesPrice: 52,
      change24h: 3,
      volume: 560000,
      closesLabel: 'This year',
    ),
    EventMarket(
      id: 'm_nvda_4t',
      question: 'Nvidia reaches a \$4T market cap this year?',
      context:
          'The AI infrastructure trade in one ticker. Data-centre demand vs a '
          'stretched valuation.',
      category: MarketCategory.tech,
      yesPrice: 44,
      change24h: -2,
      volume: 1010000,
      closesLabel: 'This year',
    ),

    // ── Culture / events ──────────────────────────────────────────────
    EventMarket(
      id: 'm_box_office',
      question: 'Top summer film crosses \$1B worldwide?',
      context:
          'A fun sentiment market. Opening-weekend numbers and word-of-mouth '
          'drive the odds.',
      category: MarketCategory.culture,
      yesPrice: 61,
      change24h: 1,
      volume: 220000,
      closesLabel: 'End of summer',
    ),
  ];

  static EventMarket? marketById(String id) {
    for (final m in markets) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The buzz / "mentions" feed — headline-driven sentiment that moves markets.
  /// Names are illustrative archetypes, not statements by real individuals.
  static const List<MentionBuzz> buzz = [
    MentionBuzz(
      id: 'b1',
      author: 'The Loud Billionaire',
      avatarEmoji: '🦅',
      quote:
          'Bitcoin is going to be BIGGER than anyone thinks. \$100K? That\'s '
          'NOTHING. Believe me.',
      bullish: true,
      mentions: 48200,
      timeAgo: '12m',
      marketId: 'm_btc_100k',
    ),
    MentionBuzz(
      id: 'b2',
      author: 'Macro Desk',
      avatarEmoji: '🏦',
      quote:
          'Soft CPI print has the whole street leaning toward a cut. Odds just '
          'jumped on the tape.',
      bullish: true,
      mentions: 12750,
      timeAgo: '38m',
      marketId: 'm_fed_cut',
    ),
    MentionBuzz(
      id: 'b3',
      author: 'Capitol Watch',
      avatarEmoji: '🗞️',
      quote:
          'Deal framework emerging in late-night talks — shutdown risk fading '
          'fast for now.',
      bullish: false,
      mentions: 9310,
      timeAgo: '1h',
      marketId: 'm_gov_shutdown',
    ),
    MentionBuzz(
      id: 'b4',
      author: 'Chip Analyst',
      avatarEmoji: '💻',
      quote:
          'Data-centre backlog is insane. \$4T is a when-not-if conversation at '
          'this point.',
      bullish: true,
      mentions: 7180,
      timeAgo: '2h',
      marketId: 'm_nvda_4t',
    ),
    MentionBuzz(
      id: 'b5',
      author: 'Altseason Caller',
      avatarEmoji: '🌗',
      quote:
          'ETH/BTC ratio still bleeding. Rotation isn\'t here yet — fade the '
          'flip callers.',
      bullish: false,
      mentions: 5640,
      timeAgo: '3h',
      marketId: 'm_eth_flip',
    ),
    MentionBuzz(
      id: 'b6',
      author: 'Silicon Signal',
      avatarEmoji: '🚀',
      quote:
          'Hearing an AI lab is prepping bankers. If true, the IPO market cracks '
          'wide open.',
      bullish: true,
      mentions: 4025,
      timeAgo: '5h',
      marketId: 'm_ai_ipo',
    ),
  ];
}
