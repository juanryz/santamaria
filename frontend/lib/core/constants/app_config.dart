class AppConfig {
  AppConfig._();

  /// Base URL for API. Override at build time:
  /// flutter run --dart-define=BASE_URL=https://your-server.com/api/v1
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Pusher app key. Override at build time:
  /// flutter run --dart-define=PUSHER_KEY=your_key
  static const pusherKey = String.fromEnvironment(
    'PUSHER_KEY',
    defaultValue: '',
  );

  /// Pusher cluster. Override at build time:
  /// flutter run --dart-define=PUSHER_CLUSTER=ap1
  static const pusherCluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'ap1',
  );

  /// Polling interval for supplier order checks (in seconds).
  static const supplierPollIntervalSeconds = 30;
}
