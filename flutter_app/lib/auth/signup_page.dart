import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  double _passwordStrength = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _passwordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    final p = _passwordController.text;
    double strength = 0;
    if (p.length >= 8) strength += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 900));
      setState(() => _isLoading = false);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return const Color(0xFFFF4D6D);
    if (_passwordStrength <= 0.5) return const Color(0xFFFFB347);
    if (_passwordStrength <= 0.75) return const Color(0xFF00FFB3);
    return const Color(0xFF00D4FF);
  }

  String get _strengthLabel {
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF060B18), Color(0xFF0D1B2E), Color(0xFF080F1E)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(top: -100, left: -100, color: const Color(0xFF7B2FFF), size: 460),
            _buildGlow(bottom: -180, right: -100, color: const Color(0xFF00D4FF), size: 520),
            _buildGlow(top: 300, right: 60, color: const Color(0xFF00FFB3), size: 200, opacity: 0.06),
            _buildGridLines(),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 36),
                          _buildCard(),
                          const SizedBox(height: 28),
                          _buildFooterLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() => Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FFF).withOpacity(0.45),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.developer_board_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'IoT Platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect · Monitor · Control',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              letterSpacing: 2.5,
            ),
          ),
        ],
      );

  Widget _buildCard() => Container(
        padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, offset: const Offset(0, 24)),
            BoxShadow(
              color: const Color(0xFF7B2FFF).withOpacity(0.04),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create account',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Join and start building IoT solutions',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
              ),
              const SizedBox(height: 28),
              _buildDividerLine(),
              const SizedBox(height: 28),
              _buildLabel('Username'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hint: 'johndoe',
                icon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a username';
                  if (v.length < 3) return 'At least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a password';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildStrengthIndicator(),
              ],
              const SizedBox(height: 20),
              _buildLabel('Confirm Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: '••••••••',
                icon: Icons.lock_person_outlined,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm your password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _buildGradientButton(label: 'Create Account', isLoading: _isLoading, onPressed: _signup),
            ],
          ),
        ),
      );

  Widget _buildStrengthIndicator() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: _strengthColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Password strength: $_strengthLabel',
                style: TextStyle(color: _strengthColor, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      );

  Widget _buildLabel(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFF7B2FFF),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white30, size: 19),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7B2FFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D)),
          ),
          errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 12),
        ),
      );

  Widget _buildGradientButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) =>
      Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FFF).withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
      );

  Widget _buildFooterLink() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text(
              'Sign in',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00D4FF),
              ),
            ),
          ),
        ],
      );

  Widget _buildDividerLine() => Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'YOUR DETAILS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08), thickness: 1)),
        ],
      );

  Widget _buildGlow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
    double opacity = 0.12,
  }) =>
      Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), Colors.transparent],
            ),
          ),
        ),
      );

  Widget _buildGridLines() => Positioned.fill(
        child: CustomPaint(painter: _GridPainter()),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
