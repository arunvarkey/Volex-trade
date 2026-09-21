import '../../models/daily_models.dart';

/// Managing a trade once it exists: exits, targets, and the decisions that
/// happen after the interesting part is over.
///
/// Entries get all the attention and decide very little. What you do between
/// entry and exit is where most of the variance in outcomes actually lives,
/// and it is almost entirely decisions you can make in advance.
class ManagementBank {
  ManagementBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'mg_exit_plan',
      prompt: 'Which part of a trade is most often left undefined?',
      context: 'Entry, stop, target, size.',
      optionA: 'The target',
      optionB: 'The entry',
      correctIsA: true,
      explanation:
          'Everyone knows where they got in. Far fewer decide in advance where '
          'they get out in profit, which is why so many winners turn into '
          'break-even trades and then into losses.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_trailing',
      prompt: 'A trailing stop is designed to do what?',
      context: 'It follows price up.',
      optionA: 'Guarantee a profit',
      optionB: 'Protect gains while leaving room to run',
      correctIsA: false,
      explanation:
          'It locks in progress at the cost of giving some back at the turn. '
          'The trade-off is unavoidable: any trail tight enough to keep most '
          'of the gain is tight enough to end the trade early.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_partial',
      prompt: 'Taking half off at the first target does what to expectancy?',
      context: 'Half out, half running.',
      optionA: 'Reduces variance — and usually average return',
      optionB: 'Strictly improves it',
      correctIsA: true,
      explanation:
          'You cap part of the upside in exchange for a smoother ride. That '
          'can be a very good trade if the smoother ride is what lets you '
          'keep following the plan — but it is a trade, not a free lunch.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_target_first',
      prompt: 'Should the target be set before or after the stop?',
      context: 'Planning the trade.',
      optionA: 'Target first, always',
      optionB: 'Either, as long as both exist before entry',
      correctIsA: false,
      explanation:
          'What matters is that you know the reward-to-risk before you commit. '
          'A setup whose target is closer than its stop needs a very high win '
          'rate, and you want to know that before you are in.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_time_stop',
      prompt: 'A trade has gone nowhere for three weeks. What is a time stop '
          'for?',
      context: 'Not at the stop, not at the target.',
      optionA: 'Freeing capital and attention from a dead idea',
      optionB: 'Nothing, wait for the stop',
      correctIsA: true,
      explanation:
          'A thesis usually has a timeframe. If the move has not happened in '
          'the window you expected, the reason for the trade has quietly '
          'expired even though the price has not hit your level.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_break_even_early',
      prompt: 'Moving to break-even as soon as you are slightly up. '
          'What is the cost?',
      context: 'A common habit.',
      optionA: 'None, it is free protection',
      optionB: 'Normal noise stops you out of eventual winners',
      correctIsA: false,
      explanation:
          'Price rarely goes straight to target. A stop pulled to entry too '
          'early sits inside the ordinary pullback, converting a good trade '
          'into a scratch and leaving you watching it work without you.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_add_winner',
      prompt: 'Adding to a winner without moving the stop does what?',
      context: 'Pyramiding.',
      optionA: 'Increases total risk, possibly beyond the original plan',
      optionB: 'Nothing, the trade is profitable',
      correctIsA: true,
      explanation:
          'The new units have their own risk to the same stop. Done without '
          'recalculating, a winning trade can quietly become the largest '
          'exposure in the account at its most extended point.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'mg_let_run',
      prompt: '"Let your winners run" works only if what is also true?',
      context: 'Half the saying.',
      optionA: 'You trade frequently',
      optionB: 'You cut your losers',
      correctIsA: false,
      explanation:
          'Running winners without cutting losers is just holding everything, '
          'which is how the disposition effect gets dressed up as patience. '
          'The pair only works together.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'mg_target_hit_partially',
      prompt: 'Price reaches 95% of your target then reverses hard. '
          'What is the lesson?',
      context: 'You held for the last 5%.',
      optionA: 'Targets near obvious levels often need a margin',
      optionB: 'Never use targets',
      correctIsA: true,
      explanation:
          'If your target sits exactly at a level everyone else is selling '
          'into, you are last in the queue. Placing it slightly ahead of the '
          'crowd is a small change with a measurable effect.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_news_during',
      prompt: 'Major news lands while you are in a position. '
          'What should govern your response?',
      context: 'Unexpected event.',
      optionA: 'How dramatic the headline is',
      optionB: 'Whether your invalidation level still makes sense',
      correctIsA: false,
      explanation:
          'The question is not how exciting the news is, it is whether the '
          'reason you took the trade survives it. If the thesis is dead, the '
          'stop is now irrelevant — exit.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_multiple_positions',
      prompt: 'You have five positions and cannot watch them all. '
          'What does that tell you?',
      context: 'Feeling stretched.',
      optionA: 'You have more positions than your process supports',
      optionB: 'You need faster software',
      correctIsA: true,
      explanation:
          'Capacity is part of your strategy. Positions you cannot manage are '
          'positions being managed by chance, and adding tools does not create '
          'attention.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_scratch',
      prompt: 'Exiting a trade for roughly zero because the setup changed. '
          'Good or bad?',
      context: 'No loss, no gain.',
      optionA: 'Bad, you should wait for the stop',
      optionB: 'Good — the reason to be in it disappeared',
      correctIsA: false,
      explanation:
          'A stop is a backstop for being wrong, not an obligation to stay '
          'until it is hit. If the thesis is gone, the position is no longer '
          'the trade you took.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_stop_visible',
      prompt: 'Is a mental stop as good as a placed one?',
      context: '"I will exit if it hits X."',
      optionA: 'No — it depends on you acting under stress',
      optionB: 'Yes, it avoids stop hunts',
      correctIsA: true,
      explanation:
          'The moment a mental stop is needed is the moment you least want to '
          'honour it. Placed orders execute without asking your permission, '
          'which is the entire benefit.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_rr_change',
      prompt: 'You move your stop closer mid-trade. What happens to the '
          'reward-to-risk of the trade you actually took?',
      context: 'Target unchanged.',
      optionA: 'Nothing, R:R is set at entry',
      optionB: 'The realised ratio changes — for better or worse',
      correctIsA: false,
      explanation:
          'The planned ratio is a forecast; what you realise depends on where '
          'you actually exit. Tightening can improve it, or can convert '
          'winners into scratches. Either way it is a decision worth making '
          'by rule rather than by nerve.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_correlated_exit',
      prompt: 'Three correlated positions all approach their stops at once. '
          'What should you have planned for?',
      context: 'A market-wide move.',
      optionA: 'Total portfolio risk, not just per-trade risk',
      optionB: 'Nothing, each has its own stop',
      correctIsA: true,
      explanation:
          'Per-trade risk is meaningless if everything loses together. The '
          'cap that matters in a correlated book is the combined one, set '
          'before the positions existed.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'mg_hope',
      prompt: 'You are holding a trade past its stop because you hope it '
          'recovers. What is the position size now, in risk terms?',
      context: 'The stop was ignored.',
      optionA: 'The same as planned',
      optionB: 'Undefined — the risk has no limit',
      correctIsA: false,
      explanation:
          'A stop you do not honour is not a stop. The trade has silently '
          'become an unlimited-risk position, and the number in your plan is '
          'now fiction.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_reduce_when_unsure',
      prompt: 'You are unsure about a position but not ready to close. '
          'A reasonable action?',
      context: 'Genuine uncertainty.',
      optionA: 'Reduce size to where you can think clearly',
      optionB: 'Double it to make it worth the stress',
      correctIsA: true,
      explanation:
          'If a position is stopping you from thinking, it is too big for '
          'you, whatever the arithmetic says. Trimming to a size you can hold '
          'calmly usually improves every subsequent decision.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'mg_profit_target_rr',
      prompt: 'Your stop is 2% away and your target 1% away. What does the '
          'trade need?',
      context: 'Reward below risk.',
      optionA: 'Nothing special',
      optionB: 'A win rate above about 67%',
      correctIsA: false,
      explanation:
          'Risking 2 to make 1 means two wins are needed per loss to break '
          'even. That is achievable for some strategies and is a very high bar '
          'for most — and it needs to be checked before entry, not after.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_weekend_hold',
      prompt: 'Deciding whether to hold over a weekend should depend on:',
      context: 'Friday afternoon.',
      optionA: 'Whether the position survives a gap',
      optionB: 'Whether you are in profit',
      correctIsA: true,
      explanation:
          'Being up is not protection against a gap. The question is whether, '
          'at this size, a sharp move against you while you cannot act is '
          'survivable.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'mg_closing_all',
      prompt: 'A useful rule after hitting your daily loss limit?',
      context: 'The limit is reached.',
      optionA: 'Reduce size and keep going',
      optionB: 'Close the platform, review tomorrow',
      correctIsA: false,
      explanation:
          'Halving your size and staying keeps you making decisions in the '
          'exact state the limit was designed to interrupt. The limit only '
          'works if it ends the session.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'mg_re_entry',
      prompt: 'Stopped out, and the setup re-forms cleanly. Should you '
          're-enter?',
      context: 'The original thesis is intact.',
      optionA: 'Yes, if it meets the criteria as a fresh trade',
      optionB: 'No, never re-enter',
      correctIsA: true,
      explanation:
          'Judge it as a new trade with its own stop and size. The trap is '
          're-entering to recover the previous loss rather than because the '
          'setup qualifies — same action, entirely different reason.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'mg_stop_at_round',
      prompt: 'Placing your stop exactly at an obvious round number. '
          'What is the risk?',
      context: '50,000 exactly.',
      optionA: 'None, round numbers are strong',
      optionB: 'It sits in the busiest cluster of stops',
      correctIsA: false,
      explanation:
          'Obvious levels attract obvious stops, and the pool of forced orders '
          'is itself a reason price reaches there. Placing yours slightly '
          'beyond costs a little and avoids the crowd.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_average_exit',
      prompt: 'Scaling out over three levels achieves what?',
      context: 'Thirds.',
      optionA: 'An average exit, avoiding the all-or-nothing call',
      optionB: 'A better price than any single exit',
      correctIsA: true,
      explanation:
          'You will never sell the top and you will never sell the worst '
          'price either. Scaling trades the chance of a perfect exit for the '
          'near-certainty of an acceptable one.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_holding_through',
      prompt: 'What separates "letting a winner run" from "getting greedy"?',
      context: 'Both look identical live.',
      optionA: 'The eventual outcome',
      optionB: 'Whether a rule defined it in advance',
      correctIsA: false,
      explanation:
          'The outcome cannot tell you, because a greedy hold that works still '
          'looks like patience. The only durable distinction is whether the '
          'behaviour was planned or improvised.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_stop_size_recalc',
      prompt: 'Your account grew 30%. Your stop distances are unchanged. '
          'What should you recheck?',
      context: 'Same setups.',
      optionA: 'Position size — the same % is now more money',
      optionB: 'Nothing',
      correctIsA: true,
      explanation:
          'Percentage sizing scales up automatically, which is correct, but '
          'the absolute numbers get larger and can start to exceed what the '
          'market can absorb or what you can hold calmly.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'mg_exit_on_target_only',
      prompt: 'Only ever exiting at your stop or your target. '
          'What does that miss?',
      context: 'Strict rules.',
      optionA: 'Nothing, it is perfect discipline',
      optionB: 'Cases where the thesis dies in between',
      correctIsA: false,
      explanation:
          'Rules should include invalidation by reasoning, not just by price. '
          'The discipline is having the condition written down in advance — '
          'not refusing to think between two levels.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_watching_pnl',
      prompt: 'Managing a trade by watching the P&L number rather than the '
          'chart leads to what?',
      context: 'Eyes on the balance.',
      optionA: 'Exits driven by your account, not the market',
      optionB: 'Better discipline',
      correctIsA: true,
      explanation:
          '"I am up \$300" is not a market event. Decisions anchored on your '
          'own P&L are why people close at arbitrary round numbers and hold '
          'losers to arbitrary round numbers.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'mg_multiple_stops',
      prompt: 'Splitting one position into two with different stops. '
          'What have you created?',
      context: 'Half tight, half wide.',
      optionA: 'Half the risk',
      optionB: 'A blended risk that must still be counted in total',
      correctIsA: false,
      explanation:
          'The total risk is the sum of both legs. Splitting can be a '
          'legitimate way to stay in a move, but it is not a reduction unless '
          'the combined number is smaller than the original.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'mg_first_loss',
      prompt: '"The first loss is the cheapest." What does that mean?',
      context: 'An old saying.',
      optionA: 'Acting on your stop costs less than negotiating with it',
      optionB: 'Your first trade will lose',
      correctIsA: true,
      explanation:
          'Once you start moving stops and averaging down, the eventual exit '
          'is almost always worse than the one you refused. The saying is '
          'about the cost of delay, not about beginners.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_leave_it',
      prompt: 'A well-planned trade is running. What is usually the best '
          'action?',
      context: 'Stop and target are set.',
      optionA: 'Adjust something to stay engaged',
      optionB: 'Nothing',
      correctIsA: false,
      explanation:
          'The work was done before entry. Most mid-trade adjustments are '
          'restlessness wearing the costume of management, and they '
          'systematically cost more than they save.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_max_positions',
      prompt: 'Why cap the number of simultaneous positions?',
      context: 'A rule many traders use.',
      optionA: 'Attention and correlated risk are both finite',
      optionB: 'Exchanges limit it anyway',
      correctIsA: true,
      explanation:
          'Beyond a handful, positions stop being separately managed and start '
          'being one undifferentiated exposure you watch anxiously. The cap is '
          'about the quality of management, not just the arithmetic.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'mg_illiquid_stop',
      prompt: 'Holding a thin altcoin with a tight stop. What is the '
          'specific danger?',
      context: 'Low liquidity.',
      optionA: 'The stop will not trigger',
      optionB: 'The stop fills far below its level',
      correctIsA: false,
      explanation:
          'In a thin book there may be nothing near your price to fill '
          'against. The stop triggers and then walks down the book, which is '
          'how a planned 2% loss becomes 8%.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'mg_profit_withdraw',
      prompt: 'Periodically withdrawing profits does what?',
      context: 'Taking money off the table.',
      optionA: 'Realises gains that cannot be given back',
      optionB: 'Reduces compounding, so it is always wrong',
      correctIsA: true,
      explanation:
          'It trades some compounding for certainty. Whether that is right '
          'depends on your goals, but a trading account that has never paid '
          'you anything is an unrealised gain, and unrealised gains can '
          'reverse entirely.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'mg_two_accounts',
      prompt: 'Keeping long-term holdings and active trades in the same '
          'account. What goes wrong?',
      context: 'One balance.',
      optionA: 'Nothing, it is simpler',
      optionB: 'The blended P&L hides how the trading is really doing',
      correctIsA: false,
      explanation:
          'A rising long-term position can mask months of losing trades. '
          'Separating them is the only way to know whether the active trading '
          'is adding anything over just holding.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'mg_stop_after_entry',
      prompt: 'How long after entering should the stop be placed?',
      context: 'You just got filled.',
      optionA: 'Immediately — ideally as part of the same action',
      optionB: 'Once you see how it moves',
      correctIsA: true,
      explanation:
          'The window between entry and stop is unlimited risk, and it is '
          'exactly when a fast move can happen. If your platform supports it, '
          'submit them together.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'mg_exit_quality',
      prompt: 'Over many trades, which contributes more to results?',
      context: 'Entries versus exits.',
      optionA: 'Entries',
      optionB: 'Exits',
      correctIsA: false,
      explanation:
          'Entries determine whether you are in; exits determine how much each '
          'outcome is worth. Two traders with identical entries and different '
          'exit discipline have entirely different equity curves.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'mg_watching_alternative',
      prompt: 'Instead of watching a running trade all day, better use of '
          'the time?',
      context: 'Stop and target are placed.',
      optionA: 'Reviewing past trades',
      optionB: 'Looking for more trades',
      correctIsA: true,
      explanation:
          'Reviewing improves the process; hunting more setups mostly '
          'increases turnover. One compounds your skill, the other compounds '
          'your costs.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_alert_vs_watch',
      prompt: 'Setting a price alert instead of watching the screen. '
          'What does it protect?',
      context: 'Same information.',
      optionA: 'Nothing, it is the same',
      optionB: 'Your attention, and therefore your discipline',
      correctIsA: false,
      explanation:
          'Continuous watching produces continuous urges to act. An alert '
          'gives you the same information at the moment it matters, without '
          'the hours of temptation in between.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'mg_worst_case_first',
      prompt: 'Before entering, which question is most useful?',
      context: 'One question.',
      optionA: '"What happens if I am wrong?"',
      optionB: '"How much could I make?"',
      correctIsA: true,
      explanation:
          'The downside is the part you must survive and the part you can '
          'actually control. Starting there sets the stop and the size; '
          'starting with the upside sets neither.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'mg_good_trade_def',
      prompt: 'What is the best definition of a good trade?',
      context: 'Summing it up.',
      optionA: 'One that made money',
      optionB: 'One that followed your plan, whatever it returned',
      correctIsA: false,
      explanation:
          'Over a large sample a good process produces good results, but any '
          'single outcome is mostly variance. Judging trades by results '
          'teaches you to repeat whatever got lucky.',
      lessonId: 'p1',
    ),
  ];
}
