/// App-wide constant values. Never hardcode these inline.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Jeb';
  static const String defaultCurrencyCode = 'EUR';
  static const int recentTransactionsLimit = 100;

  /// iCloud container id — must match the container enabled in Xcode
  /// (Signing & Capabilities → iCloud → CloudKit/iCloud Documents).
  static const String iCloudContainerId = 'iCloud.com.woltrap.jeb';

}
