/// App-wide constants.
///
/// This file used to hold a dozen more, none of them referenced anywhere, and
/// most of them disagreeing with the values the app actually uses:
///
/// - `appVersion = '1.2.2'` while pubspec.yaml said something else. A second
///   place to read the version is a place to read the wrong one.
/// - `proMonthlyId = 'explorer_premium_monthly'` and
///   `premiumMonthlyId = 'pro_mode_monthly'` — a whole second set of billing
///   product ids. The real ones live on [SubscriptionProduct] and are
///   `premium_monthly` / `premium_yearly` on Google Play. Anyone configuring
///   the Play Console from this file would have created the wrong SKUs and
///   then debugged a purchase flow that could never find them.
/// - `freeDailySignalLimit = 5` against a real limit of 10, and
///   `premiumStrategyLimit = 999` against a real 999999.
///
/// Unused constants that contradict the live values are worse than no
/// constants: they read as the source of truth. Anything genuinely shared
/// belongs here; anything one feature owns belongs with that feature.
class AppConstants {
  static const String appName = 'Volex Terminal';

  /// Contact address in the privacy policy, the Terms screen and the Play
  /// listing. Deletion requests arrive here, so it has to be a monitored
  /// inbox, not a forwarding alias that bounces.
  static const String supportEmail = 'dailyvolex@gmail.com';

  /// Where a shared Daily result should send a reader.
  ///
  /// Empty until the app is actually listed. A share loop is the only
  /// zero-budget growth mechanic this app has, and it only works if the link
  /// resolves — a URL that 404s makes a share worse than no share, because
  /// the reader's one moment of curiosity is spent on an error page.
  ///
  /// Set this to the Play listing URL the day the app goes live
  /// (https://play.google.com/store/apps/details?id=com.antigravity.volextrade)
  /// and every share starts converting. Until then the share text simply
  /// omits the line.
  static const String playListingUrl = '';

  // The hosted policy URLs and the paper starting balance were here too. Both
  // were copies: the URLs are declared in AndroidManifest.xml, which is what
  // Play actually reads, and the balance is ExecutionManager's own default.
  // A second copy that nothing reads is a value waiting to disagree with the
  // one that matters, so each now lives in exactly one place.
}
