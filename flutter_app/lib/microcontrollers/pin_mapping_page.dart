import 'package:flutter/material.dart';
import 'mcu_data.dart';

class PinMappingPage extends StatefulWidget {
  const PinMappingPage({super.key});
  @override
  State<PinMappingPage> createState() => _PinMappingPageState();
}

class _PinMappingPageState extends State<PinMappingPage>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  int? _familyIdx;
  String? _model;
  int? _expandedRow;

  // assignments: 'FamilyName|ModelName|PinName' → component map
  final Map<String, Map<String, dynamic>> _assignments = {};

  // fade animation when content changes
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 320),
  )..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  // ── helpers ────────────────────────────────────────────────────────────────
  MCUFamily? get _family =>
      _familyIdx == null ? null : mcuFamilies[_familyIdx!];

  List<PinRow> get _pins {
    if (_model == null) return [];
    return pinLayouts[resolveKey(_model!)] ?? [];
  }

  String _assignKey(String pin) => '${_family!.name}|$_model|$pin';

  void _selectFamily(int idx) {
    setState(() {
      _familyIdx = idx;
      _model = null;
      _expandedRow = null;
    });
    _fadeCtrl.forward(from: 0);
  }

  void _selectModel(String model) {
    setState(() {
      _model = model;
      _expandedRow = null;
    });
    _fadeCtrl.forward(from: 0);
  }

  void _toggleRow(int idx) =>
      setState(() => _expandedRow = _expandedRow == idx ? null : idx);

  void _assign(PinRow pin, Map<String, dynamic> comp) {
    setState(() {
      _assignments[_assignKey(pin.pin)] = comp;
      _expandedRow = null;
    });
  }

  void _clearAssignment(PinRow pin) {
    setState(() {
      _assignments.remove(_assignKey(pin.pin));
      _expandedRow = null;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned(top: -100, left: -80, child: _glowOrb(260, const Color(0xFF00D4FF))),
        Positioned(bottom: -100, right: -60, child: _glowOrb(200, const Color(0xFF7B2FFF))),
        Row(children: [
          _buildSidebar(),
          Expanded(child: _buildMain()),
        ]),
      ]),
    );
  }

  // ── SIDEBAR ────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1426),
        border:
            Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF00D4FF).withOpacity(.10),
              Colors.transparent,
            ]),
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
          ),
          child: Row(children: const [
            Icon(Icons.memory_rounded, size: 18, color: Color(0xFF00D4FF)),
            SizedBox(width: 10),
            Text('MCU Families',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: .5)),
          ]),
        ),
        // scroll list
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // family tiles
              ...List.generate(mcuFamilies.length, (i) {
                final f = mcuFamilies[i];
                final sel = _familyIdx == i;
                return _sideTile(
                  icon: f.icon,
                  label: f.name,
                  sub: '${f.boards.length} boards',
                  accent: f.accent,
                  selected: sel,
                  onTap: () => _selectFamily(i),
                );
              }),
              // board tiles under selected family
              if (_family != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    Icon(_family!.icon, size: 11, color: _family!.accent),
                    const SizedBox(width: 6),
                    Text('${_family!.name} BOARDS',
                        style: TextStyle(
                            color: _family!.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ]),
                ),
                ..._family!.boards.map((b) => _sideTile(
                      icon: Icons.developer_board_rounded,
                      label: b,
                      accent: _family!.accent,
                      selected: _model == b,
                      indent: true,
                      onTap: () => _selectModel(b),
                    )),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sideTile({
    required IconData icon,
    required String label,
    String? sub,
    required Color accent,
    required bool selected,
    bool indent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(
            horizontal: indent ? 8 : 6, vertical: 2),
        padding: EdgeInsets.symmetric(
            horizontal: indent ? 10 : 12,
            vertical: indent ? 7 : 10),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? accent.withOpacity(.35) : Colors.transparent),
        ),
        child: Row(children: [
          Icon(icon,
              size: indent ? 13 : 16,
              color: selected ? accent : Colors.white30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color:
                              selected ? Colors.white : Colors.white60,
                          fontSize: indent ? 11.5 : 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400),
                      overflow: TextOverflow.ellipsis),
                  if (sub != null)
                    Text(sub,
                        style: TextStyle(
                            color: accent.withOpacity(.65),
                            fontSize: 10)),
                ]),
          ),
          if (selected)
            Icon(Icons.chevron_right_rounded, size: 15, color: accent),
        ]),
      ),
    );
  }

  // ── MAIN CONTENT ──────────────────────────────────────────────────────────
  Widget _buildMain() {
    if (_familyIdx == null) {
      return _emptyHint(
        Icons.memory_rounded,
        'Select an MCU Family',
        'Choose ESP32, Arduino, Raspberry Pi, or STM32 from the left panel',
      );
    }
    if (_model == null) {
      return _emptyHint(
        _family!.icon,
        'Select a Board',
        'Pick one of the ${_family!.boards.length} ${_family!.name} boards',
      );
    }

    final resolvedKey = resolveKey(_model!);
    final isAlias = resolvedKey != _model;
    final pins = _pins;

    return FadeTransition(
      opacity: _fade,
      child: Column(children: [
        // header bar
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1426),
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
          ),
          child: Row(children: [
            // family badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_family!.accent, _family!.accent.withOpacity(.5)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                Icon(_family!.icon, size: 12, color: Colors.black),
                const SizedBox(width: 5),
                Text(_family!.name,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .3)),
              ]),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded,
                size: 15, color: Colors.white30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_model!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
            if (isAlias) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('layout: $resolvedKey',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ),
            ],
            const Spacer(),
            Text('${pins.length} pins',
                style: const TextStyle(
                    color: Colors.white30, fontSize: 12)),
          ]),
        ),
        // table column header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: Colors.white.withOpacity(.018),
          child: Row(children: const [
            _ColHead('PIN', 3),
            _ColHead('TYPE', 3),
            _ColHead('FUNCTIONS', 7),
            _ColHead('CONNECTED COMPONENT', 6),
          ]),
        ),
        // rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 28),
            itemCount: pins.length,
            itemBuilder: (ctx, i) {
              final pin = pins[i];
              final comp = _assignments[_assignKey(pin.pin)];
              return _buildPinRow(pin, comp, _expandedRow == i, i);
            },
          ),
        ),
      ]),
    );
  }

  // ── PIN ROW ────────────────────────────────────────────────────────────────
  Widget _buildPinRow(
      PinRow pin, Map<String, dynamic>? comp, bool expanded, int idx) {
    return Column(children: [
      GestureDetector(
        onTap: () => _toggleRow(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: expanded
                ? pin.color.withOpacity(.08)
                : idx.isEven
                    ? Colors.white.withOpacity(.015)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: expanded
                  ? pin.color.withOpacity(.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(children: [
            // PIN name
            Expanded(
              flex: 3,
              child: Text(pin.pin,
                  style: TextStyle(
                      color: pin.color,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            // TYPE badge
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: pin.color.withOpacity(.11),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: pin.color.withOpacity(.22)),
                  ),
                  child: Text(pin.type,
                      style: TextStyle(
                          color: pin.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // FUNCTIONS
            Expanded(
              flex: 7,
              child: Text(pin.functions,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
            // COMPONENT
            Expanded(
              flex: 6,
              child: comp != null
                  ? _assignedChip(comp, pin)
                  : _unassignedHint(expanded),
            ),
          ]),
        ),
      ),
      // inline picker
      if (expanded)
        _buildPicker(pin),
    ]);
  }

  Widget _assignedChip(Map<String, dynamic> comp, PinRow pin) {
    final tag = comp['tag'] as String;
    final c = tag == 'Sensor'
        ? const Color(0xFF00D4FF)
        : tag == 'Actuator'
            ? const Color(0xFFFFD166)
            : tag == 'Output'
                ? const Color(0xFF7B2FFF)
                : const Color(0xFF06D6A0);
    return Row(children: [
      Icon(comp['icon'] as IconData, size: 14, color: c),
      const SizedBox(width: 6),
      Expanded(
        child: Text(comp['name'] as String,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis),
      ),
      GestureDetector(
        onTap: () => _clearAssignment(pin),
        child: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.close_rounded,
              size: 13, color: Colors.white24),
        ),
      ),
    ]);
  }

  Widget _unassignedHint(bool expanded) {
    return Row(children: [
      Icon(
        expanded
            ? Icons.arrow_downward_rounded
            : Icons.add_circle_outline_rounded,
        size: 12,
        color: Colors.white24,
      ),
      const SizedBox(width: 6),
      Text(
        expanded ? 'pick below ↓' : 'tap to assign',
        style: const TextStyle(color: Colors.white24, fontSize: 11),
      ),
    ]);
  }

  // ── COMPONENT PICKER ──────────────────────────────────────────────────────
  Widget _buildPicker(PinRow pin) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pin.color.withOpacity(.18)),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: componentCatalogue.map((comp) {
          final tag = comp['tag'] as String;
          final c = tag == 'Sensor'
              ? const Color(0xFF00D4FF)
              : tag == 'Actuator'
                  ? const Color(0xFFFFD166)
                  : tag == 'Output'
                      ? const Color(0xFF7B2FFF)
                      : const Color(0xFF06D6A0);
          return GestureDetector(
            onTap: () => _assign(pin, comp),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: c.withOpacity(.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: c.withOpacity(.18)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(comp['icon'] as IconData, size: 13, color: c),
                const SizedBox(width: 5),
                Text(comp['name'] as String,
                    style: TextStyle(color: c, fontSize: 11)),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.withOpacity(.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: c.withOpacity(.75),
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── EMPTY HINT ────────────────────────────────────────────────────────────
  Widget _emptyHint(IconData icon, String title, String sub) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
          ).createShader(b),
          child: Icon(icon, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Text(sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('← Left panel',
            style: TextStyle(color: Colors.white24, fontSize: 12)),
      ]),
    );
  }
}

// ── Shared widget helpers ─────────────────────────────────────────────────────

Widget _glowOrb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(.16), Colors.transparent]),
      ),
    );

class _ColHead extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHead(this.label, this.flex);

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.022)
      ..strokeWidth = .5;
    const step = 40.0;
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
