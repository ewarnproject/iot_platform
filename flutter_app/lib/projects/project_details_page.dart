import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../code_editor/code_editor_page.dart';
import '../services/github_api.dart';

// ── Data passed from dashboard ─────────────────────────────────────────────

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String abbr;
  final String category;
  final String status;
  final int progress;
  final Color accent;
  final IconData icon;
  final List<String> tags;
  final String updated;

  const ProjectDetailsPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.abbr = 'PRJ',
    this.category = 'IoT',
    this.status = 'Active',
    this.progress = 50,
    this.accent = const Color(0xFF00D4FF),
    this.icon = Icons.hub_rounded,
    this.tags = const [],
    this.updated = 'recently',
  });

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

// ── Mock content generators ────────────────────────────────────────────────

const _fileSets = <String, List<Map<String, String>>>{
  'Security':   [{'name': 'main.ino',           'ver': 'v2.1.0', 'size': '4.2 KB'},
                 {'name': 'face_detect.cpp',     'ver': 'v1.3.0', 'size': '18.7 KB'},
                 {'name': 'alert_logic.h',       'ver': 'v2.0.1', 'size': '2.8 KB'},
                 {'name': 'config.h',            'ver': 'v1.0.0', 'size': '1.1 KB'}],
  'Healthcare': [{'name': 'main.ino',            'ver': 'v3.0.0', 'size': '5.6 KB'},
                 {'name': 'ecg_reader.cpp',      'ver': 'v2.1.0', 'size': '12.3 KB'},
                 {'name': 'ble_comm.cpp',        'ver': 'v1.5.0', 'size': '7.8 KB'},
                 {'name': 'config.h',            'ver': 'v1.0.0', 'size': '1.2 KB'}],
  'default':    [{'name': 'main.ino',            'ver': 'v1.2.0', 'size': '3.1 KB'},
                 {'name': 'sensor_logic.cpp',    'ver': 'v2.0.0', 'size': '8.4 KB'},
                 {'name': 'wifi_handler.cpp',    'ver': 'v1.1.0', 'size': '5.2 KB'},
                 {'name': 'config.h',            'ver': 'v1.0.0', 'size': '1.0 KB'}],
};

const _hwSets = <String, Map<String, List<String>>>{
  'Security':      {'MCU': ['ESP32-WROVER','Raspberry Pi 4'], 'Sensors': ['Camera OV2640','PIR HC-SR501','Ultrasonic HC-SR04'], 'Actuators': ['Buzzer','Relay 5V','LED Strip WS2812']},
  'Healthcare':    {'MCU': ['ESP32-S3','Arduino Nano 33 BLE'], 'Sensors': ['MAX30100 SpO2','ECG AD8232','DS18B20 Temp'], 'Actuators': ['OLED Display','Buzzer','LED Indicator']},
  'Automation':    {'MCU': ['ESP32-WROOM','NodeMCU'], 'Sensors': ['DHT22','PIR Motion','LDR'], 'Actuators': ['Relay Board','Servo SG90','RGB LED']},
  'Traffic':       {'MCU': ['Raspberry Pi 4','ESP32-S3'], 'Sensors': ['Camera','IR Sensor','Radar'], 'Actuators': ['Signal LED','Display Panel','Buzzer']},
  'Environment':   {'MCU': ['ESP32-C3','Arduino Pro Mini'], 'Sensors': ['MQ-135 Air','Turbidity','pH Sensor'], 'Actuators': ['LCD 16x2','GSM Module','LED Bar']},
  'Air Quality':   {'MCU': ['ESP32-WROOM','LOLIN D32'], 'Sensors': ['MQ-135 AQI','MQ-7 CO','Dust PM2.5'], 'Actuators': ['OLED SSD1306','Buzzer','NeoPixel']},
  'Energy':        {'MCU': ['ESP32-S2','Arduino Due'], 'Sensors': ['CT Sensor SCT-013','Voltage Divider','INA219'], 'Actuators': ['LCD I2C','Relay Module','LED Display']},
  'default':       {'MCU': ['ESP32-WROOM-32','Arduino Nano'], 'Sensors': ['DHT11 Temp/Humid','LDR Light','HC-SR04 Ultrasonic'], 'Actuators': ['OLED 0.96"','Relay 5V','Buzzer Active']},
};

