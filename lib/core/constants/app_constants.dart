/// App-wide constant values. Never hardcode these inline.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Jeb';

  /// Shown in Settings → About. Bump alongside the pubspec `version`.
  static const String appVersion = '1.0.0';

  static const String defaultCurrencyCode = 'EUR';
  static const int recentTransactionsLimit = 100;

  /// iCloud container id — must match the container enabled in Xcode
  /// (Signing & Capabilities → iCloud → CloudKit/iCloud Documents).
  static const String iCloudContainerId = 'iCloud.com.woltrap.jeb';

  // External links (Settings → About & Support).
  static const String sponsorsUrl = 'https://github.com/sponsors/iammujtaba44';
  static const String buyMeCoffeeUrl = 'https://buymeacoffee.com/immujtaba9h';
  static const String portfolioUrl = 'https://www.mujtaba.cc';
}
