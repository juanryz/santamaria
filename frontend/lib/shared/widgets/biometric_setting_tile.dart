import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import 'glass_widget.dart';

/// Reusable tile for enabling/disabling biometric auth in any settings screen.
///
/// Token auth diambil otomatis dari FlutterSecureStorage (auth_token yang
/// disimpan saat login manual). User tidak perlu login ulang untuk aktifkan.
class BiometricSettingTile extends StatefulWidget {
  const BiometricSettingTile({super.key});

  @override
  State<BiometricSettingTile> createState() => _BiometricSettingTileState();
}

class _BiometricSettingTileState extends State<BiometricSettingTile> {
  final _bio = BiometricService.instance;
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    if (!_bio.isAvailable) {
      // Device tidak support biometric — tampilkan info ke user
      return GlassWidget(
        borderRadius: 14,
        child: ListTile(
          leading: Icon(
            Icons.fingerprint,
            color: AppColors.textHint,
          ),
          title: const Text(
            'Face ID / Fingerprint',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHint),
          ),
          subtitle: const Text(
            'Tidak tersedia di perangkat ini',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
      );
    }

    return GlassWidget(
      borderRadius: 14,
      child: SwitchListTile(
        secondary: Icon(
          _bio.biometricIcon == 'face_id' ? Icons.face : Icons.fingerprint,
          color: AppColors.brandPrimary,
          size: 28,
        ),
        title: Text(
          _bio.biometricLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          _bio.isEnabled
              ? 'Aktif — login cepat tanpa password'
              : 'Nonaktif — aktifkan untuk login dengan ${_bio.biometricLabel}',
          style: const TextStyle(fontSize: 12),
        ),
        value: _bio.isEnabled,
        activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.5),
        activeThumbColor: AppColors.brandPrimary,
        onChanged: (value) async {
          if (value) {
            // Ambil token dari secure storage (dari login manual sebelumnya)
            final token = await _storage.read(key: 'auth_token');
            if (token == null || token.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Session tidak valid. Silakan login ulang sebelum mengaktifkan.'),
                  ),
                );
              }
              return;
            }

            // Minta user verify biometric dulu sebelum enable
            final success = await _bio.authenticate(
              reason:
                  'Aktifkan ${_bio.biometricLabel} untuk login cepat',
            );
            if (success) {
              await _bio.enable(token);
              if (mounted) setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_bio.biometricLabel} aktif'),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Verifikasi ${_bio.biometricLabel} gagal atau dibatalkan'),
                  ),
                );
              }
            }
          } else {
            await _bio.disable();
            if (mounted) setState(() {});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_bio.biometricLabel} dinonaktifkan')),
              );
            }
          }
        },
      ),
    );
  }
}
