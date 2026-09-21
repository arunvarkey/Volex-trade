import '../../models/daily_models.dart';

/// Backtesting, statistics, and the ways a strategy lies to you.
///
/// A backtest is the only place a beginner can get evidence before risking
/// money, and it is also the easiest thing in trading to fool yourself with.
/// Almost every question here is about the difference between a result and a
/// finding.
class TestingBank {
  TestingBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'tb_sample_size',
      prompt: 'A strategy won 7 of its last 10 trades. What have you learned?',
      context: 'A 70% win rate.',
      optionA: 'That it wins about 70% of the time',
      optionB: 'Almost nothing — ten trades is noise',
      correctIsA: false,
      explanation:
          'A fair coin produces 7 heads in 10 about 12% of the time. Ten '
          'results cannot distinguish a good strategy from a lucky one. '
          'Meaningful confidence needs hundreds.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'tb_overfit',
      prompt: 'You tuned 8 parameters until the equity curve looked perfect. '
          'What did you build?',
      context: 'It is beautiful on the test data.',
      optionA: 'A description of the past',
      optionB: 'A strategy for the future',
      correctIsA: true,
      explanation:
          'With enough knobs you can fit any history exactly, including its '
          'noise. The curve is not a prediction, it is a memory. The more '
          'parameters you tuned, the less the result means.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_out_of_sample',
      prompt: 'Why hold back some data when testing?',
      context: 'You have five years of candles.',
      optionA: 'To save computation time',
      optionB: 'To test on data the tuning never saw',
      correctIsA: false,
      explanation:
          'Any strategy performs well on the data used to build it. The only '
          'informative test is on data that had no chance to influence the '
          'design — the closest thing to live trading you can get in advance.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_lookahead',
      prompt: 'Your backtest buys at the day\'s low and sells at the high. '
          'What is wrong?',
      context: 'The results are spectacular.',
      optionA: 'It is using information it could not have had',
      optionB: 'Nothing, it found the pattern',
      correctIsA: true,
      explanation:
          'The low is only known after the day ends. Look-ahead bias is the '
          'most common backtest bug and it always produces beautiful results, '
          'which is why nobody goes looking for it.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_no_costs',
      prompt: 'A backtest with no fees shows +30% a year on 500 trades. '
          'Add 0.15% round-trip costs. Roughly what is left?',
      context: 'Do the arithmetic.',
      optionA: 'Around 28%',
      optionB: 'Nothing — costs alone are about 75%',
      correctIsA: false,
      explanation:
          '500 round trips at 0.15% is roughly 75% of capital in costs. '
          'High-frequency strategies routinely look brilliant until fees are '
          'modelled, at which point they invert. Cost modelling is not a '
          'detail, it is the test.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'tb_survivorship',
      prompt: 'You test a strategy on today\'s top 20 coins over five years. '
          'What is the flaw?',
      context: 'Five years of clean data.',
      optionA: 'They are today\'s top 20 because they survived',
      optionB: 'Five years is too short',
      correctIsA: true,
      explanation:
          'You selected winners using information from the end of the period '
          'and then tested from the start. Everything that failed is missing. '
          'Survivorship bias makes almost any buy-and-hold rule look good.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_one_market',
      prompt: 'A strategy works beautifully on BTC and nowhere else. '
          'What does that suggest?',
      context: 'Tested on ten instruments.',
      optionA: 'BTC is simply the best market',
      optionB: 'It may be fitted to BTC\'s particular history',
      correctIsA: false,
      explanation:
          'An edge based on a real market behaviour usually shows up, weakly, '
          'in similar markets. One-instrument magic is more often a '
          'coincidence that survived because you went looking for it.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_bull_only',
      prompt: 'A long-only strategy tested from 2020 to 2021 shows huge '
          'returns. What is missing?',
      context: 'A period when everything rose.',
      optionA: 'Any test of how it behaves in a falling market',
      optionB: 'Nothing — the returns are real',
      correctIsA: true,
      explanation:
          'In a bull market, "buy" is the strategy and everything else is '
          'decoration. Until it is tested across a decline you do not know '
          'whether you built an edge or a beta.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_expectancy_formula',
      prompt: '60% win rate, average win \$100, average loss \$200. '
          'Expectancy per trade?',
      context: '(0.6 × 100) − (0.4 × 200).',
      optionA: 'Positive, because you win more often',
      optionB: 'Negative — about −\$20',
      correctIsA: false,
      explanation:
          '60 minus 80 is −20 per trade. Winning most of the time means '
          'nothing if the losses are twice the size. Win rate on its own is '
          'the most misleading number in trading.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'tb_expectancy_low_wr',
      prompt: '30% win rate, average win \$500, average loss \$100. '
          'Expectancy?',
      context: '(0.3 × 500) − (0.7 × 100).',
      optionA: 'Positive — about +\$80',
      optionB: 'Negative, you lose most trades',
      correctIsA: true,
      explanation:
          '150 minus 70 is +80 per trade. Losing 7 times out of 10 is fine if '
          'the 3 wins are large enough. This is why trend-following feels '
          'awful and works.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'tb_curve_smooth',
      prompt: 'A backtest equity curve is a near-perfect straight line. '
          'Reaction?',
      context: 'Almost no drawdowns.',
      optionA: 'Delight — that is the goal',
      optionB: 'Suspicion — real edges are lumpy',
      correctIsA: false,
      explanation:
          'Genuine strategies have losing months. A curve that smooth usually '
          'means a bug, a fitted parameter set, or an unmodelled cost. Beauty '
          'in a backtest is a warning sign.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_sharpe',
      prompt: 'Sharpe ratio measures what?',
      context: 'A backtest reports 1.8.',
      optionA: 'Return relative to volatility',
      optionB: 'Total profit',
      correctIsA: true,
      explanation:
          'It is excess return divided by standard deviation — how much '
          'return you got per unit of bumpiness. Two strategies with identical '
          'profit can have very different Sharpes, and you would rather hold '
          'the smoother one.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_sortino',
      prompt: 'How does Sortino differ from Sharpe?',
      context: 'Both on the same tearsheet.',
      optionA: 'It is Sharpe times two',
      optionB: 'It only penalises downside volatility',
      correctIsA: false,
      explanation:
          'Sharpe treats upside and downside swings as equally bad. Sortino '
          'counts only the downside, which matches how anyone actually feels '
          'about volatility — nobody complains about an unexpectedly good '
          'month.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_calmar',
      prompt: 'Calmar ratio compares return to what?',
      context: 'Another risk-adjusted measure.',
      optionA: 'Maximum drawdown',
      optionB: 'Average volatility',
      correctIsA: true,
      explanation:
          'Calmar is annualised return over the worst peak-to-trough fall. It '
          'answers the practical question: for the worst pain this strategy '
          'put me through, what did I get paid?',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_profit_factor',
      prompt: 'Profit factor is 1.05. What does that tell you?',
      context: 'Gross wins over gross losses.',
      optionA: 'Strongly profitable',
      optionB: 'Barely profitable — costs could erase it',
      correctIsA: false,
      explanation:
          'It means you made \$1.05 for every \$1 lost. That is a thin margin '
          'that slippage, fees or a slightly worse market can wipe out '
          'entirely. Edges need buffer, not just a positive sign.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_data_mining',
      prompt: 'You tested 200 strategies and 3 look great. What should you '
          'assume?',
      context: 'All on the same data.',
      optionA: 'Some of the 3 are lucky by construction',
      optionB: 'You found 3 edges',
      correctIsA: true,
      explanation:
          'Test enough random ideas and some will pass by chance alone. The '
          'more you searched, the higher the bar the survivors must clear. '
          'This is why out-of-sample testing exists.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_parameter_cliff',
      prompt: 'A strategy makes money at a 14-period setting and loses at 13 '
          'and 15. What does that mean?',
      context: 'A sharp peak.',
      optionA: 'You found the optimal parameter',
      optionB: 'The setting is fitted to noise',
      correctIsA: false,
      explanation:
          'Real effects are robust to small changes. A knife-edge parameter '
          'means you found an accident of this particular dataset, and the '
          'accident will not repeat.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_walk_forward',
      prompt: 'What is walk-forward testing?',
      context: 'Beyond a single train/test split.',
      optionA: 'Repeatedly re-fitting on past data and testing on the next slice',
      optionB: 'Running the backtest faster',
      correctIsA: true,
      explanation:
          'It simulates how you would actually use a strategy: fit on what you '
          'knew then, trade forward, repeat. It catches strategies that only '
          'work if you re-optimise with hindsight.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_regime',
      prompt: 'Your strategy stopped working three months ago. '
          'Most likely explanation?',
      context: 'Nothing about it changed.',
      optionA: 'It needs re-optimising to the recent data',
      optionB: 'Either the market changed or it never worked',
      correctIsA: false,
      explanation:
          'Both possibilities demand the same discipline: check whether the '
          'original edge had enough evidence behind it. Re-optimising to the '
          'last three months is how you end up permanently fitted to whatever '
          'just happened.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_slippage_model',
      prompt: 'Your backtest fills every order at the exact signal price. '
          'Realistic?',
      context: 'Market orders on a 1-minute chart.',
      optionA: 'No — real fills are worse, systematically',
      optionB: 'Yes, close enough',
      correctIsA: true,
      explanation:
          'Slippage is not random noise that averages out; it is a cost that '
          'always leans against you. Unmodelled, it flatters every result, and '
          'most of all the ones that trade frequently.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'tb_win_rate_alone',
      prompt: 'Which single number tells you least about a strategy?',
      context: 'Choose one.',
      optionA: 'Expectancy',
      optionB: 'Win rate',
      correctIsA: false,
      explanation:
          'Win rate says nothing about the size of wins and losses, so it is '
          'compatible with both a great strategy and a ruinous one. '
          'Expectancy combines both and is the number that actually predicts '
          'your equity curve.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'tb_average_vs_median',
      prompt: 'Average profit per trade is +\$50, median is −\$10. '
          'What is happening?',
      context: 'Over 300 trades.',
      optionA: 'A few huge wins carry everything',
      optionB: 'A data error',
      correctIsA: true,
      explanation:
          'Most trades lose a little and a handful win enormously. That is a '
          'legitimate profile, but it means you must take every signal — miss '
          'the few big ones and the edge is gone.',
      lessonId: 'p5',
    ),
    DailyCall(
      id: 'tb_confidence_trades',
      prompt: 'Roughly how many trades before a win rate estimate is worth '
          'much?',
      context: 'Order of magnitude.',
      optionA: 'Around 20',
      optionB: 'Hundreds',
      correctIsA: false,
      explanation:
          'Uncertainty shrinks with the square root of sample size, so 100 '
          'trades still leaves a wide band and 20 leaves almost none at all. '
          'This is why patience is a statistical requirement, not a virtue.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'tb_backtest_vs_live',
      prompt: 'Live results are consistently worse than the backtest. '
          'First thing to check?',
      context: 'Same rules, same market.',
      optionA: 'Costs and fills',
      optionB: 'Whether the market has changed',
      correctIsA: true,
      explanation:
          'Execution is the usual culprit and the easiest to verify: spread, '
          'fees, slippage, partial fills. Regime change is the more '
          'interesting explanation and the one people reach for first, which '
          'is why it is worth checking the boring one.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'tb_more_data',
      prompt: 'Testing over 10 years instead of 1 mainly gives you what?',
      context: 'Same strategy.',
      optionA: 'A higher return figure',
      optionB: 'Exposure to more market conditions',
      correctIsA: false,
      explanation:
          'Length matters because it contains variety — crashes, chop, '
          'trends. A strategy that survives several regimes has been tested '
          'against the thing that actually kills strategies.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_correlation_causation',
      prompt: 'A coin\'s price correlates 0.8 with a random unrelated series. '
          'What follows?',
      context: 'Over 50 observations.',
      optionA: 'Nothing — spurious correlations are easy to find',
      optionB: 'There is a hidden relationship',
      correctIsA: true,
      explanation:
          'Search enough series and high correlations appear by chance. '
          'Without a mechanism you can state in advance, a correlation is a '
          'coincidence with a number attached.',
      lessonId: 'r5',
    ),
    DailyCall(
      id: 'tb_equity_curve_trading',
      prompt: 'Should you stop a strategy during its drawdown and restart '
          'when it recovers?',
      context: 'It is down 15%.',
      optionA: 'Yes, protect capital',
      optionB: 'Usually not — you miss the recovery',
      correctIsA: false,
      explanation:
          'Recoveries begin inside drawdowns, so you sit out the best part and '
          'return after it. If the drawdown genuinely exceeds what you tested '
          'for, the decision is to stop permanently and re-examine, not to '
          'time it.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_random_benchmark',
      prompt: 'Your strategy returned 12%. Buy-and-hold returned 40%. '
          'Verdict?',
      context: 'Same period, same asset.',
      optionA: 'It underperformed doing nothing',
      optionB: 'It made money, so it works',
      correctIsA: true,
      explanation:
          'A positive number means nothing without a benchmark. If sitting '
          'still beat you, the strategy added risk, effort and cost to produce '
          'less. Always compare against the lazy alternative.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_p_hacking',
      prompt: 'You change the exit rule 20 times until results improve. '
          'What have you learned?',
      context: 'Same data each time.',
      optionA: 'The best exit rule',
      optionB: 'Less than the final number suggests',
      correctIsA: false,
      explanation:
          'Every look at the same data spends some of its evidential value. '
          'After twenty attempts the winning variant is at least partly a '
          'product of the search, not the market.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_paper_to_live',
      prompt: 'A strategy that worked on paper fails live. Which explanation '
          'is most often ignored?',
      context: 'Beyond costs.',
      optionA: 'The trader did not follow it',
      optionB: 'The market changed overnight',
      correctIsA: true,
      explanation:
          'The strategy usually survives contact with the market; the '
          'discipline does not. A journal is what separates "the edge decayed" '
          'from "I took six trades it never signalled".',
      lessonId: 'p1',
    ),
    DailyCall(
      id: 'tb_metric_shopping',
      prompt: 'A strategy looks bad on Sharpe, so you report Calmar instead. '
          'What is that?',
      context: 'Same strategy, different metric.',
      optionA: 'Reasonable — use the best metric',
      optionB: 'Choosing the measure that flatters you',
      correctIsA: false,
      explanation:
          'Picking the metric after seeing the results is the same error as '
          'picking the parameter after seeing the results. Decide what you '
          'care about before you look.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_trades_per_year',
      prompt: 'A strategy has a great record over 12 trades in 5 years. '
          'Usable?',
      context: 'Very selective.',
      optionA: 'Not yet — you will wait decades for evidence',
      optionB: 'Yes, selectivity is a virtue',
      correctIsA: true,
      explanation:
          'Low frequency means you can never accumulate enough trades to know '
          'whether it works. Statistical confidence needs sample size, and '
          'sample size needs either frequency or several lifetimes.',
      lessonId: 'p6',
    ),
    DailyCall(
      id: 'tb_normalise',
      prompt: 'Comparing two strategies, one on BTC and one on a stablecoin '
          'pair. What must you adjust for?',
      context: 'Very different volatility.',
      optionA: 'Nothing, profit is profit',
      optionB: 'Risk — returns are not comparable raw',
      correctIsA: false,
      explanation:
          'A 20% return earned with wild swings is not the same achievement '
          'as 20% earned smoothly. Risk-adjusted measures exist precisely so '
          'these can be compared.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'tb_reoptimise_freq',
      prompt: 'How often should a strategy be re-optimised?',
      context: 'Tempting to do it monthly.',
      optionA: 'Rarely, and by a rule fixed in advance',
      optionB: 'Whenever performance dips',
      correctIsA: true,
      explanation:
          'Re-optimising on every dip means permanently chasing the recent '
          'past. If re-fitting is part of the design, the schedule and method '
          'should be decided up front and tested walk-forward.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_zero_losses',
      prompt: 'A backtest shows zero losing trades over 400 trades. '
          'Most likely?',
      context: 'A perfect record.',
      optionA: 'An exceptional strategy',
      optionB: 'A bug',
      correctIsA: false,
      explanation:
          'Nothing real wins 400 times in a row. Look for look-ahead bias, an '
          'exit that peeks at future prices, or losses being silently dropped. '
          'Impossible results have mundane causes.',
      lessonId: 'p2',
    ),
    DailyCall(
      id: 'tb_variance_of_outcome',
      prompt: 'Two traders run the identical strategy for a year with '
          'different results. Possible?',
      context: 'Same rules, same market.',
      optionA: 'Yes — timing and variance alone explain a lot',
      optionB: 'No, identical rules give identical results',
      correctIsA: true,
      explanation:
          'Starting a week apart changes which trades you get. Over a year '
          'that dispersion is large, which is another reason to judge a method '
          'by its process and its sample, not by one person\'s account curve.',
      lessonId: 'p6',
    ),
  ];
}
