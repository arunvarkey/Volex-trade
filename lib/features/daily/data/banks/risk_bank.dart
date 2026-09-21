import '../../models/daily_models.dart';

/// Risk, position size and the arithmetic of survival.
///
/// Almost everything that ends an account is here rather than in entries. A
/// trader with a mediocre edge and disciplined sizing survives to keep
/// trading; a trader with a good edge and reckless sizing does not get enough
/// trades for the edge to show up.
class RiskBank {
  RiskBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'r_recover_50',
      prompt: 'You lose 50% of your account. What gain gets you back to even?',
      context: '\$10,000 becomes \$5,000.',
      optionA: '100%',
      optionB: '50%',
      correctIsA: true,
      explanation:
          'Losses and gains are not symmetric. Halving needs a double to '
          'undo. This asymmetry gets worse the deeper you go: down 80% needs '
          '400%. It is the single strongest argument for small losses.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_recover_10',
      prompt: 'You lose 10%. What gain returns you to even?',
      context: 'Be precise.',
      optionA: 'Exactly 10%',
      optionB: 'About 11.1%',
      correctIsA: false,
      explanation:
          '90 needs to become 100, which is 11.1%. The gap is small here and '
          'enormous at 50%, which is exactly why a rule that caps losses while '
          'they are small is worth more than any entry signal.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_size_from',
      prompt: 'Two trades, same account, same 1% risk. One has a tight stop, '
          'one a wide stop. Which gets the larger position?',
      context: 'Both risk the same cash.',
      optionA: 'The tight stop',
      optionB: 'The wide stop',
      correctIsA: true,
      explanation:
          'Size = risk ÷ stop distance. A tighter stop means more units for '
          'the same money at risk. Beginners get this backwards: they widen '
          'the stop to feel safer and leave size alone, which doubles what '
          'they stand to lose.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'r_ten_losses',
      prompt: 'Risking 2% per trade, roughly where are you after 10 straight '
          'losses?',
      context: 'Starting at \$10,000.',
      optionA: 'Down exactly 20%, at \$8,000',
      optionB: 'Down about 18%, around \$8,170',
      correctIsA: false,
      explanation:
          'Risking a percentage of a shrinking account compounds downward, so '
          'the damage is slightly less than 10 × 2%. That is the small mercy '
          'of percentage risk — and ten losses in a row is entirely normal '
          'with a 50% win rate.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_ten_losses_20',
      prompt: 'Risking 20% per trade, where are you after 10 straight losses?',
      context: 'Starting at \$10,000.',
      optionA: 'Around \$1,070 — down nearly 90%',
      optionB: 'At zero',
      correctIsA: true,
      explanation:
          'Percentage risk never quite reaches zero, which is cold comfort: '
          'you are down 89% and need a 10x to recover. Ten losses is a normal '
          'run. Sizing has to survive normal, not average.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_streak_normal',
      prompt: 'With a 50% win rate over 100 trades, a run of 6 losses is:',
      context: 'Think about coin flips.',
      optionA: 'A sign the strategy broke',
      optionB: 'Expected — it would be odd not to see one',
      correctIsA: false,
      explanation:
          'Streaks are what randomness looks like. Six in a row has about a '
          '1-in-64 chance at any given point, so across 100 trades it is more '
          'likely than not. Abandoning a strategy mid-streak is how people '
          'end up with no strategy at all.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'r_daily_cap',
      prompt: 'What is a daily loss limit actually for?',
      context: 'You have hit it by lunchtime.',
      optionA: 'To stop a bad day becoming a bad month',
      optionB: 'To make you trade more carefully later',
      correctIsA: true,
      explanation:
          'It is a circuit breaker, not a nudge. The damage after a run of '
          'losses is rarely the losses — it is the oversized trade taken to '
          'win them back. Stopping removes the opportunity.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'r_correlated',
      prompt: 'You are long BTC, ETH and SOL, each risking 1%. '
          'What is your real risk?',
      context: 'They move together most days.',
      optionA: '1%, diversified three ways',
      optionB: 'Closer to 3% on one idea',
      correctIsA: false,
      explanation:
          'Correlated positions are one position wearing three names. '
          'Diversification only helps when things move independently; in a '
          'crypto sell-off almost nothing does. Count your risk by theme, not '
          'by ticker.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'r_no_stop',
      prompt: 'A position with no stop has what maximum loss?',
      context: 'A long, held indefinitely.',
      optionA: 'Everything you put in it',
      optionB: 'Whatever you are comfortable with',
      correctIsA: true,
      explanation:
          'Without a defined exit, the position decides when you are out — '
          'usually when the pain becomes unbearable, which is the worst '
          'possible criterion and typically the bottom.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'r_leverage_edge',
      prompt: 'Does leverage improve a losing strategy?',
      context: 'The strategy loses slowly at 1x.',
      optionA: 'Yes, bigger wins make up for it',
      optionB: 'No — it loses faster',
      correctIsA: false,
      explanation:
          'Leverage is a multiplier on whatever you already have. Applied to a '
          'negative expectancy it accelerates the outcome. It is not a way to '
          'make a bad strategy work, it is a way to find out sooner.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'r_risk_pct',
      prompt: 'Account \$10,000, risking 1%, stop is \$50 away per unit. '
          'How many units?',
      context: 'Straight arithmetic.',
      optionA: '2 units',
      optionB: '20 units',
      correctIsA: true,
      explanation:
          '1% of 10,000 is \$100. Divided by a \$50 stop distance, that is 2 '
          'units. If the arithmetic feels fiddly, that is the point — it is '
          'the part people skip, and skipping it is how size ends up arbitrary.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'r_all_in',
      prompt: 'A trade you are certain about. How much should you risk?',
      context: 'Genuinely your best setup in months.',
      optionA: 'More — conviction should size the trade',
      optionB: 'The same as always',
      correctIsA: false,
      explanation:
          'Certainty is a feeling, and feelings are uncorrelated with '
          'outcomes. The trades people feel surest about are frequently the '
          'crowded ones. Consistent sizing is what stops one confident '
          'mistake from mattering more than ten careful ones.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'r_martingale',
      prompt: 'Doubling your size after each loss until you win. '
          'What is the flaw?',
      context: 'It works until it does not.',
      optionA: 'One long streak exceeds your account',
      optionB: 'Nothing — it mathematically must win eventually',
      correctIsA: true,
      explanation:
          'It requires infinite capital and no position limits. You have '
          'neither. The strategy produces many small wins and one total loss, '
          'and the small wins arrive first, which is what makes it seductive.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_free_trade',
      prompt: 'You move your stop to break-even. Is the trade now risk-free?',
      context: '"Can\'t lose now."',
      optionA: 'Yes, worst case you are flat',
      optionB: 'No — you can still lose the opportunity, and slip through it',
      correctIsA: false,
      explanation:
          'A break-even stop removes downside but does not make the trade '
          'free: gaps can fill below it, and tightening too early converts '
          'winners into scratches. "Risk-free" thinking also encourages '
          'holding on past the plan, because losing feels impossible.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'r_position_vs_account',
      prompt: 'Which number should decide your size?',
      context: 'You have \$10,000 and a \$500 idea.',
      optionA: 'What you lose if the stop hits',
      optionB: 'How much cash is spare',
      correctIsA: true,
      explanation:
          'Size from the loss, not the outlay. Two trades of identical cost '
          'can carry wildly different risk depending on where the stop sits. '
          'The only number that matters is what leaves the account when you '
          'are wrong.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'r_drawdown_def',
      prompt: 'Maximum drawdown measures what?',
      context: 'A backtest reports 30%.',
      optionA: 'The total loss at the end',
      optionB: 'The worst peak-to-trough fall along the way',
      correctIsA: false,
      explanation:
          'It is the deepest hole between a high and the following low — the '
          'pain you had to sit through, not the final result. A strategy that '
          'ends up but drew down 60% is one most people would have abandoned '
          'at the bottom.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_drawdown_live',
      prompt: 'A backtest shows a 30% maximum drawdown. What should you '
          'expect live?',
      context: 'Planning for reality.',
      optionA: 'Possibly worse — the worst is always still ahead',
      optionB: 'Exactly 30%',
      correctIsA: true,
      explanation:
          'A backtest\'s worst drawdown is the worst that happened in that '
          'sample, not a limit. Live trading gets new samples. Plan for '
          'something deeper than anything you have measured.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'r_risk_of_ruin',
      prompt: 'Which change most reduces the chance of blowing up?',
      context: 'Pick the bigger lever.',
      optionA: 'Improving win rate slightly',
      optionB: 'Cutting risk per trade',
      correctIsA: false,
      explanation:
          'Ruin is dominated by bet size. Halving risk per trade cuts the '
          'probability of ruin far more than a couple of points of win rate, '
          'and it is fully within your control — unlike your edge.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'r_scaling_in',
      prompt: 'You plan to add to a winner. When should you decide that?',
      context: 'The trade is going well.',
      optionA: 'Before entering, as part of the plan',
      optionB: 'When it is working and you feel good',
      correctIsA: true,
      explanation:
          'Adds decided mid-trade are usually decided by mood. Planning the '
          'add in advance — the level, the size, the new stop — keeps a '
          'winning position from quietly becoming the biggest risk in the '
          'account at its most extended point.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'r_overnight',
      prompt: 'Holding a leveraged position over a weekend adds what?',
      context: 'You cannot watch it.',
      optionA: 'Nothing, stops still work',
      optionB: 'Gap risk with no chance to react',
      correctIsA: false,
      explanation:
          'Stops work when there is a market to fill them. Thin weekends and '
          'sharp news produce the exact conditions where price jumps past your '
          'level. Leverage turns that jump into a liquidation.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'r_two_percent',
      prompt: 'Why do risk rules usually land around 1–2% per trade?',
      context: 'Not 10%, not 0.01%.',
      optionA: 'It survives a bad streak while still compounding',
      optionB: 'It is a regulatory requirement',
      correctIsA: true,
      explanation:
          'It is a balance. Too large and a normal losing run is fatal; too '
          'small and nothing compounds and you get bored, which has its own '
          'failure mode. The number is a judgement, but the reasoning behind '
          'it is arithmetic.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'r_kelly',
      prompt: 'A formula says your optimal bet is 25% of the account. '
          'Should you use it?',
      context: 'It maximises long-run growth in theory.',
      optionA: 'Yes, maths beats intuition',
      optionB: 'No — it assumes you know your edge exactly',
      correctIsA: false,
      explanation:
          'Full-Kelly sizing is optimal only if your estimated edge is '
          'correct. Estimates from small samples are wrong, and overbetting a '
          'mis-estimated edge is ruinous. Practitioners use a fraction of it '
          'for exactly this reason.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'r_stop_placement',
      prompt: 'Where should a stop go?',
      context: 'You are long at 50,000.',
      optionA: 'Where the idea is proven wrong',
      optionB: 'At the loss you are willing to take',
      correctIsA: true,
      explanation:
          'The stop belongs at the level that invalidates the trade; the size '
          'is then chosen so that reaching it costs what you are willing to '
          'lose. Doing it the other way round puts your stop wherever your '
          'wallet says, which the market has no reason to respect.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'r_moving_stop_away',
      prompt: 'Price approaches your stop. You move it further away. '
          'What have you done?',
      context: 'Still convinced you are right.',
      optionA: 'Given the trade room to work',
      optionB: 'Increased your risk after the fact',
      correctIsA: false,
      explanation:
          'The plan said the idea was wrong at that level. Moving the stop '
          'does not make the idea right; it makes the loss bigger and the plan '
          'meaningless. Stops should only ever move toward you.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'r_portfolio_heat',
      prompt: 'Six open positions, each risking 2%. What is your exposure?',
      context: 'All could hit their stops.',
      optionA: '12% if they all go wrong',
      optionB: '2% — only one will lose',
      correctIsA: true,
      explanation:
          'Simultaneous positions stack. Total open risk — sometimes called '
          'heat — is what a bad day can take, and in correlated markets bad '
          'days tend to hit everything at once. Cap the total, not just each '
          'trade.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'r_stop_too_tight',
      prompt: 'Your stops keep getting hit before the move happens. '
          'Most likely cause?',
      context: 'You are often right about direction.',
      optionA: 'The market is out to get you',
      optionB: 'The stop is inside normal noise',
      correctIsA: false,
      explanation:
          'A stop closer than the instrument\'s ordinary wiggle will be hit by '
          'the wiggle. The fix is a stop outside the noise and a smaller '
          'position to keep the cash risk the same — not a wider stop at the '
          'same size.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'r_unrealised',
      prompt: 'Is an unrealised loss different from a realised one?',
      context: '"It is not a loss until I sell."',
      optionA: 'Economically no — it is your money either way',
      optionB: 'Yes, only closed trades count',
      correctIsA: true,
      explanation:
          'The position is worth what it is worth. "Not a loss until I sell" '
          'is a story that lets losers run, and it is the precise mechanism '
          'behind the disposition effect — selling winners early and holding '
          'losers long.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'r_risk_after_win',
      prompt: 'After three big wins, what should happen to your risk per '
          'trade?',
      context: 'You are feeling sharp.',
      optionA: 'Increase it while you are hot',
      optionB: 'Nothing — the rule is the rule',
      correctIsA: false,
      explanation:
          'Winning streaks feel like skill and are mostly variance. Sizing up '
          'after wins means your largest bets land exactly when your judgement '
          'is most distorted by success. If risk scales at all, it should '
          'scale with account size, automatically.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'r_max_loss_day',
      prompt: 'Which is the more useful limit?',
      context: 'Designing your rules.',
      optionA: 'A cap on loss for the day',
      optionB: 'A target for profit for the day',
      correctIsA: true,
      explanation:
          'A loss cap protects the account from you. A profit target does the '
          'opposite of what you want — it stops you when things are working '
          'and says nothing when they are not.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'r_borrowed',
      prompt: 'Trading with money you need within six months means what?',
      context: 'Rent money, tuition money.',
      optionA: 'Nothing, money is money',
      optionB: 'The timeline forces bad decisions',
      correctIsA: false,
      explanation:
          'A deadline removes your ability to wait out a drawdown, which is '
          'the one advantage a small trader has. Needing to be right by a date '
          'turns a normal losing stretch into forced selling at the worst '
          'moment.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'r_liquidation_price',
      prompt: 'You are liquidated. What did you get back?',
      context: 'A leveraged long, margin exhausted.',
      optionA: 'Little or nothing of that margin',
      optionB: 'Your position, closed at your stop',
      correctIsA: true,
      explanation:
          'Liquidation is the exchange closing you out to protect itself, not '
          'an exit you chose. The margin is largely gone, often with a fee on '
          'top. A stop is you deciding; a liquidation is you having no say.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'r_leverage_small_account',
      prompt: 'Why is high leverage especially dangerous on a small account?',
      context: '\$200 to trade with.',
      optionA: 'Exchanges charge small accounts more',
      optionB: 'The urge to make it meaningful invites ruinous size',
      correctIsA: false,
      explanation:
          'Small accounts make sensible risk feel pointless — 1% of \$200 is '
          '\$2 — so people reach for leverage to make it matter. That converts '
          'a slow learning account into a fast losing one, and the lesson you '
          'learn is the wrong one.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'r_hedge',
      prompt: 'You are long BTC and open an equal short to "hedge". '
          'What have you got?',
      context: 'Same size, same instrument.',
      optionA: 'No position, and two sets of costs',
      optionB: 'Protection while you decide',
      correctIsA: true,
      explanation:
          'Equal and opposite is flat, plus fees and possibly funding on both '
          'legs. It is usually an expensive way to avoid admitting you want '
          'out. If you want no position, close the position.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'r_risk_reward_min',
      prompt: 'A setup offers 1:0.5 — risking 100 to make 50. What win rate '
          'do you need just to break even?',
      context: 'Before costs.',
      optionA: '50%',
      optionB: 'Over 66%',
      correctIsA: false,
      explanation:
          'To break even you need wins × 50 = losses × 100, so two wins per '
          'loss — above 66%. Poor reward-to-risk demands a win rate most '
          'strategies cannot sustain, and costs make it worse.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'r_stop_and_size_link',
      prompt: 'You widen your stop from 2% to 4% and keep the same position '
          'size. What happened to your risk?',
      context: 'Same entry, same units.',
      optionA: 'It doubled',
      optionB: 'It stayed the same',
      correctIsA: true,
      explanation:
          'Risk is size × stop distance. Doubling the distance without halving '
          'the size doubles the loss. A wider stop feels more conservative and '
          'is the exact opposite unless the size moves with it.',
      lessonId: 'r2',
    ),
  ];
}
