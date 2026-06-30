import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060B18), Color(0xFF0D1B2E), Color(0xFF060D1A)],
          ),
        ),
        child: Stack(
          children: [
            _glow(top: -140, right: -140, color: const Color(0xFF00D4FF), size: 500, opacity: 0.10),
            _glow(bottom: -200, left: -160, color: const Color(0xFF7B2FFF), size: 600, opacity: 0.10),
            _glow(top: 300, left: 200, color: const Color(0xFF00FFB3), size: 250, opacity: 0.05),
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() => FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _heroSlide,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildNavBar(),
                _buildHero(),
                const SizedBox(height: 60),
                _buildFeatureCards(),
                const SizedBox(height: 60),
                _buildStatsRow(),
                const SizedBox(height: 80),
                _buildCTA(),
                const SizedBox(height: 60),
                _buildFooter(),
              ],
            ),
          ),
        ),
      );

  Widget _buildNavBar() => Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 16),
                ],
              ),
              child: const Icon(Icons.memory_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'IoT Platform',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            _navLink('Features'),
            const SizedBox(width: 32),
            _navLink('Docs'),
            const SizedBox(width: 32),
            _navLink('GitHub'),
            const SizedBox(width: 32),
            _outlineButton(
              label: 'Sign In',
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
          ],
        ),
      );

  Widget _navLink(String label) => Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );

  Widget _outlineButton({required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );

  Widget _buildHero() => Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                    color: const Color(0xFF00D4FF).withOpacity(0.06),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00D4FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Now supporting ESP32, Arduino & Raspberry Pi',
                        style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB0BEC5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    'One Platform for\nAll Your IoT Devices',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect, monitor, and control microcontrollers, sensors, and actuators\nfrom a single unified dashboard. Built for engineers and makers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 44),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _gradientButton(
                      label: 'Get Started',
                      icon: Icons.rocket_launch_rounded,
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      colors: const [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                      glowColor: const Color(0xFF00D4FF),
                    ),
                    const SizedBox(width: 16),
                    _ghostButton(
                      label: 'Sign In',
                      icon: Icons.login_rounded,
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> colors,
    required Color glowColor,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ghostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            color: Colors.white.withOpacity(0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFeatureCards() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                _sectionLabel('CAPABILITIES'),
                const SizedBox(height: 12),
                const Text(
                  'Everything you need to manage IoT',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _featureCard(
                      icon: Icons.memory_rounded,
                      title: 'Microcontroller Hub',
                      body: 'Configure ESP32, Arduino, Raspberry Pi with pin mapping and version control.',
                      accent: const Color(0xFF00D4FF),
                    ),
                    _featureCard(
                      icon: Icons.wifi_tethering_rounded,
                      title: 'Network Scanner',
                      body: 'Discover and connect WiFi and Bluetooth devices on your local network instantly.',
                      accent: const Color(0xFF7B2FFF),
                    ),
                    _featureCard(
                      icon: Icons.sensors_rounded,
                      title: 'Sensor & Actuators',
                      body: 'Map components to pins, monitor real-time data and control actuators remotely.',
                      accent: const Color(0xFF00FFB3),
                    ),
                    _featureCard(
                      icon: Icons.code_rounded,
                      title: 'GitHub Integration',
                      body: 'Link repositories to projects, sync firmware and manage code deployments.',
                      accent: const Color(0xFFFFB347),
                    ),
                    _featureCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Live Dashboard',
                      body: 'Visualize telemetry, device status and project health from one central view.',
                      accent: const Color(0xFFFF4D6D),
                    ),
                    _featureCard(
                      icon: Icons.security_rounded,
                      title: 'Secure Access',
                      body: 'Role-based authentication with encrypted credentials and session management.',
                      accent: const Color(0xFF00D4FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String body,
    required Color accent,
  }) =>
      Container(
        width: 290,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withOpacity(0.12),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatsRow() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('18+', 'IoT Projects'),
                _statDivider(),
                _stat('50+', 'Sensor Types'),
                _statDivider(),
                _stat('3', 'MCU Families'),
                _statDivider(),
                _stat('100%', 'Open Source'),
              ],
            ),
          ),
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
        ],
      );

  Widget _statDivider() => Container(
        width: 1,
        height: 48,
        color: Colors.white.withOpacity(0.07),
      );

  Widget _buildCTA() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00D4FF).withOpacity(0.08),
                  const Color(0xFF7B2FFF).withOpacity(0.08),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                const Text(
                  'Start building today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a free account and connect your first device in minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 32),
                _gradientButton(
                  label: 'Create Free Account',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  colors: const [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                  glowColor: const Color(0xFF00D4FF),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFooter() => Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '© 2025 IoT Platform. Built with Flutter & ❤',
              style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
            ),
          ],
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: const Color(0xFF00D4FF).withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      );

  Widget _glow({
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
