import 'package:intl/intl.dart';

/// How numbers are written, everywhere.
///
/// Inconsistent number formatting is the fastest way for an app to lose a
/// trader's confidence, and it is invisible to the person writing the code.
/// `$50000.00` on one screen and `$50,000.00` on the next reads as two teams
/// who never spoke. Thousands separators in particular are not decoration:
/// without them nobody can tell 1000000 from 100000 at a glance, which is the
/// entire job of a number in a trading UI.
///
/// This absorbs the logic that already lived in the market ticker — which was
/// correct, just not available to the rest of the app — so there is one
/// implementation rather than two that drift.
///
/// Pair these with [VxTypography], whose styles carry tabular figures, so the
/// digits also line up column to column.
class VxFormat {
  VxFormat._();

  static final NumberFormat _grouped = NumberFormat('#,##0.00');
  static final NumberFormat _groupedWhole = NumberFormat('#,##0');
  static final NumberFormat _mid = NumberFormat('0.000');
  static final NumberFormat _small = NumberFormat('0.00000');

  /// A price, with precision matched to its magnitude, the way terminals do
  /// it: 68,895.00 / 3.142 / 0.12345.
  ///
  /// A fixed two decimals would render a cheap altcoin as "0.00", and five
  /// decimals would render Bitcoin as noise. Magnitude-aware precision is
  /// what makes one column readable across both.
  static String price(double value) {
    final abs = value.abs();
    if (abs >= 100) return _grouped.format(value);
    if (abs >= 1) return _mid.format(value);
    return _small.format(value);
  }

  /// A cash amount with a currency symbol: `$1,240.00`.
  static String money(double value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${_grouped.format(value.abs())}';
  }

  /// A profit or loss, with an explicit sign: `+$1,240.00`, `-$340.00`.
  ///
  /// The leading `+` is not redundant. In a column of results the eye needs
  /// to sort winners from losers without reading the digits, and colour alone
  /// cannot do that job for the roughly one in twelve men with a red-green
  /// deficiency. Every trading platform shows the sign for this reason.
  static String signedMoney(double value) {
    final sign = value < 0 ? '-' : '+';
    return '$sign\$${_grouped.format(value.abs())}';
  }

  /// A percentage with an explicit sign: `+2.45%`.
  static String signedPercent(double value, {int decimals = 2}) {
    final sign = value < 0 ? '-' : '+';
    return '$sign${value.abs().toStringAsFixed(decimals)}%';
  }

  /// Large values shortened: `$1.2B`, `$845M`, `$12K`.
  ///
  /// Used for volume and market cap, where the exact figure is noise and the
  /// order of magnitude is the information.
  static String compactMoney(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1e9) return '$sign\$${(abs / 1e9).toStringAsFixed(1)}B';
    if (abs >= 1e6) return '$sign\$${(abs / 1e6).toStringAsFixed(0)}M';
    if (abs >= 1e3) return '$sign\$${(abs / 1e3).toStringAsFixed(0)}K';
    return '$sign\$${_groupedWhole.format(abs)}';
  }

  /// A plain count with separators: `1,284`.
  static String count(num value) => _groupedWhole.format(value);

  /// A duration stated the way a person would say it.
  static String duration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '$minutes min';
    if (minutes < 60 * 24) return '${(minutes / 60).toStringAsFixed(1)} hours';
    return '${(minutes / (60 * 24)).toStringAsFixed(1)} days';
  }
}
