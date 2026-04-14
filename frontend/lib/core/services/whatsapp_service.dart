import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';

/// WhatsApp Deep Link utility — replaces manual contact buttons per pedoman v1.12.
/// Templates loaded from database via /wa/templates endpoint (no hardcode).
class WhatsAppService {
  static final ApiClient _api = ApiClient();
  static Map<String, String> _templates = {};
  static bool _loaded = false;

  /// Load WA templates from database. Call once on app init or lazily.
  static Future<void> loadTemplates() async {
    if (_loaded) return;
    try {
      final res = await _api.dio.get('/wa/templates');
      if (res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        _templates = {
          for (final t in list)
            (t['slug'] as String? ?? ''): (t['body'] as String? ?? ''),
        };
        _loaded = true;
      }
    } catch (_) {
      // Fallback to defaults if API unavailable
    }
  }

  /// Get template body by slug, with variable substitution.
  /// Variables in template use {key} format, e.g. "Halo, terkait order {order_number}..."
  static String _resolveTemplate(String slug, Map<String, String> vars, String fallback) {
    var body = _templates[slug] ?? fallback;
    vars.forEach((key, value) {
      body = body.replaceAll('{$key}', value);
    });
    return body;
  }

  /// Open WhatsApp chat with a phone number.
  static Future<void> openChat({
    required String phone,
    String? message,
  }) async {
    String normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    } else if (!normalized.startsWith('62')) {
      normalized = '62$normalized';
    }

    final uri = Uri.parse(
      'https://wa.me/$normalized${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open WhatsApp with order-related message template from DB.
  static Future<void> contactForOrder({
    required String phone,
    required String orderNumber,
    String? role,
  }) async {
    await loadTemplates();
    final fallback = 'Halo, saya dari Santa Maria terkait order $orderNumber.'
        '${role != null ? ' ($role)' : ''}'
        ' Mohon konfirmasinya. Terima kasih.';
    final message = _resolveTemplate('order_contact', {
      'order_number': orderNumber,
      'role': role ?? 'Tim',
    }, fallback);

    await openChat(phone: phone, message: message);
  }

  /// Open WhatsApp for supplier coordination.
  static Future<void> contactSupplier({
    required String phone,
    required String procurementNumber,
  }) async {
    await loadTemplates();
    final fallback = 'Halo, terkait pengadaan $procurementNumber dari Santa Maria. '
        'Mohon info pengiriman barang. Terima kasih.';
    final message = _resolveTemplate('supplier_contact', {
      'procurement_number': procurementNumber,
    }, fallback);

    await openChat(phone: phone, message: message);
  }
}
