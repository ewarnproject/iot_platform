import 'package:flutter/material.dart';

class _Device {
  final String name;
  final String ip;
  final String mac;
  final String type;
  final String signal;
  final Color accent;
  final String status;
  const _Device({
    required this.name,
    required this.ip,
    required this.mac,
    required this.type,
    required this.signal,
    required this.accent,
    required this.status,
  });
}

const _mockDevices = [
  _Device(name: 'ESP32-Weather-Station', ip: '192.168.1.45', mac: 'AA:BB:CC:DD:EE:FF',
      type: 'WiFi', signal: 'Strong', accent: Color(0xFF00D4FF), status: 'Online'),
  _Device(name: 'Smart-Lock-Controller', ip: '192.168.1.50', mac: '11:22:33:44:55:66',
      type: 'WiFi', signal: 'Good', accent: Color(0xFF06D6A0), status: 'Online'),
  _Device(name: 'HC-05 Bluetooth Module', ip: 'N/A', mac: '99:88:77:66:55:44',
      type: 'Bluetooth', signal: 'Good', accent: Color(0xFF7B2FFF), status: 'Paired'),
  _Device(name: 'Arduino-Sensor-Node', ip: '192.168.1.62', mac: 'CC:DD:EE:FF:00:11',
      type: 'WiFi', signal: 'Weak', accent: Color(0xFFFFB347), status: 'Online'),
  _Device(name: 'Raspberry-Pi-Gateway', ip: '192.168.1.10', mac: '22:33:44:55:66:77',
      type: 'WiFi', signal: 'Strong', accent: Color(0xFFFF4D6D), status: 'Online'),
  _Device(name: 'BLE-Motion-Sensor', ip: 'N/A', mac: '44:55:66:77:88:99',
      type: 'Bluetooth', signal: 'Weak', accent: Color(0xFF7B2FFF), status: 'Discovered'),
];

class NetworkScannerPage extends StatefulWidget {
  const NetworkScannerPage({super.key});

  @override
  State<NetworkScannerPage> createState() => _NetworkScannerPageState();
}

