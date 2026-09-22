import 'dart:math';

import '../models/daily_models.dart';
import 'banks/costs_process_bank.dart';
import 'banks/foundations_bank.dart';
import 'banks/indicators_bank.dart';
import 'banks/management_bank.dart';
import 'banks/mechanics_bank.dart';
import 'banks/psychology_bank.dart';
import 'banks/risk_bank.dart';
import 'banks/testing_bank.dart';

/// The pool Volex Daily draws its calls from. Each is a binary trading-
/// judgment question with a definitively correct answer, an explanation, and
/// (where relevant) an Academy lesson that teaches the concept.
///
/// These test *reasoning*, not clairvoyance — so they resolve instantly and
/// deterministically.
///
/// ## Why the pool is this large
///
/// It used to be 16 questions, drawn 5 at a time. A player saw repeats on day
/// two and had exhausted the pool by day four, so the streak they were being
/// asked to protect was a streak of re-answering questions they had already
/// answered. A daily habit needs somewhere to go; at 5 a day this pool lasts
/// about two months without repetition.
///
/// ## Why it is interleaved rather than shuffled
///
/// [all] round-robins across the topic banks instead of concatenating them,
/// because [DailyService] takes a contiguous slice for each day. Concatenated,
/// a player would get five consecutive risk questions one day and five
/// psychology questions the next. Interleaved, each day spans several topics
/// by construction, with no extra logic in the service.
///
/// Each bank is shuffled internally with a fixed seed first, so the order is
/// stable across devices and builds — every player sees the same challenge on
/// the same day, which is what makes a shared result comparable — while not
/// simply following the order the questions were written in.
class DailyQuestionBank {
  DailyQuestionBank._();

  /// Fixed so the permutation is identical everywhere. Changing it reshuffles
  /// every future day's challenge, so it should not change casually.
  static const int _seed = 20260921;

  // const, not final: every element is itself a const list, so the literal is
  // a constant expression and `final` here trips prefer_const_declarations.
  // [all] below is safe as final because a function call is never a constant
  // expression, so neither that lint nor prefer_const_constructors applies.
  static const List<List<DailyCall>> _topics = [
    _core,
    MechanicsBank.calls,
    RiskBank.calls,
    PsychologyBank.calls,
    TestingBank.calls,
    IndicatorsBank.calls,
    ManagementBank.calls,
    CostsAndProcessBank.calls,
    FoundationsBank.calls,
  ];

  /// Every question, ordered so that any contiguous run of five spans
  /// several topics.
  static final List<DailyCall> all = _interleave(_topics);

  static List<DailyCall> _interleave(List<List<DailyCall>> topics) {
    final shuffled = [
      for (var i = 0; i < topics.length; i++)
        // A per-topic seed, so two topics of equal length do not receive the
        // same permutation.
        [...topics[i]]..shuffle(Random(_seed + i)),
    ];

    final longest =
        shuffled.fold<int>(0, (m, t) => t.length > m ? t.length : m);

    // Round-robin: one from each topic, then the next from each, and so on.
    // Topics run out at different points; those simply drop out of the
    // rotation, which leaves the tail of the list less varied than the head.
    // That is acceptable because the tail is two months away and the banks
    // are close to the same size.
    return [
      for (var round = 0; round < longest; round++)
        for (final topic in shuffled)
          if (round < topic.length) topic[round],
    ];
  }

