import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/engine/execution/i_execution_service.dart';
import 'package:volex_terminal/engine/parameters/parameter_models.dart';
import 'package:volex_terminal/engine/strategy/strategy_base.dart';
import 'package:volex_terminal/engine/strategy/strategy_recommendation.dart';

/// A strategy whose rules are not present in this build.
///
/// Publishing a strategy records its name, description and parameters, but
/// there is no mechanism for shipping the rules themselves — that would mean
/// downloading and running someone else's code. The registry used to paper
/// over the gap by handing back a BollingerRSIStrategy for *any* published
/// entry, so running a published strategy silently executed Bollinger+RSI
/// while the screen showed the published one's name, and any trades or
/// backtest results were attributed to a strategy that never ran.
///
/// Substituting different logic is worse than having none. This takes no
/// trades and says why, so the failure is visible the first time rather than
/// hidden inside plausible-looking results.
class UnavailableStrategy extends Strategy {
  @override
  final String id;

  @override
  final String name;

  UnavailableStrategy({required this.id, required this.name});

  @override
  String get description =>
      'The rules for this strategy are not available in this build, so it '
      'cannot be run. Publishing records a strategy\'s description and '
      'settings, not its code.';

  @override
  List<StrategyParameterSchema> get parameters => const [];

  @override
  Map<String, dynamic> get currentParameterValues => const {};

  @override
  ValidationStatus get validationStatus => ValidationStatus.experimental;

  @override
  String get validationMessage =>
      'Not runnable — this build does not contain this strategy\'s rules.';

  @override
  Strategy cloneWith(Map<String, dynamic> newValues) =>
      UnavailableStrategy(id: id, name: name);

  @override
  Future<void> onTick(
    Candle candle,
    IExecutionService execution,
    ChartController controller,
  ) async {
    // Deliberately does nothing. Logging on every tick would bury the app in
    // noise; the message on activation is the one that matters.
  }

  @override
  Future<List<StrategyRecommendation>> analyze(
    String symbol,
    List<Candle> history,
  ) async =>
      const [];
}
