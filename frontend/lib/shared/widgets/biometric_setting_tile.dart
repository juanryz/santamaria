import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import 'glass_widget.dart';

/// Reusable tile for enabling/disabling biometric auth in any settings screen.
class BiometricSettingTile extends StatefulWidget {
  final String? authToken;
  const BiometricSettingTile({super.key, this.authToken});

  @override
  State<BiometricSettingTile> createState() => _BiometricSettingTileState();
}

class _BiometricSettingTileState extends State<BiometricSettingTile> {
  final _bio = BiometricService.instance;

  @override
  Widget build(BuildContext context) {
    if (!_bio.isAvailable) return const SizedBox.shrink();

    return GlassWidget(
      borderRadius: 14,
      child: SwitchListTile(
        secondary: Icon(
          _bio.biometricIcon == 'face_id' ? Icons.face : Icons.fingerprint,
          color: AppColors.brandPrimary,
        ),
        title: Text(_bio.biometricLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _bio.isEnabled ? 'Aktif — login cepat tanpa password' : 'Nonaktif',
          style: const TextStyle(fontSize: 12),
        ),
        value: _bio.isEnabled,
        activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.5),
        activeThumbColor: AppColors.brandPrimary,
        onChanged: (value) async {
          if (value) {
            final success = await _bio.authenticate(reason: 'Aktifkan ${_bio.biometricLabel}');
            if (success) {
              await _bio.enable(widget.authToken ?? '');
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_bio.biometricLabel} diaktifkan')),
                );
              }
            }
          } else {
            await _bio.disable();
            setState(() {});
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