class _NetworkScannerPageState extends State<NetworkScannerPage>
    with TickerProviderStateMixin {
  bool isScanning = false;
  List<_Device> visibleDevices = List.from(_mockDevices);
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      isScanning = true;
      visibleDevices = [];
    });
    for (int i = 0; i < _mockDevices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() => visibleDevices.add(_mockDevices[i]));
    }
    if (mounted) setState(() => isScanning = false);
  }

  int get _wifiCount => visibleDevices.where((d) => d.type == 'WiFi').length;
  int get _btCount => visibleDevices.where((d) => d.type == 'Bluetooth').length;
  int get _onlineCount => visibleDevices.where((d) => d.status == 'Online').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060B18), Color(0xFF0D1B2E), Color(0xFF060D1A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, right: -100, child: _glowOrb(const Color(0xFF7B2FFF), 400, 0.09)),
            Positioned(bottom: -100, left: -80, child: _glowOrb(const Color(0xFF00D4FF), 450, 0.08)),
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNetworkStatus(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildDevicesHeader(),
                          const SizedBox(height: 16),
                          if (isScanning && visibleDevices.isEmpty)
                            _buildScanningPlaceholder()
                          else
                            _buildDeviceGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
          color: const Color(0xFF060B18).withOpacity(0.85),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white.withOpacity(0.7), size: 18),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF7B2FFF).withOpacity(0.12),
                border: Border.all(color: const Color(0xFF7B2FFF).withOpacity(0.25)),
              ),
              child: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF7B2FFF), size: 18),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Network Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Discover IoT devices on your network',
                    style: TextStyle(color: Color(0xFF7B2FFF), fontSize: 11, letterSpacing: 0.3)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: isScanning ? null : _startScan,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isScanning
                      ? null
                      : const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)]),
                  color: isScanning ? Colors.white.withOpacity(0.05) : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isScanning ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                  boxShadow: isScanning
                      ? []
                      : [BoxShadow(color: const Color(0xFF7B2FFF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    if (isScanning)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Color(0xFF7B2FFF), strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.radar_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isScanning ? 'Scanning...' : 'Scan Network',
                      style: TextStyle(
                        color: isScanning ? Colors.white.withOpacity(0.5) : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildNetworkStatus() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50 + (_pulseAnim.value * 12),
                    height: 50 + (_pulseAnim.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF06D6A0)
                          .withOpacity(0.08 - _pulseAnim.value * 0.07),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF06D6A0).withOpacity(0.12),
                      border: Border.all(
                          color: const Color(0xFF06D6A0).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.router_rounded,
                        color: Color(0xFF06D6A0), size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('192.168.1.0/24',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Local Network · Gateway 192.168.1.1',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF06D6A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF06D6A0).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF06D6A0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Connected',
                      style: TextStyle(
                          color: Color(0xFF06D6A0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatsRow() => Row(
        children: [
          _statCard('Devices Found', '${visibleDevices.length}', Icons.devices_rounded, const Color(0xFF00D4FF)),
          const SizedBox(width: 14),
          _statCard('WiFi', '$_wifiCount', Icons.wifi_rounded, const Color(0xFF06D6A0)),
          const SizedBox(width: 14),
          _statCard('Bluetooth', '$_btCount', Icons.bluetooth_rounded, const Color(0xFF7B2FFF)),
          const SizedBox(width: 14),
          _statCard('Online', '$_onlineCount', Icons.check_circle_rounded, const Color(0xFFFFB347)),
        ],
      );

  Widget _statCard(String label, String value, IconData icon, Color accent) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accent.withOpacity(0.1),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDevicesHeader() => Row(
        children: [
          const Text('Discovered Devices',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${visibleDevices.length}',
                style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );

  Widget _buildScanningPlaceholder() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80 + _pulseAnim.value * 30,
                      height: 80 + _pulseAnim.value * 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B2FFF)
                            .withOpacity(0.05 - _pulseAnim.value * 0.04),
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B2FFF).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFF7B2FFF).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.radar_rounded, color: Color(0xFF7B2FFF), size: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Scanning network...',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Discovering IoT devices on 192.168.1.0/24',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildDeviceGrid() {
    if (visibleDevices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(Icons.device_unknown_rounded,
                  color: Colors.white.withOpacity(0.15), size: 52),
              const SizedBox(height: 14),
              Text('No devices found',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 14)),
              const SizedBox(height: 6),
              Text('Tap Scan Network to discover devices',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        final w = (constraints.maxWidth - (cols - 1) * 16) / cols;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: visibleDevices
              .map((d) => SizedBox(width: w, child: _deviceCard(d)))
              .toList(),
        );
      },
    );
  }

  Widget _deviceCard(_Device device) {
    Color statusColor;
    switch (device.status) {
      case 'Online': statusColor = const Color(0xFF06D6A0); break;
      case 'Paired': statusColor = const Color(0xFF7B2FFF); break;
      default: statusColor = const Color(0xFFFFB347);
    }

    int signalBars;
    switch (device.signal) {
      case 'Strong': signalBars = 3; break;
      case 'Good': signalBars = 2; break;
      default: signalBars = 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              gradient: LinearGradient(colors: [device.accent, device.accent.withOpacity(0.2)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: device.accent.withOpacity(0.12),
                        border: Border.all(color: device.accent.withOpacity(0.2)),
                      ),
                      child: Icon(
                        device.type == 'WiFi' ? Icons.wifi_rounded : Icons.bluetooth_rounded,
                        color: device.accent,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: statusColor.withOpacity(0.1),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 5, height: 5,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                          const SizedBox(width: 5),
                          Text(device.status,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(device.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _infoRow(Icons.lan_rounded, device.ip == 'N/A' ? 'Bluetooth device' : device.ip),
                const SizedBox(height: 6),
                _infoRow(Icons.tag_rounded, device.mac),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt_rounded,
                        color: Colors.white.withOpacity(0.3), size: 13),
                    const SizedBox(width: 6),
                    ...List.generate(3, (i) => Container(
                          width: 8,
                          height: 8 + i * 3.0,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: i < signalBars ? device.accent : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                    const SizedBox(width: 6),
                    Text(device.signal,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showConnectDialog(device),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              device.accent.withOpacity(0.18),
                              device.accent.withOpacity(0.06),
                            ]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: device.accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_rounded, color: device.accent, size: 14),
                              const SizedBox(width: 6),
                              Text('Connect',
                                  style: TextStyle(
                                      color: device.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Icon(Icons.more_horiz_rounded,
                          color: Colors.white.withOpacity(0.35), size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.25), size: 13),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
          ),
        ],
      );

  void _showConnectDialog(_Device device) {
    final hostnameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 16)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: device.accent.withOpacity(0.12),
                      border: Border.all(color: device.accent.withOpacity(0.25)),
                    ),
                    child: Icon(
                      device.type == 'WiFi' ? Icons.wifi_rounded : Icons.bluetooth_rounded,
                      color: device.accent, size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Connect via ${device.type}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 20),
              if (device.type == 'WiFi') ...[
                _dialogField('Hostname / IP', hostnameCtrl, Icons.lan_rounded, hint: device.ip),
                const SizedBox(height: 14),
                _dialogField('Password', passwordCtrl, Icons.lock_outline_rounded, obscure: true),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: device.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: device.accent.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_searching_rounded, color: device.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pairing via Bluetooth',
                                style: TextStyle(
                                    color: device.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Ensure the device is in pairing mode',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.35), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(device.accent),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [device.accent, device.accent.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: device.accent.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Center(
                          child: Text('Connect',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false, String? hint}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 7),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFF00D4FF),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
              prefixIcon: Icon(icon, color: Colors.white30, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5)),
            ),
          ),
        ],
      );

  Widget _glowOrb(Color color, double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
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
