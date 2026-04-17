import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/location_tracking_service.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../driver/screens/driver_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../so/screens/so_dashboard_screen.dart';
import '../../supplier/screens/supplier_home_screen.dart';
import '../../gudang/screens/gudang_dashboard_screen.dart';
import '../../super_admin/screens/super_admin_dashboard_screen.dart';
import '../../finance/screens/finance_dashboard_screen.dart';
import '../../owner/screens/owner_dashboard_screen.dart';
import '../../musisi/screens/musisi_home_screen.dart';
import '../../tukang_angkat_peti/screens/tukang_angkat_peti_home_screen.dart';
import '../../tukang_jaga/screens/tukang_jaga_home_screen.dart';
import '../../security/screens/security_home_screen.dart';
import '../../viewer/screens/viewer_dashboard_screen.dart';
import '../../hrd/screens/hrd_dashboard_screen.dart';
import '../../dekor/screens/dekor_dashboard_screen.dart';
import '../../tukang_foto/screens/tukang_foto_dashboard_screen.dart';
import '../../petugas_akta/screens/petugas_akta_home_screen.dart';
import '../../vendor/screens/vendor_home_screen.dart';

class InternalLoginScreen extends StatefulWidget {
  const InternalLoginScreen({super.key});

  @override
  State<InternalLoginScreen> createState() => _InternalLoginScreenState();
}

class _InternalLoginScreenState extends State<InternalLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.loginInternal(
        _identifierController.text,
        _passwordController.text,
      );
      if (mounted) {
        final role = auth.user?['role'] as String?;
        if (role == RoleConstants.superAdmin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.driver) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.admin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.owner) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.supplier) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SupplierHomeScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.serviceOfficer) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SODashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.gudang) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const GudangDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.finance) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const FinanceDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.musisi) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MusisiHomeScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.tukangAngkatPeti) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TukangAngkatPetiHomeScreen()),
            (route) => false,
          );
        } else if (role == 'tukang_jaga') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TukangJagaHomeScreen()),
            (route) => false,
          );
        } else if (role == 'security') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SecurityHomeScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.viewer) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ViewerDashboardScreen()),
            (route) => false,
          );
        } else if (role == RoleConstants.hrd) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HrdDashboardScreen()),
            (route) => false,
          );
        } else if (role == 'dekor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DekorDashboardScreen()),
            (route) => false,
          );
        } else if (role == 'tukang_foto') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TukangFotoDashboardScreen()),
            (route) => false,
          );
        } else if (role == 'petugas_akta') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PetugasAktaHomeScreen()),
            (route) => false,
          );
        } else if (role == 'purchasing') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const FinanceDashboardScreen()),
            (route) => false,
          );
        } else if (role == 'pemuka_agama' || role == 'konsumsi') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat datang, ${auth.user?['name']}. (Dashboard Belum Tersedia)')),
          );
        }

        // Auto-start background location tracking jika consent sudah diberikan HR
        if (role != null && role != 'consumer' && role != 'owner' && role != 'super_admin') {
          LocationTrackingService.instance.initialize();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getLoginMessage(e)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10002B), Color(0xFF240046)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 40,
                  right: 40,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Personnel Login',
                      style: AppTheme.darkTheme.textTheme.displayLarge,
                    ),
                    const Text(
                      'Masuk ke portal operasional Santa Maria.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 48),
                    _buildField(
                      controller: _identifierController,
                      label: 'Email atau Nomor HP',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 48),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return LoadingButton(
                          label: 'MASUK',
                          loadingLabel: 'Masuk...',
                          isLoading: auth.isLoading,
                          onPressed: _handleLogin,
                          color: AppColors.brandPrimary,
                          icon: Icons.login,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Kembali ke Menu Utama',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}