const _activityLog = [
  {'action': 'Pushed 3 commits',        'who': 'Abhilash', 'time': '2h ago',  'icon': 'upload'},
  {'action': 'Updated sensor_logic.cpp','who': 'Abhilash', 'time': '5h ago',  'icon': 'edit'},
  {'action': 'Flashed to ESP32-S3',     'who': 'System',   'time': '1d ago',  'icon': 'flash'},
  {'action': 'Created branch dev/v2',   'who': 'Abhilash', 'time': '2d ago',  'icon': 'branch'},
  {'action': 'Merged pull request #4',  'who': 'Abhilash', 'time': '3d ago',  'icon': 'merge'},
  {'action': 'Initial commit',          'who': 'Abhilash', 'time': '2w ago',  'icon': 'rocket'},
];

// ── Page state ─────────────────────────────────────────────────────────────

class _ProjectDetailsPageState extends State<ProjectDetailsPage>
    with TickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 4, vsync: this);

  late final AnimationController _heroCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..forward();
  late final Animation<double> _heroFade =
      CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);

  String? _githubRepoUrl;
  bool _githubBusy = false;
  bool _loadingGithubFiles = false;
  List<Map<String, String>>? _githubFileRows;
  String? _githubFilesError;

  @override
  void dispose() {
    _tabs.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFFF4D6D) : const Color(0xFF06D6A0),
    ));
  }

  Future<void> _connectGithubRepo() async {
    final controller = TextEditingController(text: _githubRepoUrl ?? '');
    final repoUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        title: const Text('Connect GitHub Repository',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'owner/repo or https://github.com/owner/repo',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Connect')),
        ],
      ),
    );
    if (repoUrl == null || repoUrl.isEmpty) return;

    setState(() => _githubBusy = true);
    try {
      await GithubApi.connect(widget.projectId, repoUrl);
      setState(() => _githubRepoUrl = repoUrl);
      await _loadGithubFiles();
      _toast('Connected to $repoUrl');
    } catch (e) {
      _toast('Connect failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _githubBusy = false);
    }
  }

  Future<void> _pullFromGithub() async {
    if (_githubRepoUrl == null) {
      _toast('Connect a GitHub repository first', isError: true);
      return _connectGithubRepo();
    }
    final url = GithubApi.pullUrl(widget.projectId);
    final opened = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    if (!opened) {
      _toast('Could not open download', isError: true);
    } else {
      _toast('Pulling latest version from GitHub…');
    }
  }

  Future<void> _loadGithubFiles() async {
    if (_githubRepoUrl == null) return;
    setState(() {
      _loadingGithubFiles = true;
      _githubFilesError = null;
    });
    try {
      final files = await GithubApi.repoFiles(widget.projectId);
      if (!mounted) return;
      setState(() {
        _githubFileRows = files
            .map((file) => {
                  'name': file['path'] as String,
                  'ver': 'remote',
                  'size': '${file['size'] ?? '?'} bytes',
                })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _githubFilesError = 'Could not load GitHub files';
        _githubFileRows = [];
      });
      _toast('Failed to load GitHub files: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingGithubFiles = false);
    }
  }

  Future<void> _pushToGithub() async {
    if (_githubRepoUrl == null) {
      _toast('Connect a GitHub repository first', isError: true);
      return _connectGithubRepo();
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _toast('Could not read selected file', isError: true);
      return;
    }

    setState(() => _githubBusy = true);
    try {
      final res = await GithubApi.push(
        widget.projectId,
        zipBytes: bytes,
        fileName: file.name,
        message: 'Update ${widget.abbr} files from IoT Platform',
      );
      _toast('Pushed ${res['filesPushed']} file(s) · commit ${res['commitSha']?.toString().substring(0, 7)}');
    } catch (e) {
      _toast('Push failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _githubBusy = false);
    }
  }

  List<Map<String, String>> get _files =>
      _fileSets[widget.category] ?? _fileSets['default']!;
  Map<String, List<String>> get _hw =>
      _hwSets[widget.category] ?? _hwSets['default']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned(
            top: -120, right: -80,
            child: _orb(380, widget.accent, .09)),
        Positioned(
            bottom: -160, left: -100,
            child: _orb(420, const Color(0xFF7B2FFF), .07)),
        FadeTransition(
          opacity: _heroFade,
          child: Column(children: [
            _header(),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _overviewTab(),
                  _hardwareTab(),
                  _filesTab(),
                  _activityTab(),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _header() {
    final (statusColor, statusLabel) = switch (widget.status) {
      'Active'      => (const Color(0xFF06D6A0), 'Active'),
      'In Progress' => (const Color(0xFFFFB347), 'In Progress'),
      _             => (const Color(0xFF7B2FFF), 'Planning'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accent.withOpacity(.15),
            const Color(0xFF0A1426),
            const Color(0xFF060B18),
          ],
        ),
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(.06))),
      ),
      child: Row(children: [
        // back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(.06),
              border: Border.all(color: Colors.white.withOpacity(.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white70, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        // project icon
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: widget.accent.withOpacity(.18),
            border: Border.all(color: widget.accent.withOpacity(.4)),
            boxShadow: [
              BoxShadow(
                  color: widget.accent.withOpacity(.3),
                  blurRadius: 16)
            ],
          ),
          child: Icon(widget.icon, color: widget.accent, size: 22),
        ),
        const SizedBox(width: 14),
        // name block
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Flexible(
                child: Text(widget.projectName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: widget.accent.withOpacity(.25)),
                ),
                child: Text(widget.abbr,
                    style: TextStyle(
                        color: widget.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8)),
              ),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.category_rounded,
                  size: 11,
                  color: Colors.white.withOpacity(.35)),
              const SizedBox(width: 4),
              Text(widget.category,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.45),
                      fontSize: 12)),
              const SizedBox(width: 14),
              Icon(Icons.schedule_rounded,
                  size: 11,
                  color: Colors.white.withOpacity(.25)),
              const SizedBox(width: 4),
              Text('Updated ${widget.updated}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.3),
                      fontSize: 12)),
            ]),
          ]),
        ),
        // status + progress
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: statusColor.withOpacity(.12),
              border: Border.all(color: statusColor.withOpacity(.35)),
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
                        color: statusColor.withOpacity(.7),
                        blurRadius: 5)
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text('${widget.progress}% complete',
                  style: TextStyle(
                      color: widget.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.progress / 100,
                  backgroundColor: Colors.white.withOpacity(.07),
                  valueColor:
                      AlwaysStoppedAnimation(widget.accent),
                  minHeight: 5,
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(width: 16),
        // action buttons
        if (_githubBusy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        _actionBtn(Icons.upload_rounded, 'Push', widget.accent,
            onTap: _githubBusy ? null : _pushToGithub),
        const SizedBox(width: 8),
        _actionBtn(Icons.download_rounded, 'Pull',
            Colors.white.withOpacity(.4),
            onTap: _githubBusy ? null : _pullFromGithub),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color,
          {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: color.withOpacity(.1),
            border: Border.all(color: color.withOpacity(.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── TAB BAR ───────────────────────────────────────────────────────────────
  Widget _tabBar() => Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1426),
          border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(.06))),
        ),
        child: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: widget.accent,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: widget.accent, width: 2),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Hardware'),
            Tab(text: 'Files'),
            Tab(text: 'Activity'),
          ],
        ),
      );

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────
  Widget _overviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // top row: description + stats
        LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth > 800;
          final desc = _descCard();
          final stats = _statsCard();
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Expanded(flex: 3, child: desc),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: stats),
                ])
              : Column(children: [desc, const SizedBox(height: 16), stats]);
        }),
        const SizedBox(height: 16),
        _techTagsCard(),
        const SizedBox(height: 16),
        _githubCard(),
      ]),
    );
  }

  Widget _descCard() => _panel(
        icon: Icons.description_rounded,
        title: 'Project Description',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'This ${widget.category} IoT project leverages embedded systems '
            'and cloud connectivity to deliver real-time monitoring, automated '
            'responses, and remote access through a web dashboard. Built on '
            'the IoT Platform framework with ${widget.tags.join(", ")} support.',
            style: TextStyle(
                color: Colors.white.withOpacity(.55),
                fontSize: 13,
                height: 1.65),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _infoPill(Icons.developer_board_rounded, 'Embedded Systems'),
            _infoPill(Icons.cloud_rounded, 'Cloud Connected'),
            _infoPill(Icons.security_rounded, 'Encrypted Comms'),
            _infoPill(Icons.bar_chart_rounded, 'Real-time Data'),
          ]),
        ]),
      );

  Widget _statsCard() => _panel(
        icon: Icons.bar_chart_rounded,
        title: 'Project Stats',
        child: Column(children: [
          _statRow(Icons.commit_rounded, 'Commits',
              '${24 + widget.progress ~/ 5}', widget.accent),
          _statRow(Icons.people_rounded, 'Contributors', '3',
              const Color(0xFF7B2FFF)),
          _statRow(Icons.bug_report_rounded, 'Open Issues', '2',
              const Color(0xFFFFD166)),
          _statRow(Icons.check_circle_rounded, 'Tests Passing', '18/18',
              const Color(0xFF06D6A0)),
          _statRow(Icons.storage_rounded, 'Repo Size', '2.4 MB',
              const Color(0xFF00D4FF)),
        ]),
      );

  Widget _statRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(.1),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.5), fontSize: 12)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _techTagsCard() => _panel(
        icon: Icons.label_rounded,
        title: 'Technology Stack',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.tags.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: widget.accent.withOpacity(.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.memory_rounded,
                    size: 12, color: widget.accent),
                const SizedBox(width: 6),
                Text(t,
                    style: TextStyle(
                        color: widget.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ),
      );

  Widget _githubCard() => _panel(
        icon: Icons.code_rounded,
        title: 'GitHub Repository',
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(.04),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: Icon(
                _githubRepoUrl == null
                    ? Icons.link_off_rounded
                    : Icons.lock_rounded,
                size: 20,
                color: Colors.white.withOpacity(.3)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                  _githubRepoUrl ??
                      'iot-platform / ${widget.abbr.toLowerCase()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                  _githubRepoUrl == null
                      ? 'Not connected · tap Connect to link a repo'
                      : 'Connected · ${widget.category} · IoT Platform',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.35),
                      fontSize: 11)),
            ]),
          ),
          if (_githubRepoUrl == null)
            _actionBtn(Icons.link_rounded, 'Connect', widget.accent,
                onTap: _githubBusy ? null : _connectGithubRepo)
          else
            _actionBtn(Icons.open_in_new_rounded, 'Open', widget.accent,
                onTap: () => launchUrl(
                    Uri.parse(_githubRepoUrl!.startsWith('http')
                        ? _githubRepoUrl!
                        : 'https://github.com/$_githubRepoUrl'),
                    webOnlyWindowName: '_blank')),
        ]),
      );

  Widget _infoPill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
        ]),
      );

  // ── HARDWARE TAB ──────────────────────────────────────────────────────────
  Widget _hardwareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(builder: (ctx, c) {
        final wide = c.maxWidth > 700;
        final cols = [
          _hwSection('MCU / Board', _hw['MCU'] ?? [],
              Icons.developer_board_rounded, const Color(0xFF00D4FF)),
          _hwSection('Sensors', _hw['Sensors'] ?? [],
              Icons.sensors_rounded, const Color(0xFF06D6A0)),
          _hwSection('Actuators / Output', _hw['Actuators'] ?? [],
              Icons.settings_rounded, const Color(0xFFFFD166)),
          _hwSection('Connectivity', widget.tags,
              Icons.wifi_rounded, const Color(0xFF7B2FFF)),
        ];
        if (wide) {
          return Column(children: [
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Expanded(child: cols[0]),
              const SizedBox(width: 16),
              Expanded(child: cols[1]),
            ]),
            const SizedBox(height: 16),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Expanded(child: cols[2]),
              const SizedBox(width: 16),
              Expanded(child: cols[3]),
            ]),
          ]);
        }
        return Column(children: [
          for (int i = 0; i < cols.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cols[i],
          ]
        ]);
      }),
    );
  }

  Widget _hwSection(
      String title, List<String> items, IconData icon, Color color) {
    return _panel(
      icon: icon,
      title: title,
      accent: color,
      child: Column(
        children: items.isEmpty
            ? [
                Text('No components defined',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.2),
                        fontSize: 12))
              ]
            : items.asMap().entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.06),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withOpacity(.14)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(.7)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('×${e.key == 0 ? 1 : 1}',
                          style: TextStyle(
                              color: color.withOpacity(.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                );
              }).toList(),
      ),
    );
  }

  // ── FILES TAB ─────────────────────────────────────────────────────────────
  Widget _filesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _panel(
        icon: Icons.folder_open_rounded,
        title: 'Source Files',
        child: Column(children: [
          // toolbar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: Row(children: [
                Icon(Icons.folder_rounded,
                    size: 13, color: Colors.white.withOpacity(.3)),
                const SizedBox(width: 7),
                Text('${widget.abbr.toLowerCase()}/',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.35),
                        fontSize: 12,
                        fontFamily: 'monospace')),
                const Spacer(),
                if (_githubRepoUrl != null)
                  GestureDetector(
                    onTap: _loadingGithubFiles ? null : _loadGithubFiles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.refresh,
                            size: 12, color: Colors.white.withOpacity(.6)),
                        const SizedBox(width: 4),
                        Text('Refresh',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.6),
                                fontSize: 11)),
                      ]),
                    ),
                  )
                else
                  Text('${_files.length} files',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.25),
                          fontSize: 11)),
              ]),
            ),
            if (_githubRepoUrl != null)
              if (_loadingGithubFiles)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_githubFilesError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(_githubFilesError!,
                      style: const TextStyle(color: Colors.white70)),
                )
              else if (_githubFileRows != null)
                ..._githubFileRows!.map((f) => _fileRow(f))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('GitHub repo connected. Tap Refresh to load files.',
                      style: const TextStyle(color: Colors.white70)),
                )
            else
              ..._files.map((f) => _fileRow(f)),
        ]),
      ),
    );
  }

  Widget _fileRow(Map<String, String> f) {
    final ext = f['name']!.split('.').last;
    final (extColor, extIcon) = switch (ext) {
      'ino'  => (const Color(0xFF00B4D8), Icons.developer_board_rounded),
      'cpp'  => (const Color(0xFF7B2FFF), Icons.code_rounded),
      'h'    => (const Color(0xFFFFD166), Icons.integration_instructions_rounded),
      'py'   => (const Color(0xFF06D6A0), Icons.code_rounded),
      _      => (Colors.white38, Icons.insert_drive_file_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(children: [
        // file icon
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: extColor.withOpacity(.1),
            border: Border.all(color: extColor.withOpacity(.2)),
          ),
          child: Icon(extIcon, size: 15, color: extColor),
        ),
        const SizedBox(width: 12),
        // name + version
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(f['name']!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: extColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(f['ver']!,
                    style: TextStyle(
                        color: extColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(f['size']!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.3),
                      fontSize: 11)),
            ]),
          ]),
        ),
        // action buttons
        _fileBtn(Icons.remove_red_eye_rounded, 'View',
            Colors.white.withOpacity(.3), () {
          final isRemote = f['ver'] == 'remote' || _githubRepoUrl != null;
          if (isRemote && _githubRepoUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodeEditorPage(
                    fileName: f['name']!,
                    projectId: widget.projectId,
                    remotePath: f['name']),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodeEditorPage(fileName: f['name']!),
              ),
            );
          }
        }),
        const SizedBox(width: 6),
        _fileBtn(Icons.edit_rounded, 'Edit', widget.accent, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CodeEditorPage(fileName: f['name']!),
            ),
          );
        }),
        const SizedBox(width: 6),
        _fileBtn(Icons.play_arrow_rounded, 'Run',
            const Color(0xFF06D6A0), () {
          final isRemote = f['ver'] == 'remote' || _githubRepoUrl != null;
          if (isRemote && _githubRepoUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodeEditorPage(
                    fileName: f['name']!,
                    projectId: widget.projectId,
                    remotePath: f['name'],
                    autoCompile: true),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CodeEditorPage(fileName: f['name']!, autoCompile: true),
              ),
            );
          }
        }),
      ]),
    );
  }

  Widget _fileBtn(
      IconData icon, String tip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: color.withOpacity(.1),
            border: Border.all(color: color.withOpacity(.2)),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }

  // ── ACTIVITY TAB ──────────────────────────────────────────────────────────
  Widget _activityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _panel(
        icon: Icons.timeline_rounded,
        title: 'Activity Timeline',
        child: Column(
          children: _activityLog.asMap().entries.map((e) {
            final i = e.key;
            final act = e.value;
            final isLast = i == _activityLog.length - 1;
            final (actColor, actIcon) = switch (act['icon']) {
              'upload' => (const Color(0xFF00D4FF), Icons.upload_rounded),
              'edit'   => (const Color(0xFFFFD166), Icons.edit_rounded),
              'flash'  => (const Color(0xFF7B2FFF), Icons.bolt_rounded),
              'branch' => (const Color(0xFF06D6A0), Icons.account_tree_rounded),
              'merge'  => (const Color(0xFFFF8C42), Icons.merge_rounded),
              _        => (widget.accent, Icons.rocket_launch_rounded),
            };

            return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // timeline column
              Column(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: actColor.withOpacity(.12),
                    border:
                        Border.all(color: actColor.withOpacity(.3)),
                  ),
                  child: Icon(actIcon, size: 14, color: actColor),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          actColor.withOpacity(.3),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
              ]),
              const SizedBox(width: 14),
              // content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(act['action']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            widget.accent,
                            widget.accent.withOpacity(.5)
                          ]),
                        ),
                        child: Center(
                          child: Text(
                            act['who']![0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(act['who']!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.45),
                              fontSize: 11)),
                      const SizedBox(width: 8),
                      Text('·',
                          style: TextStyle(
                              color: Colors.white.withOpacity(.2))),
                      const SizedBox(width: 8),
                      Text(act['time']!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.3),
                              fontSize: 11)),
                    ]),
                  ]),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ── Reusable panel card ────────────────────────────────────────────────────
  Widget _panel({
    required IconData icon,
    required String title,
    required Widget child,
    Color? accent,
  }) {
    final c = accent ?? widget.accent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: c.withOpacity(.12),
            ),
            child: Icon(icon, size: 15, color: c),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.white.withOpacity(.05),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        child,
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
      ..color = Colors.white.withOpacity(.02)
      ..strokeWidth = .5;
    const step = 50.0;
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
