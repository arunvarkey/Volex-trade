import '../../models/daily_models.dart';

/// Costs, and the process that keeps a trader alive long enough to improve.
///
/// Costs are the most reliably underestimated force in retail trading: they
/// are small, certain, and compound against you, which is exactly the shape a
/// human is worst at noticing. Process is what converts a run of trades into
/// something you can learn from rather than just survive.
class CostsAndProcessBank {
  CostsAndProcessBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'c_roundtrip',
      prompt: 'Fees are 0.075% each way. What does one round trip cost?',
      context: 'In and out.',
      optionA: '0.15%',
      optionB: '0.075%',
      correctIsA: true,
      explanation:
          'You pay on entry and on exit. It sounds trivial until you count '
          'how many round trips a year you intend to make — that is the number '
          'that decides whether costs are a rounding error or the whole '
          'result.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_daily_trader',
      prompt: 'Five round trips a day at 0.15%, 250 days. '
          'What must you make just to break even?',
      context: 'Before any profit.',
      optionA: 'About 19%',
      optionB: 'Around 187% of your capital in gross gains',
      correctIsA: false,
      explanation:
          '5 × 250 × 0.15% is roughly 187%. At that frequency you are not '
          'primarily trading the market, you are trading against your own cost '
          'base — and this is before spread and slippage.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_weekly_trader',
      prompt: 'Two round trips a week at 0.15%. Annual cost drag?',
      context: 'About 100 round trips.',
      optionA: 'Roughly 15%',
      optionB: 'Roughly 1.5%',
      correctIsA: true,
      explanation:
          '100 × 0.15% is 15% a year you must earn before you earn anything. '
          'Cutting frequency is the most certain return improvement available '
          'to a retail trader, because unlike an edge it is guaranteed.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_hidden_costs',
      prompt: 'Which cost do beginners most often ignore entirely?',
      context: 'Beyond the posted fee.',
      optionA: 'The exchange fee',
      optionB: 'The spread',
      correctIsA: false,
      explanation:
          'Fees are advertised; the spread is silent. You pay it on every '
          'round trip automatically, and on illiquid pairs it can dwarf the '
          'fee. Counting only the visible cost systematically understates '
          'what trading costs.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_tight_stop_cost',
      prompt: 'Very tight stops mean more trades. What does that do to costs?',
      context: 'Getting stopped often.',
      optionA: 'Raises them — each re-entry is another round trip',
      optionB: 'Nothing, costs are per unit',
      correctIsA: true,
      explanation:
          'A stop so tight you keep getting knocked out converts one intended '
          'trade into five paid ones. The stop distance is not only a risk '
          'decision, it is a cost decision.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'c_small_edge',
      prompt: 'A strategy with a 0.1% edge per trade and 0.15% costs. '
          'What is it?',
      context: 'Real edge, real costs.',
      optionA: 'A winning strategy with overheads',
      optionB: 'A losing strategy',
      correctIsA: false,
      explanation:
          'Costs exceed the edge, so every trade is negative in expectation. '
          'Plenty of genuine patterns exist that are real and unprofitable — '
          'being right about the market is not the same as making money.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_fee_tier',
      prompt: 'Trading more to reach a lower fee tier. Sound plan?',
      context: 'The discount is real.',
      optionA: 'No — the extra trading costs more than the discount saves',
      optionB: 'Yes, lower fees are better',
      correctIsA: true,
      explanation:
          'You would pay full fees on the extra volume to earn a small '
          'discount on all of it. Volume incentives are designed to make more '
          'trading feel like saving money.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_compounding_cost',
      prompt: 'Why do small costs matter so much more over time?',
      context: 'Compounding.',
      optionA: 'They increase each year',
      optionB: 'They come out of the capital that would have compounded',
      correctIsA: false,
      explanation:
          'Every unit of cost is a unit that never earns anything afterwards. '
          'The loss is not the fee, it is the fee plus everything it would '
          'have grown into.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_tax_awareness',
      prompt: 'Frequent trading can affect your tax position how?',
      context: 'Jurisdiction-dependent.',
      optionA: 'Realising gains often can trigger more tax sooner',
      optionB: 'Trading is always tax-free',
      correctIsA: true,
      explanation:
          'Rules vary enormously and this is not tax advice, but the general '
          'shape holds: closing positions can crystallise liabilities that '
          'holding would defer. It is another cost of turnover that never '
          'shows on the chart.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'c_spread_illiquid',
      prompt: 'A tiny altcoin has a 2% spread. What does a round trip cost '
          'before fees?',
      context: 'Buy at ask, sell at bid.',
      optionA: 'About 0.2%',
      optionB: 'About 2%',
      correctIsA: false,
      explanation:
          'You start 2% down the moment you are filled. The coin has to move '
          '2% in your favour for you to be flat — which is why spread should '
          'be checked before the chart, not after.',
      lessonId: 't5',
    ),
    // ── Process ──────────────────────────────────────────────────────
    DailyCall(
      id: 'pr_what_to_log',
      prompt: 'Which is most useful to record about a trade?',
      context: 'Building a journal.',
      optionA: 'The reason you entered and where you would be wrong',
      optionB: 'The profit or loss',
      correctIsA: true,
      explanation:
          'Your broker already records P&L. What it cannot record is your '
          'reasoning — and reasoning is the only thing you can actually revise.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_review_cadence',
      prompt: 'When is reviewing your trades most useful?',
      context: 'Timing the review.',
      optionA: 'Immediately after each trade',
      optionB: 'Periodically, across many trades at once',
      correctIsA: false,
      explanation:
          'Single trades are noise; patterns live in batches. Reviewing while '
          'the last outcome still stings also guarantees the conclusion is '
          'about that outcome rather than about the pattern.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'pr_checklist',
      prompt: 'What is a pre-trade checklist mostly protecting you from?',
      context: 'Five boxes to tick.',
      optionA: 'Yourself, in a hurry',
      optionB: 'Bad market conditions',
      correctIsA: true,
      explanation:
          'The checklist does not know anything you do not. Its value is '
          'forcing a pause between impulse and order, which is where most '
          'avoidable trades die.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_rule_count',
      prompt: 'A trading plan with 40 rules. What is the likely outcome?',
      context: 'Very thorough.',
      optionA: 'Excellent discipline',
      optionB: 'You will not follow it',
      correctIsA: false,
      explanation:
          'A plan you cannot hold in your head under pressure is not a plan, '
          'it is a document. A few rules you actually obey beat forty you '
          'consult afterwards.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_measure_adherence',
      prompt: 'What percentage of your trades followed your own rules? '
          'Why track it?',
      context: 'A number most traders do not have.',
      optionA: 'Because you cannot evaluate a plan you did not follow',
      optionB: 'It is not worth tracking',
      correctIsA: true,
      explanation:
          'If half your trades were off-plan, your results say nothing about '
          'the plan. Adherence has to be measured before performance means '
          'anything.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_first_goal',
      prompt: 'A sensible first goal for a new trader?',
      context: 'Month one.',
      optionA: 'Double the account',
      optionB: 'Follow the process for 50 trades',
      correctIsA: false,
      explanation:
          'A return target is not under your control and invites the exact '
          'behaviours that destroy accounts. Adherence is entirely under your '
          'control and is the thing that has to exist before returns can.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_simulator_purpose',
      prompt: 'What is a paper account genuinely good for?',
      context: 'Being realistic.',
      optionA: 'Learning mechanics and testing a process cheaply',
      optionB: 'Proving you will be profitable live',
      correctIsA: true,
      explanation:
          'It teaches how orders, sizing and management work, and it lets you '
          'accumulate trades without paying tuition to the market. What it '
          'cannot test is your behaviour when the loss is real.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_when_to_go_live',
      prompt: 'The best signal that you might be ready for real money?',
      context: 'After paper trading.',
      optionA: 'A big paper profit',
      optionB: 'A long run of following your rules, profitable or not',
      correctIsA: false,
      explanation:
          'Paper profits can come from oversized, lucky trades — which is '
          'precisely the habit that will hurt you. Consistency of behaviour '
          'transfers; a lucky equity curve does not.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_one_change',
      prompt: 'You change three things about your strategy at once and '
          'results improve. What do you know?',
      context: 'Three simultaneous changes.',
      optionA: 'Not which change helped',
      optionB: 'All three were improvements',
      correctIsA: true,
      explanation:
          'Simultaneous changes are uninterpretable — one might be helping and '
          'another hurting. Changing one variable at a time is slow and is the '
          'only way to learn anything from the result.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'pr_position_review',
      prompt: 'Best time to decide how you will manage a trade?',
      context: 'Targets, stops, adds.',
      optionA: 'As it develops',
      optionB: 'Before you are in it',
      correctIsA: false,
      explanation:
          'Decisions made while exposed are made by the exposure. Everything '
          'you can decide in advance — where you are wrong, where you take '
          'profit, whether you add — should be decided in advance.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_learning_source',
      prompt: 'Which teaches you most about your own trading?',
      context: 'Pick one.',
      optionA: 'Your own logged trades',
      optionB: 'Another course',
      correctIsA: true,
      explanation:
          'General education has diminishing returns quickly. Your journal is '
          'the only dataset about you — your patterns, your tilt, your '
          'recurring mistake — and nobody else can supply it.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_scaling_capital',
      prompt: 'You go from \$1,000 to \$10,000. What should change?',
      context: 'Ten times the capital.',
      optionA: 'The risk percentage',
      optionB: 'Position sizes, by the same rule',
      correctIsA: false,
      explanation:
          'Percentage-of-account sizing scales automatically, which is its '
          'main virtue. What must not change is the percentage — a larger '
          'account is not permission to take more risk per trade.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'pr_stop_trading_signal',
      prompt: 'Which is a legitimate reason to stop trading for a while?',
      context: 'Self-assessment.',
      optionA: 'You have repeatedly broken your own rules',
      optionB: 'You had two losing trades',
      correctIsA: true,
      explanation:
          'Losses are the cost of doing business. Repeated rule-breaking means '
          'the process has stopped functioning, and continuing just generates '
          'more unusable data.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_benchmark_self',
      prompt: 'Comparing your returns to a stranger online is useful how?',
      context: 'They claim 300%.',
      optionA: 'It shows what is achievable',
      optionB: 'Barely — you know nothing about their risk or honesty',
      correctIsA: false,
      explanation:
          'Without risk taken, sample size, and verification, a return number '
          'is meaningless. The useful benchmark is your own previous quarter, '
          'and the passive alternative.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'pr_complexity_creep',
      prompt: 'Your strategy has grown from 3 rules to 15 over a year. '
          'What is the likely cause?',
      context: 'Each addition felt justified.',
      optionA: 'Patching individual losses that were just variance',
      optionB: 'Genuine refinement',
      correctIsA: true,
      explanation:
          'Every rule usually traces to one memorable bad trade. Added up, '
          'they fit the strategy to a handful of anecdotes — overfitting by '
          'hand, one painful trade at a time.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'pr_time_horizon',
      prompt: 'Which decision should come first?',
      context: 'Setting up.',
      optionA: 'Which indicator to use',
      optionB: 'How long you intend to hold',
      correctIsA: false,
      explanation:
          'Horizon determines everything downstream — timeframe, stop '
          'distance, how often you look, which costs matter. Choosing tools '
          'first means choosing them for a trade you have not defined.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'pr_record_no_trade',
      prompt: 'Should you log the trades you considered and skipped?',
      context: 'Nothing happened.',
      optionA: 'Yes — it shows whether your filter works',
      optionB: 'No, only real trades matter',
      correctIsA: true,
      explanation:
          'If the setups you reject consistently work out, your filter is '
          'costing you. If they consistently fail, it is earning its keep. '
          'Neither is knowable without recording the non-trades.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_goal_setting',
      prompt: '"Make \$500 this week" — what does that target encourage?',
      context: 'A cash goal.',
      optionA: 'Focus and discipline',
      optionB: 'Forcing trades when nothing is there',
      correctIsA: false,
      explanation:
          'The market does not supply opportunities on your schedule. A '
          'deadline for profit converts a flat week into pressure, and '
          'pressure into oversized trades on marginal setups.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'pr_after_big_win',
      prompt: 'The most dangerous moment for your account is often:',
      context: 'Counter-intuitive.',
      optionA: 'Right after a large win',
      optionB: 'Right after a large loss',
      correctIsA: true,
      explanation:
          'Losses make people cautious; wins make them certain. The oversized '
          'trade taken while feeling invincible is a bigger threat than the '
          'one taken while stung, though both are worth a rule.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'pr_minimum_viable',
      prompt: 'What is the smallest useful trading plan?',
      context: 'Starting out.',
      optionA: 'A detailed 20-page document',
      optionB: 'What you trade, when you enter, where you are wrong, how big',
      correctIsA: false,
      explanation:
          'Those four answers are enough to make a trade reviewable, which is '
          'the whole point. Everything else is refinement you can add once you '
          'have data showing you need it.',
      lessonId: 'p1',
    ),
  ];
}
