import '../../models/daily_models.dart';

/// How markets and orders actually work.
///
/// Mechanics questions are the ones beginners most often get wrong for free —
/// not because the concept is hard, but because nobody told them. A market
/// order is not "buy at the price on screen", and a stop order is not a
/// guarantee. Both misunderstandings cost money the first time they matter.
class MechanicsBank {
  MechanicsBank._();

  static const List<DailyCall> calls = [
    DailyCall(
      id: 'm_market_fill',
      prompt: 'You place a market order. What price do you get?',
      context: 'The screen shows BTC at 50,000.',
      optionA: 'Whatever the book offers when it arrives',
      optionB: 'Exactly 50,000',
      correctIsA: true,
      explanation:
          'A market order buys whatever is being sold, at whatever price that '
          'is. The number on screen is the last trade, not a quote you are '
          'entitled to. The gap is slippage, and it grows when the market is '
          'thin or fast.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_spread',
      prompt: 'The bid is 49,990 and the ask is 50,010. You buy, then '
          'immediately sell. Where do you stand?',
      context: 'Ignore fees for a moment.',
      optionA: 'Flat — nothing moved',
      optionB: 'Down about 20 per coin',
      correctIsA: false,
      explanation:
          'You buy at the ask and sell at the bid, so a round trip costs the '
          'spread even if price never moves. On a wide-spread market that is a '
          'loss you took before you had an opinion.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'm_limit_guarantee',
      prompt: 'A limit buy at 49,000 guarantees what?',
      context: 'Price is currently 50,000.',
      optionA: 'A price no worse than 49,000, if it fills at all',
      optionB: 'That you will get in at 49,000',
      correctIsA: true,
      explanation:
          'A limit order controls price, not certainty. If the market never '
          'trades down to 49,000, or trades through it too fast, you simply '
          'do not get filled. Market orders guarantee a fill; limit orders '
          'guarantee a price. You cannot have both.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_stop_guarantee',
      prompt: 'Does a stop-loss guarantee you exit at your stop price?',
      context: 'Your stop sits at 48,000.',
      optionA: 'Yes, that is what a stop is for',
      optionB: 'No — it becomes a market order when triggered',
      correctIsA: false,
      explanation:
          'A stop is an instruction to get out, not a promise about price. '
          'Once triggered it fills at whatever is available. In a fast drop '
          'that can be well below your stop. This is why position size, not '
          'the stop alone, is what limits the damage.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'm_liquidity',
      prompt: 'Which market is more forgiving of a large order?',
      context: 'You want to buy \$50,000 of something.',
      optionA: 'A deep book with orders stacked at every level',
      optionB: 'A thin book with big gaps between orders',
      correctIsA: true,
      explanation:
          'Depth is how much size the market can absorb before price moves. '
          'In a thin book your own order walks the price up, and you become '
          'the reason your fill was bad.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_last_price',
      prompt: 'What does the "last price" tell you?',
      context: 'It reads 50,000.',
      optionA: 'What you can buy or sell at now',
      optionB: 'One trade happened there, in the past',
      correctIsA: false,
      explanation:
          'Last price is history — a single completed trade. What you can '
          'actually transact at is the bid and the ask, which sit either side '
          'of it and may have moved since.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_maker_taker',
      prompt: 'Which order usually pays the lower fee?',
      context: 'Most exchanges price the two differently.',
      optionA: 'A resting limit order that adds liquidity',
      optionB: 'A market order that takes liquidity',
      correctIsA: true,
      explanation:
          'Exchanges pay for the liquidity that makes them usable, so makers '
          'are charged less than takers — sometimes nothing. If you trade '
          'often, patience is not only better entries, it is a lower fee tier.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'm_gap',
      prompt: 'Price gaps straight through your stop overnight. What happens?',
      context: 'Your stop was at 48,000; the market reopens at 45,000.',
      optionA: 'You exit at 48,000',
      optionB: 'You exit near 45,000',
      correctIsA: false,
      explanation:
          'A stop cannot fill at a price nobody traded. If the market jumps '
          'the level, your exit is on the other side of the gap. Gaps are why '
          '"my risk is capped at 2%" is an assumption, not a fact.',
      lessonId: 'r1',
    ),
    DailyCall(
      id: 'm_orderbook',
      prompt: 'A huge sell order sits on the book just above price. '
          'What can you conclude?',
      context: 'It has been there for ten minutes.',
      optionA: 'Very little — it can be pulled instantly',
      optionB: 'Price will not get through it',
      correctIsA: true,
      explanation:
          'Resting orders are not commitments. They can be cancelled the '
          'moment price approaches, and often are, precisely because they were '
          'placed to be seen. Treat the book as information about intent, not '
          'about outcome.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_24h',
      prompt: 'Crypto trades 24/7. What does that mean for your stops?',
      context: 'You are going to sleep.',
      optionA: 'Nothing happens until you are back',
      optionB: 'They can trigger while you are asleep',
      correctIsA: false,
      explanation:
          'The market does not wait for you. That is an argument for setting '
          'stops rather than against it — an unattended position with no exit '
          'is the one that can do real damage.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'm_volume_meaning',
      prompt: 'Volume measures what?',
      context: 'The bar under the chart.',
      optionA: 'How much was traded in that period',
      optionB: 'How many people want to buy',
      correctIsA: true,
      explanation:
          'Every trade has a buyer and a seller, so volume cannot tell you '
          'which side "won". It tells you how much changed hands — how much '
          'conviction, on both sides, was behind the move.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_short_mechanic',
      prompt: 'When you short, what are you betting on?',
      context: 'You open a short at 50,000.',
      optionA: 'The price going to zero',
      optionB: 'Buying it back cheaper later',
      correctIsA: false,
      explanation:
          'A short sells first and buys back later; the profit is the '
          'difference. You do not need collapse, just a lower price than where '
          'you sold. The asymmetry to respect is that price can rise without '
          'limit, so a short\'s loss has no natural ceiling.',
      lessonId: 'f3',
    ),
    DailyCall(
      id: 'm_slippage_size',
      prompt: 'When is slippage worst?',
      context: 'Same order, different moments.',
      optionA: 'Large order, thin book, fast market',
      optionB: 'Small order, deep book, quiet market',
      correctIsA: true,
      explanation:
          'Slippage is the cost of demanding immediacy when supply is scarce. '
          'It is largest exactly when you most want out — during the news, the '
          'crash, the spike.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'm_partial_fill',
      prompt: 'Your limit order fills only halfway. What is your risk now?',
      context: 'You wanted 1.0 BTC; you got 0.5.',
      optionA: 'Unchanged — the order is still working',
      optionB: 'Half of what you planned',
      correctIsA: false,
      explanation:
          'Risk is on the filled portion only. This matters because people '
          'size their stop for the intended position and forget to recheck '
          'after a partial fill — or worse, assume they are out when half the '
          'exit is still resting.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'm_weekend',
      prompt: 'Liquidity in crypto on a weekend is usually:',
      context: 'Saturday, 3am.',
      optionA: 'Thinner, so moves are exaggerated',
      optionB: 'The same as any weekday',
      correctIsA: true,
      explanation:
          'Fewer participants means less depth, so the same order moves price '
          'further. Weekend moves often look dramatic and then unwind when '
          'real volume returns.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_ticker_vs_chart',
      prompt: 'The chart shows a green candle. Does that mean buyers '
          'outnumbered sellers?',
      context: 'A standard candlestick.',
      optionA: 'Yes, more buyers than sellers',
      optionB: 'No — it means it closed above where it opened',
      correctIsA: false,
      explanation:
          'Buyers and sellers are always equal in number of coins traded — '
          'every trade is both. A green candle says price ended higher than it '
          'started, which is about urgency, not headcount.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_timeframe',
      prompt: 'The 5-minute chart says down, the daily says up. '
          'Which is wrong?',
      context: 'Both are the same market.',
      optionA: 'Neither — they answer different questions',
      optionB: 'The 5-minute, always',
      correctIsA: true,
      explanation:
          'Timeframes are not competing forecasts, they are different zoom '
          'levels. The mistake is not picking the "wrong" one, it is entering '
          'on one and then managing on another — taking a five-minute entry '
          'and holding it with daily-chart patience.',
      lessonId: 't3',
    ),
    DailyCall(
      id: 'm_limit_above',
      prompt: 'You place a limit BUY above the current price. What happens?',
      context: 'Price is 50,000; your limit buy is at 51,000.',
      optionA: 'It waits until price reaches 51,000',
      optionB: 'It fills immediately, near 50,000',
      correctIsA: false,
      explanation:
          'A limit order means "this price or better". A buy limit above the '
          'market is instantly satisfiable, so it executes at once. People '
          'make this mistake when they mean to set a stop entry and reach for '
          'the wrong order type.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_funding',
      prompt: 'On a perpetual future, the funding rate is positive and you '
          'are long. What does that mean for you?',
      context: 'Funding pays out every few hours.',
      optionA: 'You pay, periodically, just for holding',
      optionB: 'You receive a payment',
      correctIsA: true,
      explanation:
          'Positive funding means longs pay shorts, to tether the perpetual to '
          'spot. Holding a crowded long through a high-funding stretch bleeds '
          'money even in a flat market — a cost that never shows on the chart.',
      lessonId: 't5',
    ),
    DailyCall(
      id: 'm_open_interest',
      prompt: 'Open interest rises sharply while price barely moves. '
          'What does that suggest?',
      context: 'A futures market.',
      optionA: 'Price is about to rise',
      optionB: 'New positions are being built on both sides',
      correctIsA: false,
      explanation:
          'Open interest counts contracts outstanding, not direction. Rising '
          'OI in a flat market means both sides are adding — a build-up of '
          'disagreement, which often resolves violently but tells you nothing '
          'about which way.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_exchange_price_diff',
      prompt: 'Two exchanges show slightly different prices for the same '
          'coin. Is one broken?',
      context: 'A 0.1% difference.',
      optionA: 'No — separate order books drift apart',
      optionB: 'Yes, one has stale data',
      correctIsA: true,
      explanation:
          'Each exchange is its own market with its own buyers and sellers. '
          'Small differences are normal and are what arbitrage exists to '
          'close. It matters practically: your fill comes from the book you '
          'are trading on, not the price you saw elsewhere.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_market_close',
      prompt: 'Why do stock markets gap at the open and crypto rarely does?',
      context: 'Comparing the two.',
      optionA: 'Crypto is less volatile',
      optionB: 'Stocks stop trading while news keeps arriving',
      correctIsA: false,
      explanation:
          'A gap is accumulated news with nowhere to go. Continuous markets '
          'price information as it lands, so the move happens in ticks rather '
          'than a jump. It is not that crypto is calmer — it is that it never '
          'closes.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_ohlc',
      prompt: 'A candle\'s wick tells you what?',
      context: 'Long upper wick, small body.',
      optionA: 'Price went there and did not stay',
      optionB: 'Price is heading that way',
      correctIsA: true,
      explanation:
          'A wick is rejected territory — trades happened up there and the '
          'close came back. It is evidence about what already failed, not a '
          'forecast. Reading it as direction is how a rejection gets traded as '
          'a breakout.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_round_numbers',
      prompt: 'Why do round numbers like 50,000 often see reactions?',
      context: 'Price stalls exactly there.',
      optionA: 'Because the number itself has meaning',
      optionB: 'Because that is where people cluster their orders',
      correctIsA: false,
      explanation:
          'Nothing about 50,000 is special to the market. It is special to '
          'people, who set targets and stops at memorable numbers — so the '
          'orders really are there. The level is real because the behaviour '
          'is, not the other way round.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_stop_hunt',
      prompt: 'Price dips just below an obvious support, then rips back up. '
          'What likely happened?',
      context: 'A common pattern.',
      optionA: 'Clustered stops got triggered and supplied the move',
      optionB: 'Someone is personally targeting you',
      correctIsA: true,
      explanation:
          'Stops below an obvious level are a pool of guaranteed market sells. '
          'Reaching them creates liquidity for anyone wanting to buy size. It '
          'is not personal — it is structural, and it is an argument for not '
          'putting your stop where everyone else puts theirs.',
      lessonId: 't2',
    ),
    DailyCall(
      id: 'm_order_types_count',
      prompt: 'You want to enter only if price breaks above resistance. '
          'Which tool?',
      context: 'Resistance at 52,000; price at 50,000.',
      optionA: 'A limit buy at 52,000',
      optionB: 'A stop (or stop-limit) buy above 52,000',
      correctIsA: false,
      explanation:
          'A limit buy at 52,000 would fill immediately if price rose to it, '
          'but it is designed to buy *below*. To buy strength you want an '
          'order that activates on the way up — a buy stop. Same price, '
          'opposite intent.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_avg_down',
      prompt: 'Adding to a losing position lowers your average entry. '
          'Does it lower your risk?',
      context: 'You are down and you buy more.',
      optionA: 'No — it increases the money at stake',
      optionB: 'Yes, your break-even is closer',
      correctIsA: true,
      explanation:
          'A nearer break-even feels like progress, but you now hold more of '
          'something that has been going against you. The comforting number '
          'moved; the exposure went up. This is the single most common way a '
          'small loss becomes an account-ending one.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'm_illiquid_exit',
      prompt: 'You hold a large position in a thin altcoin and want out fast. '
          'What is the realistic problem?',
      context: 'Daily volume is small relative to your size.',
      optionA: 'The exchange will refuse the order',
      optionB: 'Your exit moves the price against you',
      correctIsA: false,
      explanation:
          'In a thin market you are not a price-taker, you are the event. '
          'Getting out costs you a worse average the larger you are — which is '
          'why position size should be judged against the market\'s depth, not '
          'just your account.',
      lessonId: 'r2',
    ),
    DailyCall(
      id: 'm_price_discovery',
      prompt: 'Price is at an all-time high. What does the chart tell you '
          'about what happens next?',
      context: 'No historical levels above.',
      optionA: 'Less than usual — there is no history up there',
      optionB: 'It must come back down',
      correctIsA: true,
      explanation:
          'Every level above is unvisited, so support-and-resistance reasoning '
          'has nothing to work with. "It is too high" is not analysis; markets '
          'in discovery can keep going. Less information should mean smaller '
          'size, not a confident fade.',
      lessonId: 'p4',
    ),
    DailyCall(
      id: 'm_two_way',
      prompt: 'For every coin someone panic-sells, what is true?',
      context: 'A sharp sell-off.',
      optionA: 'It vanished from the market',
      optionB: 'Someone bought it',
      correctIsA: false,
      explanation:
          '"Everyone is selling" is never literally true — every sale needs a '
          'buyer. What changes in a sell-off is the price both sides agree on, '
          'not the existence of the other side. This reframing kills a lot of '
          'panicked reasoning.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_news_priced',
      prompt: 'Good news comes out and the price falls. How is that possible?',
      context: 'The news is genuinely positive.',
      optionA: 'The market already expected it',
      optionB: 'The market is irrational',
      correctIsA: true,
      explanation:
          'Price moves on the difference between what happens and what was '
          'expected. Good news that was widely anticipated is already in the '
          'price, and the people who bought the rumour now sell the fact. '
          'Trading headlines without asking what was priced in is how you end '
          'up right on the news and wrong on the trade.',
      lessonId: 'f2',
    ),
    DailyCall(
      id: 'm_leverage_liq',
      prompt: 'At 20x leverage, roughly how far can price move against you '
          'before liquidation?',
      context: 'Ignoring fees and maintenance margin.',
      optionA: 'About 20%',
      optionB: 'About 5%',
      correctIsA: false,
      explanation:
          'Your margin is 1/20th of the position, so a 5% adverse move wipes '
          'it out. Ordinary daily noise in crypto is several percent — at 20x, '
          'being right about direction and early about timing is '
          'indistinguishable from being wrong.',
      lessonId: 'r4',
    ),
    DailyCall(
      id: 'm_fill_or_kill',
      prompt: 'Your order sat unfilled all day and you cancelled it. '
          'What did it cost you?',
      context: 'Price never reached your limit.',
      optionA: 'Nothing in fees — but possibly a trade you wanted',
      optionB: 'A cancellation fee on most exchanges',
      correctIsA: true,
      explanation:
          'Unfilled orders are free to place and cancel. The real cost is '
          'opportunity: waiting for a perfect price that never comes is still '
          'a decision, and it is the one that never appears in your P&L.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_depth_vs_volume',
      prompt: 'High daily volume but a thin order book right now. '
          'Can both be true?',
      context: 'You are about to send a large order.',
      optionA: 'No, they measure the same thing',
      optionB: 'Yes — volume is history, depth is this moment',
      correctIsA: false,
      explanation:
          'Volume is what traded over a period; depth is what is resting on '
          'the book now. A market can be busy on average and empty at 4am. The '
          'one that determines your fill is depth.',
      lessonId: 't1',
    ),
    DailyCall(
      id: 'm_paper_vs_real',
      prompt: 'What does a simulator like this one struggle to reproduce?',
      context: 'Being honest about the tool.',
      optionA: 'How it feels to have real money at risk',
      optionB: 'The arithmetic of profit and loss',
      correctIsA: true,
      explanation:
          'The maths is easy to model; the fear is not. Paper trading builds '
          'process and mechanics, and it cannot build the discipline to follow '
          'them when the loss is real. Treat a good simulated record as '
          'necessary, not sufficient.',
      lessonId: 'p1',
    ),
  ];
}
