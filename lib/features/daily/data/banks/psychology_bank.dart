import '../../models/daily_models.dart';

/// The trader, not the market.
///
/// The Academy's base-rate lesson cites the uncomfortable research: the large
/// majority of active retail traders lose over time, and overtrading is the
/// mechanism. Almost none of that is caused by bad analysis. It is caused by
/// people doing things they had already decided not to do.
class PsychologyBank {
  PsychologyBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'ps_revenge_size',
      prompt: 'After a loss, what usually happens to the next trade\'s size?',
      context: 'Be honest about the pattern.',
      optionA: 'It stays the same',
      optionB: 'It gets bigger',
      correctIsA: false,
      explanation:
          'The urge to win it back arrives with the loss. That is why the '
          'trade after a loss is statistically the most dangerous one most '
          'people take — and why a rule that fixes size in advance is worth '
          'more than the intention to stay calm.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_disposition',
      prompt: 'Which do most traders hold longer?',
      context: 'One is up, one is down.',
      optionA: 'The loser',
      optionB: 'The winner',
      correctIsA: true,
      explanation:
          'Selling a winner confirms you were right; selling a loser confirms '
          'you were wrong. So people bank gains early and let losses run — the '
          'disposition effect. It is precisely backwards from what the '
          'arithmetic wants.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_fomo_entry',
      prompt: 'A coin is up 40% today and you have no position. '
          'What does that feeling tell you about the trade?',
      context: 'The urge is strong.',
      optionA: 'That momentum is strong and you should join',
      optionB: 'Nothing about the trade — only about you',
      correctIsA: false,
      explanation:
          'The intensity of wanting in is not evidence. It is usually at its '
          'peak after a move has already happened, which is exactly when risk '
          'is highest and the stop would have to be furthest away.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_overtrading',
      prompt: 'Research on retail traders finds that trading more frequently '
          'tends to produce:',
      context: 'Studies across multiple markets.',
      optionA: 'Worse net returns',
      optionB: 'Better returns through practice',
      correctIsA: true,
      explanation:
          'Barber and Odean found the most active traders underperformed the '
          'least active by a wide margin, and costs explained much of it. More '
          'activity is not more skill; it is more fees, more spread and more '
          'chances to be impulsive.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'ps_confirmation',
      prompt: 'You are long and searching for bullish opinions. '
          'What is that?',
      context: 'You already have the position.',
      optionA: 'Diligent research',
      optionB: 'Confirmation bias — looking for agreement, not truth',
      correctIsA: false,
      explanation:
          'Research done after the position is usually advocacy. The useful '
          'version is deliberately hunting the strongest argument against '
          'yourself — and the useful time is before you enter.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_hindsight',
      prompt: '"I knew that was going to happen." What is wrong with it?',
      context: 'Looking at yesterday\'s chart.',
      optionA: 'The past always looks inevitable afterwards',
      optionB: 'Nothing, you read it correctly',
      correctIsA: true,
      explanation:
          'Once the outcome is known the chart reorganises itself around it. '
          'The only honest test of what you knew is what you wrote down '
          'beforehand — which is most of what a journal is for.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_process_outcome',
      prompt: 'A trade that broke all your rules made money. '
          'Was it a good trade?',
      context: 'Profit is profit.',
      optionA: 'Yes, the result proves it',
      optionB: 'No — good process, not good result',
      correctIsA: false,
      explanation:
          'A rule-breaking winner is the most expensive kind, because it '
          'rewards the behaviour that will eventually cost you. Judge trades '
          'by whether you followed the plan; judge the plan by results over '
          'many trades.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_tilt',
      prompt: 'You notice you are angry at the market. What is the correct '
          'next action?',
      context: 'Mid-session, down on the day.',
      optionA: 'Stop trading for the day',
      optionB: 'Take a smaller position to calm down',
      correctIsA: true,
      explanation:
          'Anger is not a state you trade your way out of. "Smaller" still '
          'keeps you at the screen making decisions with a broken instrument. '
          'The only reliable intervention is to leave.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_boredom',
      prompt: 'Nothing meets your criteria today. What is the right trade?',
      context: 'Hours of watching.',
      optionA: 'The closest thing to a setup',
      optionB: 'None',
      correctIsA: false,
      explanation:
          'Boredom is a cost of having standards, not a signal. "Nearly a '
          'setup" is just a setup with the edge removed, and taking it teaches '
          'you that the criteria are optional.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_sunk_cost',
      prompt: 'You have held a loser for three weeks. Should that time '
          'affect your decision?',
      context: '"I have waited this long."',
      optionA: 'No — only what happens from here matters',
      optionB: 'Yes, you have earned the right to be patient',
      correctIsA: true,
      explanation:
          'Time already spent is gone whatever you do next. The only question '
          'is whether you would open this position today at this price. If '
          'not, the waiting is not a reason to continue.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_lucky_win',
      prompt: 'Your first three trades were big winners. What is the danger?',
      context: 'New to trading.',
      optionA: 'None — a good start is a good start',
      optionB: 'You learn the wrong lesson and size up',
      correctIsA: false,
      explanation:
          'Early luck is the worst possible teacher, because it confirms '
          'whatever you happened to be doing. The traders who survive tend to '
          'be the ones whose first lesson was cheap and early.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_social',
      prompt: 'Someone posts a screenshot of a 900% gain. What is missing?',
      context: 'Social media.',
      optionA: 'Every losing trade they did not post',
      optionB: 'Nothing, it is verified',
      correctIsA: true,
      explanation:
          'Timelines are a survivorship machine: winners get posted, losers '
          'get deleted. You are seeing the tail of a distribution and '
          'mistaking it for the middle.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'ps_averaging_feeling',
      prompt: 'Why does adding to a loser feel so reasonable in the moment?',
      context: 'You are down 10%.',
      optionA: 'Because it genuinely reduces risk',
      optionB: 'It converts admitting error into "buying cheaper"',
      correctIsA: false,
      explanation:
          'The reframe is the trap. Nothing about the position improved; only '
          'the story did. The clue is that the argument arrived after the '
          'loss, not before the entry.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'ps_screen_time',
      prompt: 'Does watching the chart more closely improve your results?',
      context: 'Six hours of staring.',
      optionA: 'No — it mostly increases the urge to act',
      optionB: 'Yes, more information is better',
      correctIsA: true,
      explanation:
          'More screen time rarely produces new information on a position you '
          'have already sized and stopped. What it reliably produces is '
          'fidgeting: early exits, widened stops, unplanned adds.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_journal_when',
      prompt: 'When should you write down why you took a trade?',
      context: 'For it to be useful.',
      optionA: 'After it resolves',
      optionB: 'Before or at entry',
      correctIsA: false,
      explanation:
          'Written afterwards, the reason is reconstructed to fit the result. '
          'Written at entry, it is testable — and the gap between the two is '
          'where the real learning is.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_emotion_log',
      prompt: 'Why log how you felt on each trade?',
      context: 'It seems unscientific.',
      optionA: 'Patterns in mood predict patterns in mistakes',
      optionB: 'It does not help',
      correctIsA: true,
      explanation:
          'Nobody remembers being anxious on trade 40. But if the anxious '
          'trades cluster around your losses, that is an edge you can act on — '
          'a rule about when not to trade, derived from your own data.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_plan_deviation',
      prompt: 'You exited early because it "felt wrong". The trade then hit '
          'your target. What should you record?',
      context: 'You made less than planned.',
      optionA: 'A win, since you made money',
      optionB: 'A rule violation, even though it cost little',
      correctIsA: false,
      explanation:
          'The breach is the data point. Recorded as a win, it disappears; '
          'recorded as a deviation, it becomes part of a countable pattern '
          'you can actually fix.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_streak_confidence',
      prompt: 'After five straight wins, your estimate of your own skill '
          'should move how much?',
      context: 'Five trades.',
      optionA: 'Barely at all',
      optionB: 'Substantially upward',
      correctIsA: true,
      explanation:
          'Five results cannot separate skill from luck — a coin does that '
          'about 3% of the time. Confidence tends to move much further than '
          'the evidence allows, and size follows confidence.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'ps_advice_source',
      prompt: 'Someone with a huge following says a coin will 10x. '
          'How should that change your plan?',
      context: 'They are usually confident.',
      optionA: 'Follow it — reach implies accuracy',
      optionB: 'Not at all, unless it changes your evidence',
      correctIsA: false,
      explanation:
          'Audience size measures entertainment, not accuracy, and the '
          'incentive to sound certain is enormous. Anyone worth listening to '
          'gives you reasoning you can check, not a target.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'ps_one_more',
      prompt: '"One more trade to get back to even." What is the tell?',
      context: 'Late in a losing day.',
      optionA: 'The goal is a number, not a setup',
      optionB: 'Nothing wrong — it is a target',
      correctIsA: true,
      explanation:
          'When the reason to trade is your P&L rather than the market, the '
          'market is no longer involved in the decision. That is the exact '
          'state a daily loss limit exists to interrupt.',
      lessonId: 'r3',
    ),
    DailyCall(
      id: 'ps_analysis_paralysis',
      prompt: 'You have twelve indicators and still cannot decide. '
          'What is the likely problem?',
      context: 'More tools have not helped.',
      optionA: 'Not enough indicators',
      optionB: 'No rule for what counts as a setup',
      correctIsA: false,
      explanation:
          'Indicators do not decide; criteria do. Adding another view of the '
          'same price data mostly adds another chance to find disagreement. '
          'The fix is a written definition of the trade, not a thirteenth '
          'oscillator.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_recency',
      prompt: 'Your last three losses were all shorts, so you stop shorting. '
          'Sound reasoning?',
      context: 'Three trades.',
      optionA: 'No — three outcomes is not a finding',
      optionB: 'Yes, adapt to what is working',
      correctIsA: true,
      explanation:
          'Recency makes the last few trades feel like the whole picture. '
          'Adapting to noise means constantly abandoning whatever just lost, '
          'which guarantees you are always out of whatever is about to work.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'ps_break_after_loss',
      prompt: 'What is the most useful thing to do immediately after a big '
          'loss?',
      context: 'It just closed.',
      optionA: 'Analyse the chart for the re-entry',
      optionB: 'Step away before deciding anything',
      correctIsA: false,
      explanation:
          'Analysis done while stung is advocacy for getting the money back. '
          'The chart will still be there in an hour; the urge will not be, and '
          'that is the point.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_identity',
      prompt: '"I am a trend trader." What is the risk in that sentence?',
      context: 'Identity and strategy.',
      optionA: 'Being wrong starts to feel like a threat to who you are',
      optionB: 'None — commitment is good',
      correctIsA: true,
      explanation:
          'When a method becomes an identity, evidence against it becomes '
          'personal, and you defend it past the point of usefulness. Holding '
          'the method loosely is what lets you update.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_small_account_pressure',
      prompt: 'Why do small accounts often blow up faster than large ones?',
      context: 'Same markets, same tools.',
      optionA: 'Small accounts get worse fills',
      optionB: 'Sensible risk feels too slow, so rules get abandoned',
      correctIsA: false,
      explanation:
          'On \$200, correct sizing earns pennies, which feels pointless — so '
          'the leverage goes up and the rules go out. The account size did not '
          'cause it; the impatience it produced did.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'ps_watching_after_exit',
      prompt: 'You exited at your stop and price immediately reversed. '
          'What was the mistake?',
      context: 'You followed the plan exactly.',
      optionA: 'There was none — this happens',
      optionB: 'Using a stop at all',
      correctIsA: true,
      explanation:
          'A correct decision can have a bad outcome; that is what '
          'probability means. Treating this as proof that stops are wrong is '
          'how people arrive at the no-stop trade that ends the account.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_missed_move',
      prompt: 'You missed a big move entirely. What is the correct response?',
      context: 'It went without you.',
      optionA: 'Chase it so you do not miss more',
      optionB: 'Nothing — a missed trade costs you zero',
      correctIsA: false,
      explanation:
          'Missing a trade has no effect on your account. Chasing one does. '
          'The feeling of loss is real, but the loss itself is imaginary until '
          'you act on it.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_rules_when_written',
      prompt: 'When are trading rules most likely to be sensible?',
      context: 'Writing them down.',
      optionA: 'When you have no position open',
      optionB: 'In the middle of a trade',
      correctIsA: true,
      explanation:
          'Rules written while exposed are written by the exposure. The calm '
          'version of you is the one qualified to constrain the agitated '
          'version — which is the entire point of writing them at all.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_target_greed',
      prompt: 'Price hits your target. You move the target higher. '
          'What have you changed?',
      context: 'It is still going up.',
      optionA: 'Nothing — letting winners run',
      optionB: 'A planned trade into an unplanned one',
      correctIsA: false,
      explanation:
          'Trailing a stop is a plan; moving a target mid-trade because it '
          'feels strong is improvisation. The difference is whether the rule '
          'existed before the emotion did.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_two_screens',
      prompt: 'Does more equipment — screens, subscriptions, faster data — '
          'reliably improve retail results?',
      context: 'The trading-desk aesthetic.',
      optionA: 'No — the binding constraint is usually behaviour',
      optionB: 'Yes, professionals use it for a reason',
      correctIsA: true,
      explanation:
          'Institutions need speed because their strategies need it. A '
          'discretionary trader losing to overtrading and oversizing does not '
          'get better with lower latency. Spend on the constraint you actually '
          'have.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_explain_simply',
      prompt: 'You cannot explain your trade idea in one sentence. '
          'What does that suggest?',
      context: 'It takes five minutes to justify.',
      optionA: 'It is a sophisticated setup',
      optionB: 'The idea may be a rationalisation',
      correctIsA: false,
      explanation:
          'Complexity is often the sound of an argument being assembled to '
          'justify a decision already made. Genuine setups tend to be '
          'statable: this level, this invalidation, this target.',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'ps_loss_aversion',
      prompt: 'Research suggests a loss feels roughly how painful compared '
          'to an equal gain?',
      context: 'Behavioural economics.',
      optionA: 'About twice',
      optionB: 'About the same',
      correctIsA: true,
      explanation:
          'Losses register around twice as strongly as equivalent gains. That '
          'asymmetry is why holding losers feels bearable and closing them '
          'feels awful — and why the rule has to be set before the feeling '
          'arrives.',
      lessonId: 'p3',
    ),
    DailyCall(
      id: 'ps_streak_pressure',
      prompt: 'A long daily streak starts making you trade just to keep it. '
          'What should you do?',
      context: 'The streak has become the goal.',
      optionA: 'Take a small trade to maintain it',
      optionB: 'Let the streak go',
      correctIsA: false,
      explanation:
          'A habit that starts generating trades is no longer helping. In '
          'this app the streak tracks judgment practice, not trading, for '
          'exactly that reason — practising is safe to do daily, trading is '
          'not.',
      lessonId: 'f5',
    ),
    DailyCall(
      id: 'ps_certainty',
      prompt: 'What is a realistic level of certainty on any single trade?',
      context: 'Even a great setup.',
      optionA: 'A probability, never a certainty',
      optionB: 'High confidence is achievable',
      correctIsA: true,
      explanation:
          'Every trade is a bet on a distribution. Thinking in probabilities '
          'makes losses ordinary rather than shocking, which is what keeps '
          'sizing and behaviour stable across them.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'ps_copy_trading',
      prompt: 'Copying someone else\'s trades. What is the hidden problem?',
      context: 'They have a good record.',
      optionA: 'It always works if they are good',
      optionB: 'You cannot hold through a drawdown you do not understand',
      correctIsA: false,
      explanation:
          'Conviction is not transferable. When the inevitable losing stretch '
          'arrives you have no reasoning of your own to hold onto, so you quit '
          'at the bottom — capturing their drawdown and none of their '
          'recovery.',
      lessonId: 'p1',
    ),
  ];
}
