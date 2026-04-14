
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/role_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../consumer/screens/consumer_home.dart';
import '../../driver/screens/driver_dashboard_screen.dart';
import '../../finance/screens/finance_dashboard_screen.dart';
import '../../gudang/screens/gudang_dashboard_screen.dart';
import '../../owner/screens/owner_dashboard_screen.dart';
import '../../so/screens/so_dashboard_screen.dart';
import '../../super_admin/screens/super_admin_dashboard_screen.dart';
import '../../purchasing/screens/purchasing_dashboard_screen.dart';
import '../../hrd/screens/hrd_dashboard_screen.dart';
import '../../tukang_foto/screens/tukang_foto_dashboard_screen.dart';
import '../../tukang_angkat_peti/screens/tukang_angkat_peti_dashboard_screen.dart';
import '../../viewer/screens/viewer_dashboard_screen.dart';
import '../../vendor/screens/supplier_dashboard_screen.dart';
import '../../vendor_assignment/screens/vendor_assignment_screen.dart';
import '../../dekor/screens/dekor_dashboard_screen.dart';
import '../../../core/services/biometric_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  int _mode = 0; // 0 = Konsumen, 1 = Personel

  // Konsumen
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  // Konsumen register
  bool _isRegister = false;
  final _nameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscureRegPin = true;
  bool _obscureConfirm = true;

  // Personel
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _regPhoneController.dispose();
    _regPinController.dispose();
    _confirmPinController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginConsumer() async {
    if (_phoneController.text.trim().isEmpty || _pinController.text.trim().isEmpty) {
      _snack('Lengkapi nomor HP dan PIN.');
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      await auth.loginConsumer(_phoneController.text.trim(), _pinController.text.trim());
      if (!mounted) return;
      _navigateTo(const ConsumerHome());
    } catch (e) {
      if (mounted) _snack(e.toString().contains('401') ? 'Nomor HP atau PIN salah.' : 'Gagal login: $e');
    }
  }

  Future<void> _registerConsumer() async {
    final name = _nameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final pin = _regPinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    if (name.isEmpty || phone.isEmpty || pin.isEmpty) {
      _snack('Lengkapi semua field.');
      return;
    }
    if (pin.length < 4) { _snack('PIN minimal 4 digit.'); return; }
    if (pin != confirm) { _snack('Konfirmasi PIN tidak cocok.'); return; }
    final auth = context.read<AuthProvider>();
    try {
      await auth.registerConsumer(name, phone, pin);
      if (!mounted) return;
      _navigateTo(const ConsumerHome());
    } catch (e) {
      if (mounted) _snack('Registrasi gagal: $e');
    }
  }

  Future<void> _loginInternal() async {
    if (_identifierController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _snack('Lengkapi email/HP dan kata sandi.');
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      await auth.loginInternal(_identifierController.text.trim(), _passwordController.text);
      if (!mounted) return;
      _routeByRole(auth.user?['role']);
    } catch (e) {
      if (mounted) {
        String msg = 'Login gagal. Periksa kembali kredensial Anda.';
        if (e.toString().contains('401')) {
          msg = 'Kredensial (Email/Password) salah.';
        } else if (e.toString().contains('403')) {
          msg = 'Akun tidak aktif atau belum diverifikasi.';
        }
        _snack('$msg ($e)');
      }
    }
  }

  Future<void> _biometricLogin() async {
    final bio = BiometricService.instance;
    final success = await bio.authenticate(reason: 'Login ke Santa Maria');
    if (!success) {
      _snack('Autentikasi biometrik gagal');
      return;
    }
    final token = await bio.getStoredToken();
    if (token == null || token.isEmpty) {
      _snack('Sesi biometrik kadaluarsa. Silakan login manual.');
      return;
    }
    // Re-authenticate with stored token
    try {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.restoreSession(token);
      if (!mounted) return;
      final role = auth.user?['role'];
      // Re-use the same role routing logic
      _routeByRole(role);
    } catch (e) {
      _snack('Sesi kadaluarsa. Silakan login manual.');
      await bio.disable();
    }
  }

  void _routeByRole(String? role) {
    switch (role) {
      case RoleConstants.superAdmin:
        _navigateTo(const SuperAdminDashboardScreen());
      case RoleConstants.admin:
        _navigateTo(const AdminDashboardScreen());
      case RoleConstants.owner:
        _navigateTo(const OwnerDashboardScreen());
      case RoleConstants.serviceOfficer:
        _navigateTo(const SODashboardScreen());
      case RoleConstants.gudang:
        _navigateTo(const GudangDashboardScreen());
      case RoleConstants.finance:
        _navigateTo(const FinanceDashboardScreen());
      case RoleConstants.driver:
        _navigateTo(const DriverDashboardScreen());
      case RoleConstants.supplier:
        _navigateTo(const SupplierDashboardScreen());
      case RoleConstants.purchasing:
        _navigateTo(const PurchasingDashboardScreen());
      case RoleConstants.hrd:
        _navigateTo(const HrdDashboardScreen());
      case RoleConstants.tukangFoto:
        _navigateTo(const TukangFotoDashboardScreen());
      case RoleConstants.tukangAngkatPeti:
        _navigateTo(const TukangAngkatPetiDashboardScreen());
      case RoleConstants.viewer:
        _navigateTo(const ViewerDashboardScreen());
      case RoleConstants.dekor:
        _navigateTo(const DekorDashboardScreen());
      case RoleConstants.konsumsi || RoleConstants.pemukaAgama:
        _navigateTo(const VendorAssignmentScreen());
      default:
        _snack('Selamat datang.');
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        labelText: label,
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  Widget _consumerContent() {
    if (_isRegister) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(controller: _nameController, label: 'Nama Lengkap', icon: Icons.person_outline),
          const SizedBox(height: 14),
          _field(controller: _regPhoneController, label: 'Nomor HP', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _field(controller: _regPinController, label: 'PIN (min 4 digit)', icon: Icons.lock_outline, keyboardType: TextInputType.number, obscure: _obscureRegPin, onToggle: () => setState(() => _obscureRegPin = !_obscureRegPin)),
          const SizedBox(height: 14),
          _field(controller: _confirmPinController, label: 'Konfirmasi PIN', icon: Icons.lock_reset_outlined, keyboardType: TextInputType.number, obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (_, auth, _) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleConsumer),
              onPressed: auth.isLoading ? null : _registerConsumer,
              child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('DAFTAR'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegister = false),
              child: const Text('Sudah punya akun? Masuk', style: TextStyle(color: AppColors.roleConsumer, fontSize: 13)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(controller: _phoneController, label: 'Nomor HP', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _field(controller: _pinController, label: 'PIN', icon: Icons.lock_outline, keyboardType: TextInputType.number, obscure: _obscurePin, onToggle: () => setState(() => _obscurePin = !_obscurePin)),
        const SizedBox(height: 24),
        Consumer<AuthProvider>(
          builder: (_, auth, _) => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleConsumer),
            onPressed: auth.isLoading ? null : _loginConsumer,
            child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('MASUK'),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isRegister = true),
            child: const Text('Belum punya akun? Daftar', style: TextStyle(color: AppColors.roleConsumer, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _personnelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(controller: _identifierController, label: 'Email atau Nomor HP', icon: Icons.person_outline),
        const SizedBox(height: 14),
        _field(controller: _passwordController, label: 'Kata Sandi', icon: Icons.lock_outline, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
        const SizedBox(height: 24),
        Consumer<AuthProvider>(
          builder: (_, auth, _) => ElevatedButton(
            onPressed: auth.isLoading ? null : _loginInternal,
            child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('MASUK'),
          ),
        ),
        // Biometric quick login
        if (BiometricService.instance.isEnabled) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _biometricLogin,
              icon: Icon(
                BiometricService.instance.biometricIcon == 'face_id' ? Icons.face : Icons.fingerprint,
                color: AppColors.brandPrimary,
              ),
              label: Text('Masuk dengan ${BiometricService.instance.biometricLabel}',
                  style: const TextStyle(color: AppColors.brandPrimary)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Akun personel dibuat oleh Super Admin.',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background blobs ─────────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandSecondary.withValues(alpha: 0.06),
              ),
            ),
          ),

          // ── Konten ──────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  GlassWidget(
                    borderRadius: 12,
                    blurSigma: 10,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.all(8),
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Masuk untuk melanjutkan.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 28),

                  // ── Mode toggle ─────────────────────────────────────────
                  GlassWidget(
                    borderRadius: 50,
                    blurSigma: 10,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _pillBtn('Konsumen', 0, AppColors.roleConsumer),
                        _pillBtn('Personel', 1, AppColors.brandPrimary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Form ────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _mode == 0 ? _consumerContent() : _personnelContent(),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Butuh bantuan atau panduan layanan?',
                          style: TextStyle(color: AppColors.textHint, fontSize: 13),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse("https://wa.me/628113619222");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.roleConsumer),
                          label: const Text(
                            'Hubungi WhatsApp Santa Maria',
                            style: TextStyle(
                              color: AppColors.roleConsumer,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, int index, Color color) {
    final isSelected = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = index;
          _isRegister = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
