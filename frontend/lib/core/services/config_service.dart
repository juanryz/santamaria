import '../../core/network/api_client.dart';

/// Dynamic config service — fetches all enums, thresholds, settings from backend.
/// ZERO hardcoded status labels or business params in frontend.
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();
  ConfigService._();

  final ApiClient _api = ApiClient();

  Map<String, dynamic> _thresholds = {};
  Map<String, dynamic> _settings = {};
  Map<String, List<Map<String, dynamic>>> _enums = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Map<String, dynamic> get thresholds => _thresholds;
  Map<String, dynamic> get settings => _settings;

  /// Call once on app startup (after login or on splash).
  Future<void> load() async {
    try {
      final res = await _api.dio.get('/config');
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        _thresholds = Map<String, dynamic>.from(data['thresholds'] ?? {});
        _settings = Map<String, dynamic>.from(data['settings'] ?? {});

        final enumsRaw = data['enums'] as Map<String, dynamic>? ?? {};
        _enums = {};
        enumsRaw.forEach((key, value) {
          _enums[key] = List<Map<String, dynamic>>.from(
            (value as List).map((e) => Map<String, dynamic>.from(e)),
          );
        });

        _loaded = true;
      }
    } catch (_) {
      // Config is optional — app still works with fallback labels
    }
  }

  /// Get threshold value by key.
  double getThreshold(String key, {double defaultValue = 0}) {
    final val = _thresholds[key];
    if (val == null) return defaultValue;
    return double.tryParse(val.toString()) ?? defaultValue;
  }

  /// Get setting value by key.
  String getSetting(String key, {String defaultValue = ''}) {
    return _settings[key]?.toString() ?? defaultValue;
  }

  /// Get label for a status value from a specific enum group.
  /// Example: getLabel('order_status', 'confirmed') → 'Dikonfirmasi'
  String getLabel(String enumGroup, String value, {String? fallback}) {
    final items = _enums[enumGroup];
    if (items == null) return fallback ?? value;

    final match = items.where((e) => e['value'] == value);
    if (match.isEmpty) return fallback ?? value;

    return match.first['label'] ?? fallback ?? value;
  }

  /// Get color for an attendance status.
  String? getAttendanceColor(String value) {
    final items = _enums['attendance_status'];
    if (items == null) return null;

    final match = items.where((e) => e['value'] == value);
    if (match.isEmpty) return null;

    return match.first['color'];
  }

  /// Get all enum items for a group (for building dropdown/filter chips).
  List<Map<String, dynamic>> getEnumItems(String enumGroup) {
    return _enums[enumGroup] ?? [];
  }

  /// Get violation severity from config (not hardcoded).
  String getViolationSeverity(String violationType) {
    final items = _enums['violation_type'];
    if (items == null) return 'medium';

    final match = items.where((e) => e['value'] == violationType);
    if (match.isEmpty) return 'medium';

    return match.first['severity'] ?? 'medium';
  }
}
