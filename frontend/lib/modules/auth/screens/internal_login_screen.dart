import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../driver/screens/driver_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../so/screens/so_dashboard_screen.dart';
import '../../vendor/screens/supplier_dashboard_screen.dart';
import '../../gudang/screens/gudang_dashboard_screen.dart';
import '../../super_admin/screens/super_admin_dashboard_screen.dart';
import '../../finance/screens/finance_dashboard_screen.dart';
import '../../owner/screens/owner_dashboard_screen.dart';

class InternalLoginScreen extends StatefulWidget {
  const InternalLoginScreen({super.key});

  @override
  State<InternalLoginScreen> createState() => _InternalLoginScreenState();
}

class _InternalLoginScreenState extends State<InternalLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.loginInternal(
        _identifierController.text,
        _passwordController.text,
      );
      if (mounted) {
        final role = auth.user?['role'];
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
            MaterialPageRoute(builder: (_) => const SupplierDashboardScreen()),
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat datang, ${auth.user?['name']}. (Dashboard Belum Tersedia)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login gagal. Periksa kembali kredensial Anda.')),
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
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('MASUK'),
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
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
