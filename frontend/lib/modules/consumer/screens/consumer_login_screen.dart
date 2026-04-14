import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import 'consumer_home.dart';

class ConsumerLoginScreen extends StatefulWidget {
  const ConsumerLoginScreen({super.key});

  @override
  State<ConsumerLoginScreen> createState() => _ConsumerLoginScreenState();
}

class _ConsumerLoginScreenState extends State<ConsumerLoginScreen> {
  bool _isRegisterMode = false;

  // Login
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  // Register
  final _nameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _regPhoneController.dispose();
    _regPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      _showSnack('Lengkapi nomor HP dan PIN.');
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.loginConsumer(phone, pin);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ConsumerHome()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) _showSnack('Nomor HP atau PIN salah.');
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final pin = _regPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (name.isEmpty || phone.isEmpty || pin.isEmpty) {
      _showSnack('Lengkapi semua field.');
      return;
    }
    if (pin != confirm) {
      _showSnack('Konfirmasi PIN tidak cocok.');
      return;
    }
    if (pin.length < 4) {
      _showSnack('PIN minimal 4 digit.');
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.registerConsumer(name, phone, pin);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ConsumerHome()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) _showSnack('Registrasi gagal. Nomor HP mungkin sudah terdaftar.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPin = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPin ? obscure : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white54, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: isPin
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                  onPressed: onToggleObscure,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildField(
          controller: _phoneController,
          label: 'Nomor HP',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _pinController,
          label: 'PIN',
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
          isPin: true,
          obscure: _obscurePin,
          onToggleObscure: () => setState(() => _obscurePin = !_obscurePin),
        ),
        const SizedBox(height: 32),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => ElevatedButton(
            onPressed: auth.isLoading ? null : _login,
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('MASUK'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isRegisterMode = true),
          child: const Text('Belum punya akun? Daftar di sini', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildField(
          controller: _nameController,
          label: 'Nama Lengkap',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _regPhoneController,
          label: 'Nomor HP',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _regPinController,
          label: 'PIN (min 4 digit)',
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
          isPin: true,
          obscure: _obscurePin,
          onToggleObscure: () => setState(() => _obscurePin = !_obscurePin),
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _confirmPinController,
          label: 'Konfirmasi PIN',
          icon: Icons.lock_reset_outlined,
          keyboardType: TextInputType.number,
          isPin: true,
          obscure: _obscureConfirm,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 32),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => ElevatedButton(
            onPressed: auth.isLoading ? null : _register,
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('DAFTAR'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isRegisterMode = false),
          child: const Text('Sudah punya akun? Masuk', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 40,
              right: 40,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                const Icon(Icons.family_restroom_rounded, size: 56, color: AppTheme.accent),
                const SizedBox(height: 20),
                Text(
                  _isRegisterMode ? 'Daftar Akun' : 'Masuk sebagai\nKonsumen',
                  style: AppTheme.darkTheme.textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegisterMode
                      ? 'Buat akun untuk memantau proses layanan secara real-time.'
                      : 'Masuk dengan nomor HP dan PIN Anda.',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isRegisterMode
                      ? _buildRegisterForm()
                      : _buildLoginForm(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
