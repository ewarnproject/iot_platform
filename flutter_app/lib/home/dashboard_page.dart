import 'package:flutter/material.dart';
import '../projects/project_details_page.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _Project {
  final int id;
  final String name;
  final String abbr;
  final String category;
  final IconData icon;
  final Color accent;
  final String status;
  final int progress;
  final String updated;
  final List<String> tags;

  const _Project({
    required this.id,
    required this.name,
    required this.abbr,
    required this.category,
    required this.icon,
    required this.accent,
    required this.status,
    required this.progress,
    required this.updated,
    required this.tags,
  });
}

// `id` must match the project ids in backend/src/data/projects.store.js
// so push/pull/connect calls hit the right GitHub repository.
const _projects = [
  _Project(id: 1, name: 'Criminal Activity Detector & Monitor', abbr: 'CADMS', category: 'Security', icon: Icons.shield_rounded, accent: Color(0xFFFF4D6D), status: 'Active', progress: 87, updated: '2h ago', tags: ['CV', 'BLE', 'Cloud']),
  _Project(id: 2, name: 'SmartHome Automation', abbr: 'SH', category: 'Automation', icon: Icons.home_rounded, accent: Color(0xFFFFB347), status: 'Active', progress: 92, updated: '1h ago', tags: ['WiFi', 'MQTT', 'Voice']),
  _Project(id: 3, name: 'Smart Traffic Control System', abbr: 'STCMS', category: 'Traffic', icon: Icons.traffic_rounded, accent: Color(0xFF00D4FF), status: 'In Progress', progress: 54, updated: '1d ago', tags: ['IoT', 'Edge', '4G']),
  _Project(id: 4, name: 'Drone Controller', abbr: 'DC', category: 'Aerial', icon: Icons.flight_rounded, accent: Color(0xFF7B2FFF), status: 'Active', progress: 78, updated: '3h ago', tags: ['RF', 'IMU', 'GPS']),
  _Project(id: 5, name: 'Bahan Kavach', abbr: 'BK', category: 'Vehicle', icon: Icons.directions_car_rounded, accent: Color(0xFFFF8C42), status: 'In Progress', progress: 41, updated: '2d ago', tags: ['CAN', 'OBD', 'SIM']),
  _Project(id: 6, name: 'Blind Curve Monitoring System', abbr: 'BCMS', category: 'Safety', icon: Icons.visibility_rounded, accent: Color(0xFFFFD166), status: 'Planning', progress: 15, updated: '5d ago', tags: ['Radar', 'LoRa']),
  _Project(id: 7, name: 'Wild Animal Monitoring', abbr: 'WAMS', category: 'Wildlife', icon: Icons.pets_rounded, accent: Color(0xFF06D6A0), status: 'Active', progress: 69, updated: '6h ago', tags: ['GPS', 'Solar', 'NB-IoT']),
  _Project(id: 8, name: 'CommStick', abbr: 'CS', category: 'Communication', icon: Icons.settings_input_antenna_rounded, accent: Color(0xFF00B4D8), status: 'Active', progress: 95, updated: '30m ago', tags: ['SDR', 'BLE', 'USB']),
  _Project(id: 9, name: 'High Speed FSO Transmitter', abbr: 'HSDT', category: 'Optical', icon: Icons.bolt_rounded, accent: Color(0xFF00D4FF), status: 'In Progress', progress: 33, updated: '3d ago', tags: ['FSO', 'Laser', 'FEC']),
  _Project(id: 10, name: 'Smart Healthcare Monitoring', abbr: 'SHCM', category: 'Healthcare', icon: Icons.monitor_heart_rounded, accent: Color(0xFFFF4D6D), status: 'Active', progress: 82, updated: '4h ago', tags: ['BLE', 'ECG', 'Cloud']),
  _Project(id: 11, name: 'Water Quality Monitoring', abbr: 'WQMS', category: 'Environment', icon: Icons.water_drop_rounded, accent: Color(0xFF0096C7), status: 'Active', progress: 74, updated: '8h ago', tags: ['pH', 'TDS', 'LoRa']),
  _Project(id: 12, name: 'Weather Monitoring System', abbr: 'WMS', category: 'Meteorology', icon: Icons.cloud_rounded, accent: Color(0xFF74C0FC), status: 'Active', progress: 91, updated: '1h ago', tags: ['BME280', 'Solar', 'WiFi']),
  _Project(id: 13, name: 'Soil Quality Monitoring', abbr: 'SQM', category: 'Agriculture', icon: Icons.grass_rounded, accent: Color(0xFF74B816), status: 'Planning', progress: 20, updated: '1w ago', tags: ['NPK', 'LoRa', 'Solar']),
  _Project(id: 14, name: 'Indoor Pollution Monitor', abbr: 'IPMS', category: 'Air Quality', icon: Icons.air_rounded, accent: Color(0xFF00FFB3), status: 'In Progress', progress: 48, updated: '2d ago', tags: ['PM2.5', 'VOC', 'WiFi']),
  _Project(id: 15, name: 'Underground Pollution Monitor', abbr: 'UPMS', category: 'Environment', icon: Icons.terrain_rounded, accent: Color(0xFF69DB7C), status: 'Planning', progress: 8, updated: '2w ago', tags: ['Sensor', 'Mesh']),
  _Project(id: 16, name: 'Outdoor Pollution Monitor', abbr: 'OPMS', category: 'Air Quality', icon: Icons.nature_rounded, accent: Color(0xFF00FFB3), status: 'Active', progress: 67, updated: '5h ago', tags: ['AQI', '4G', 'Solar']),
  _Project(id: 17, name: 'All-in-One IoT Platform', abbr: 'AIoTMS', category: 'IoT Platform', icon: Icons.hub_rounded, accent: Color(0xFF7B2FFF), status: 'Active', progress: 79, updated: '45m ago', tags: ['Multi', 'Cloud', 'MQTT']),
  _Project(id: 18, name: 'All-in-One Energy Monitor', abbr: 'AMS', category: 'Energy', icon: Icons.electric_bolt_rounded, accent: Color(0xFFFFD166), status: 'In Progress', progress: 38, updated: '1d ago', tags: ['CT', 'Grid', 'PV']),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  String _search = '';
  String _filterStatus = 'All';
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Project> get _filtered => _projects.where((p) {
        final q = _search.toLowerCase();
        final matchSearch = p.name.toLowerCase().contains(q) ||
            p.abbr.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
        final matchStatus =
            _filterStatus == 'All' || p.status == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();

  int _count(String s) => _projects.where((p) => p.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(children: [
        // background
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned(
            top: -140, right: -100,
            child: _orb(440, const Color(0xFF00D4FF), .07)),
        Positioned(
            bottom: -160, left: -120,
            child: _orb(500, const Color(0xFF7B2FFF), .07)),
        // content
        FadeTransition(
          opacity: _fade,
          child: Column(children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const SizedBox(height: 28),
                  _greeting(),
                  const SizedBox(height: 28),
                  _statsRow(),
                  const SizedBox(height: 32),
                  _projectsHeader(),
                  const SizedBox(height: 18),
                  _grid(),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF060B18).withOpacity(.92),
          border:
              Border(bottom: BorderSide(color: Colors.white.withOpacity(.06))),
        ),
        child: Row(children: [
          // logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(.35),
                    blurRadius: 12)
              ],
            ),
            child:
                const Icon(Icons.memory_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('IoT Platform',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5)),
          const SizedBox(width: 36),
          _navItem(Icons.dashboard_rounded, 'Dashboard', active: true),
          _navItem(Icons.developer_board_rounded, 'Controllers',
              onTap: () => Navigator.pushNamed(context, '/microcontrollers')),
          _navItem(Icons.wifi_tethering_rounded, 'Network',
              onTap: () => Navigator.pushNamed(context, '/network_scanner')),
          const Spacer(),
          // search
          Container(
            width: 210,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style:
                  const TextStyle(color: Colors.white, fontSize: 12),
              cursorColor: const Color(0xFF00D4FF),
              decoration: InputDecoration(
                hintText: 'Search projects…',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(.25), fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(.25), size: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _iconBtn(Icons.notifications_outlined),
          const SizedBox(width: 10),
          _avatar(),
        ]),
      );

  Widget _navItem(IconData icon, String label,
      {bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              active ? Colors.white.withOpacity(.07) : Colors.transparent,
        ),
        child: Row(children: [
          Icon(icon,
              size: 14,
              color: active
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withOpacity(.4)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacity(.4),
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.white.withOpacity(.05),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(icon, color: Colors.white.withOpacity(.45), size: 17),
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF4D6D),
              ),
            ),
          ),
        ]),
      );

  Widget _avatar() => Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)]),
        ),
        child: const Center(
          child: Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );

  // ── GREETING ───────────────────────────────────────────────────────────────
  Widget _greeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
              ).createShader(b),
              child: Text('$greet, Abhilash',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3)),
            ),
            const SizedBox(width: 10),
            const Text('👋', style: TextStyle(fontSize: 22)),
          ]),
          const SizedBox(height: 4),
          Text(
            '${_projects.length} active IoT projects · ${_count('Active')} running now',
            style: TextStyle(
                color: Colors.white.withOpacity(.38), fontSize: 13),
          ),
        ]),
      ),
      // quick action buttons
      _quickBtn(Icons.add_rounded, 'New Project', const Color(0xFF00D4FF)),
      const SizedBox(width: 10),
      _quickBtn(Icons.upload_rounded, 'Deploy', const Color(0xFF7B2FFF)),
    ]);
  }

  Widget _quickBtn(IconData icon, String label, Color accent) =>
      GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: accent.withOpacity(.1),
            border: Border.all(color: accent.withOpacity(.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── STATS ROW ──────────────────────────────────────────────────────────────
  Widget _statsRow() => Row(children: [
        _statCard('Total Projects', '${_projects.length}', '+2 this month',
            Icons.folder_copy_rounded, const Color(0xFF00D4FF), 1.0),
        const SizedBox(width: 14),
        _statCard('Active', '${_count('Active')}', 'Running now',
            Icons.check_circle_rounded, const Color(0xFF06D6A0),
            _count('Active') / _projects.length),
        const SizedBox(width: 14),
        _statCard('In Progress', '${_count('In Progress')}', 'Building',
            Icons.pending_rounded, const Color(0xFFFFB347),
            _count('In Progress') / _projects.length),
        const SizedBox(width: 14),
        _statCard('Planning', '${_count('Planning')}', 'Roadmap',
            Icons.edit_note_rounded, const Color(0xFF7B2FFF),
            _count('Planning') / _projects.length),
      ]);

  Widget _statCard(String label, String value, String sub, IconData icon,
      Color accent, double ratio) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.06)),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(.06),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: accent.withOpacity(.12),
                border: Border.all(color: accent.withOpacity(.2)),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: accent.withOpacity(.1),
              ),
              child: Text(sub,
                  style: TextStyle(
                      color: accent.withOpacity(.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(.38), fontSize: 12)),
          const SizedBox(height: 12),
          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white.withOpacity(.06),
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 3,
            ),
          ),
        ]),
      ),
    );
  }

  // ── PROJECTS HEADER ────────────────────────────────────────────────────────
  Widget _projectsHeader() => Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('IoT Projects',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${_filtered.length} of ${_projects.length} projects shown',
              style: TextStyle(
                  color: Colors.white.withOpacity(.3), fontSize: 12)),
        ]),
        const Spacer(),
        _chip('All'),
        const SizedBox(width: 8),
        _chip('Active'),
        const SizedBox(width: 8),
        _chip('In Progress'),
        const SizedBox(width: 8),
        _chip('Planning'),
      ]);

  Widget _chip(String label) {
    final active = _filterStatus == label;
    final counts = {
      'All': _projects.length,
      'Active': _count('Active'),
      'In Progress': _count('In Progress'),
      'Planning': _count('Planning'),
    };
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active
              ? const Color(0xFF00D4FF).withOpacity(.12)
              : Colors.white.withOpacity(.04),
          border: Border.all(
              color: active
                  ? const Color(0xFF00D4FF).withOpacity(.4)
                  : Colors.white.withOpacity(.07)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: active
                      ? const Color(0xFF00D4FF)
                      : Colors.white.withOpacity(.4),
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? const Color(0xFF00D4FF).withOpacity(.2)
                  : Colors.white.withOpacity(.06),
            ),
            child: Text('${counts[label]}',
                style: TextStyle(
                    color: active
                        ? const Color(0xFF00D4FF)
                        : Colors.white.withOpacity(.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── PROJECT GRID ───────────────────────────────────────────────────────────
  Widget _grid() {
    final items = _filtered;
    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded,
                color: Colors.white.withOpacity(.15), size: 44),
            const SizedBox(height: 12),
            Text('No projects match your filter',
                style: TextStyle(
                    color: Colors.white.withOpacity(.25), fontSize: 14)),
          ]),
        ),
      );
    }
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols =
            c.maxWidth > 1100 ? 3 : c.maxWidth > 700 ? 2 : 1;
        final w = (c.maxWidth - (cols - 1) * 16) / cols;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(items.length, (i) {
            // stagger fade-in
            final delay = (i * 60).clamp(0, 500);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + delay),
              curve: Curves.easeOut,
              builder: (_, v, child) =>
                  Opacity(opacity: v, child: child),
              child:
                  SizedBox(width: w, child: _card(items[i])),
            );
          }),
        );
      },
    );
  }

  Widget _card(_Project p) {
    final (statusColor, statusIcon) = switch (p.status) {
      'Active' => (const Color(0xFF06D6A0), Icons.radio_button_checked_rounded),
      'In Progress' => (const Color(0xFFFFB347), Icons.pending_rounded),
      _ => (const Color(0xFF7B2FFF), Icons.edit_note_rounded),
    };

    return _HoverCard(
      accent: p.accent,
      child: Column(children: [
        // accent header band with gradient + icon overlay
        Container(
          height: 76,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                p.accent.withOpacity(.28),
                p.accent.withOpacity(.06),
              ],
            ),
          ),
          child: Stack(children: [
            // background pattern dots
            Positioned(
              right: 16,
              bottom: 10,
              child: Opacity(
                opacity: .15,
                child: Icon(p.icon, size: 52, color: p.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: p.accent.withOpacity(.18),
                    border:
                        Border.all(color: p.accent.withOpacity(.35)),
                    boxShadow: [
                      BoxShadow(
                          color: p.accent.withOpacity(.25),
                          blurRadius: 10)
                    ],
                  ),
                  child: Icon(p.icon, color: p.accent, size: 20),
                ),
                const Spacer(),
                // status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: statusColor.withOpacity(.12),
                    border: Border.all(
                        color: statusColor.withOpacity(.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                              color: statusColor.withOpacity(.6),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(p.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        // card body
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // abbr tag
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.accent.withOpacity(.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: p.accent.withOpacity(.2)),
              ),
              child: Text(p.abbr,
                  style: TextStyle(
                      color: p.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6)),
            ),
            const SizedBox(height: 8),
            // name
            Text(p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
            const SizedBox(height: 5),
            // category + updated
            Row(children: [
              Icon(Icons.category_rounded,
                  size: 11,
                  color: Colors.white.withOpacity(.3)),
              const SizedBox(width: 4),
              Text(p.category,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.35),
                      fontSize: 11)),
              const Spacer(),
              Icon(Icons.schedule_rounded,
                  size: 11,
                  color: Colors.white.withOpacity(.25)),
              const SizedBox(width: 4),
              Text(p.updated,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.25),
                      fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            // progress bar
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text('Progress',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.3),
                            fontSize: 10)),
                    const Spacer(),
                    Text('${p.progress}%',
                        style: TextStyle(
                            color: p.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.progress / 100,
                      backgroundColor: Colors.white.withOpacity(.06),
                      valueColor:
                          AlwaysStoppedAnimation(p.accent),
                      minHeight: 4,
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            // tech tags
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: p.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.04),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.white.withOpacity(.08)),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 10)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            // open button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailsPage(
                    projectId: p.id,
                    projectName: p.name,
                    abbr: p.abbr,
                    category: p.category,
                    status: p.status,
                    progress: p.progress,
                    accent: p.accent,
                    icon: p.icon,
                    tags: p.tags,
                    updated: p.updated,
                  ),
                ),
              ),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    p.accent.withOpacity(.18),
                    p.accent.withOpacity(.06),
                  ]),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: p.accent.withOpacity(.3)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text('Open Project',
                      style: TextStyle(
                          color: p.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: p.accent, size: 13),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Hover-lift card wrapper ────────────────────────────────────────────────────

class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color accent;
  const _HoverCard({required this.child, required this.accent});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.accent.withOpacity(.35)
                : Colors.white.withOpacity(.06),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.accent.withOpacity(.14)
                  : Colors.black.withOpacity(.25),
              blurRadius: _hovered ? 28 : 16,
              offset: Offset(0, _hovered ? 12 : 6),
            ),
          ],
        ),
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -4.0 : 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Widget _orb(double size, Color color, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.022)
      ..strokeWidth = .6;
    const step = 52.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