  /// The questions this feature shipped with, kept as their own topic.
  static const List<DailyCall> _core = [
    DailyCall(
      id: 'q_stop',
      prompt: 'You open a long trade. When should you decide your stop-loss?',
      context: 'Price is moving in your favour and you feel confident.',
      optionA: 'After you see how it moves',
      optionB: 'Before you enter',
      correctIsA: false,
      explanation:
          'Decide where you\'re wrong BEFORE entering — while you\'re calm. '
          'Setting stops after the fact is how small losses become big ones.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'q_size',
      prompt: 'What should decide your position size?',
      context: 'You have a \$10,000 account and a trade idea.',
      optionA: 'How much you could lose to your stop',
      optionB: 'How much you want to make',
      correctIsA: true,
      explanation:
          'Size from risk, not reward: risk ÷ stop-distance = size. Starting '
          'from "how much do I want to make" is how accounts blow up.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'q_revenge',
      prompt: 'You just took a loss. What\'s the disciplined move?',
      context: 'You feel the urge to jump straight back in to win it back.',
      optionA: 'Re-enter immediately, bigger',
      optionB: 'Step back — stick to the plan',
      correctIsA: false,
      explanation:
          'That urge is revenge trading — performance drops sharply right '
          'after a loss. A hard daily stop protects you from yourself.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'q_winrate',
      prompt: 'Can a strategy be profitable if it loses more often than it wins?',
      context: 'A system wins 40% of trades.',
      optionA: 'Yes — if wins are bigger than losses',
      optionB: 'No — you need to win most trades',
      correctIsA: true,
      explanation:
          'Expectancy, not win rate, decides profitability. Losing small and '
          'winning big beats a high win rate with poor risk/reward.',
      lessonId: 'f4',
    ),
    DailyCall(
      id: 'q_rsi',
      prompt: 'RSI has been above 70 for days in a strong uptrend. Sell signal?',
      context: '"Overbought" is often taught as a sell trigger.',
      optionA: 'Yes — overbought always means sell',
      optionB: 'No — RSI can stay high in strong trends',
      correctIsA: false,
      explanation:
          'In a strong trend RSI can stay "overbought" for a long time. '
          'Indicators are hints, not commands.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'q_volume',
      prompt: 'A breakout happens on very low volume. How much do you trust it?',
      context: 'Price pushes above resistance but few are trading.',
      optionA: 'Less — low-volume breakouts often fail',
      optionB: 'More — price moved, that\'s enough',
      correctIsA: true,
      explanation:
          'Volume is conviction. Breakouts on high volume are far more '
          'trustworthy; low-volume ones frequently reverse.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'q_support',
      prompt: 'Support finally breaks. What often happens to that level?',
      context: 'A price floor that held many times gives way.',
      optionA: 'It disappears and stops mattering',
      optionB: 'It can flip to become resistance',
      correctIsA: false,
      explanation:
          'Broken support often becomes new resistance (and vice versa). '
          'Levels are crowd memory — they keep mattering.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'q_trend',
      prompt: 'A market is in a strong downtrend. What\'s generally lower-risk?',
      context: 'Lower highs and lower lows, steadily.',
      optionA: 'Trading with the trend',
      optionB: 'Buying the dip to catch the bottom',
      correctIsA: true,
      explanation:
          'Trading with the trend puts odds on your side. "Catching the '
          'falling knife" is where beginners lose the most.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'q_candle_wick',
      prompt: 'A candle has a long lower wick after a drop. What does it hint?',
      context: 'Price fell hard, then buyers pushed it back up by the close.',
      optionA: 'Sellers are fully in control',
      optionB: 'Buyers stepped in — possible support',
      correctIsA: false,
      explanation:
          'A long lower wick shows price was rejected at the lows — buyers '
          'defended it. Often a sign of support forming.',
      lessonId: 'f3',
    ),
    DailyCall(
      id: 'q_market_order',
      prompt: 'You want a specific entry price and can wait. Which order type?',
      context: 'The price you want is a little away from the current price.',
      optionA: 'Limit order',
      optionB: 'Market order',
      correctIsA: true,
      explanation:
          'A limit order fills only at your price or better. Market orders '
          'trade now but pay the spread — worse when you can afford to wait.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'q_plan',
      prompt: 'When is the best time to write your trading rules?',
      context: 'The market is moving fast and you feel the pressure.',
      optionA: 'In the moment, reacting live',
      optionB: 'In advance, when you\'re calm',
      correctIsA: false,
      explanation:
          'A written plan hands decisions to your calm brain instead of your '
          'in-the-moment emotional one. Write it before, follow it during.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'q_backtest',
      prompt: 'A strategy looks perfect on past data after heavy tweaking. Trust it?',
      context: 'You adjusted the rules until the historical curve looked great.',
      optionA: 'Be cautious — it may be curve-fit',
      optionB: 'Yes — great past results guarantee the future',
      correctIsA: true,
      explanation:
          'Tuning rules until they fit history ("curve-fitting") often fails '
          'on new data. A backtest must be honest, not optimised to look good.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'q_risk_first',
      prompt: 'What\'s the single most important habit for surviving as a trader?',
      context: 'Everyone wants the secret indicator.',
      optionA: 'Finding the one perfect indicator',
      optionB: 'Protecting capital with risk management',
      correctIsA: false,
      explanation:
          'You can\'t trade tomorrow if you blow up today. Risk management, '
          'not a magic indicator, is what keeps you in the game.',
      lessonId: 'f4',
    ),
    DailyCall(
      id: 'q_leverage',
      prompt: 'High leverage mostly changes what about a trade?',
      context: 'A broker offers you 50x leverage.',
      optionA: 'How fast you can be wiped out',
      optionB: 'Your odds of being right',
      correctIsA: true,
      explanation:
          'Leverage magnifies both directions but does nothing for your '
          'accuracy — it mainly shortens how long a losing streak takes to '
          'ruin you.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'q_fomo',
      prompt: 'A coin just pumped 30% and everyone\'s buying. Best instinct?',
      context: 'You feel like you\'re missing out.',
      optionA: 'Chase it — momentum never stops',
      optionB: 'Be careful — FOMO entries often lose',
      correctIsA: false,
      explanation:
          'Buying because you\'re afraid of missing out usually means buying '
          'late, near a local top. Wait for your setup, not the crowd\'s.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'q_price_is',
      prompt: 'What is a market price, fundamentally?',
      context: 'Prices tick up and down constantly.',
      optionA: 'Where a buyer and seller agree right now',
      optionB: 'The true, fixed value of the asset',
      correctIsA: true,
      explanation:
          'Price is just the current agreement between buyers and sellers — '
          'a live vote, not a fixed truth.',
      lessonId: 'f2',
    ),
  ];
}
