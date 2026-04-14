import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'glass_widget.dart';

class ChangePasswordDialog extends StatefulWidget {
  final ApiClient apiClient;
  final bool isPin;

  const ChangePasswordDialog({
    super.key,
    required this.apiClient,
    this.isPin = false,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final label = widget.isPin ? 'PIN' : 'Password';
    final accentColor = widget.isPin ? AppColors.roleConsumer : AppColors.brandPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassWidget(
        borderRadius: 24,
        blurSigma: 20,
        tint: AppColors.surfaceWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ganti $label',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan perbarui $label default Anda untuk keamanan.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: AppColors.statusDanger, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _currentController,
              obscureText: true,
              keyboardType: widget.isPin ? TextInputType.number : TextInputType.text,
              maxLength: widget.isPin ? 6 : null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: '$label Saat Ini',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newController,
              obscureText: true,
              keyboardType: widget.isPin ? TextInputType.number : TextInputType.text,
              maxLength: widget.isPin ? 6 : null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: '$label Baru',
                prefixIcon: const Icon(Icons.password_rounded, size: 20),
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: widget.isPin ? TextInputType.number : TextInputType.text,
              maxLength: widget.isPin ? 6 : null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Konfirmasi $label Baru',
                prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                counterText: "",
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('PERBARUI $label'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_currentController.text.isEmpty || _newController.text.isEmpty) {
      setState(() => _error = 'Semua field harus diisi.');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'Konfirmasi $label tidak cocok.');
      return;
    }
    if (widget.isPin && (_newController.text.length < 4 || _newController.text.length > 6)) {
      setState(() => _error = 'PIN harus berjumlah 4 sampai 6 digit.');
      return;
    }
    if (!widget.isPin && _newController.text.length < 8) {
      setState(() => _error = 'Password minimal 8 karakter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.apiClient.dio.put(
        '/auth/update-password',
        data: {
          'current_password': _currentController.text,
          'new_password': _newController.text,
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.isPin ? 'PIN' : 'Password'} berhasil diperbarui.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memperbarui. Pastikan ${widget.isPin ? 'PIN' : 'Password'} lama benar.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get label => widget.isPin ? 'PIN' : 'Password';
}
