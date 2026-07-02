import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/github_api.dart';
import '../serial_port_stub.dart' if (dart.library.ffi) 'package:libserialport/libserialport.dart';

class CodeEditorPage extends StatefulWidget {
  final String fileName;
  final int? projectId;
  final String? remotePath;
  final bool autoCompile;
  final String? board;
  final String? port;

  const CodeEditorPage({
    super.key,
    required this.fileName,
    this.projectId,
    this.remotePath,
    this.autoCompile = false,
    this.board,
    this.port,
  });

  @override
  State<CodeEditorPage> createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  final TextEditingController _codeController = TextEditingController(
    text: """void setup() {
  Serial.begin(115200);
  pinMode(2, OUTPUT);
}

void loop() {
  digitalWrite(2, HIGH);
  Serial.println(\"LED ON\");
  delay(1000);
  digitalWrite(2, LOW);
  Serial.println(\"LED OFF\");
  delay(1000);
}""",
  );

  String serialLogs = 'Serial Monitor Started...\n';
  bool isCompiling = false;

  bool _loadingRemote = false;
  bool _portOpen = false;
  bool _portConnecting = false;

  SerialPort? _serialPort;
  SerialPortReader? _serialReader;
  StreamSubscription<Uint8List>? _serialSubscription;

  final ScrollController _serialScrollController = ScrollController();

  bool get _serialAvailable => !kIsWeb;

  Future<void> loadRemoteContent(String projectFilePath, int projectId) async {
    setState(() => _loadingRemote = true);
    try {
      final content = await GithubApi.fetchFile(projectId, projectFilePath);
      _codeController.text = content;
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingRemote = false);
    }
  }

  Future<void> _compileAndFlash() async {
    setState(() => isCompiling = true);
    serialLogs += '[System] Flash request...\n';

    try {
      // Backend endpoint to be implemented next.
      // Should trigger compile+flash for the selected board+port and return success/failure.
      final res = await http.post(
        Uri.parse('${GithubApi.baseUrl}/realtime/flash'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'board': widget.board ?? '',
          'port': widget.port ?? '',
          'fileName': widget.fileName,
          'projectId': widget.projectId,
          'remotePath': widget.remotePath,
          'baudRate': 115200,
        }),
      );

      if (!mounted) return;

      if (res.statusCode < 200 || res.statusCode >= 300) {
        serialLogs += '[System] Flash failed: HTTP ${res.statusCode}\n';
        if (res.body.isNotEmpty) serialLogs += '${res.body}\n';
        return;
      }

      serialLogs += '[System] Flash success. Starting serial monitor...\n';

      if (!_portOpen && widget.port != null && widget.port!.isNotEmpty) {
        if (_serialAvailable) {
          await _connectSerial();
        } else {
          serialLogs += '[Serial Monitor] Serial port access is not available on web.\n';
        }
      }
    } catch (e) {
      if (!mounted) return;
      serialLogs += '[System] Flash error: $e\n';
    } finally {
      if (mounted) setState(() => isCompiling = false);
    }
  }

  Future<void> _connectSerial() async {
    if (widget.port == null || widget.port!.isEmpty) {
      setState(() {
        serialLogs += '[Serial Monitor] No port selected.\n';
      });
      return;
    }

    setState(() {
      _portConnecting = true;
      serialLogs += '[Serial Monitor] Connecting to ${widget.port}...\n';
    });

    try {
      _serialPort?.dispose();
      _serialPort = SerialPort(widget.port!);

      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none);
      _serialPort!.config = config;

      if (!_serialPort!.openRead()) {
        throw Exception('Unable to open port ${widget.port}');
      }

      setState(() {
        _portOpen = true;
        serialLogs += '[Serial Monitor] Connected to ${widget.port}.\n';
      });

      _startSerialReader();
    } catch (error) {
      setState(() {
        serialLogs += '[Serial Monitor] Connection failed: $error\n';
      });
      _disconnectSerial();
    } finally {
      setState(() => _portConnecting = false);
    }
  }

  void _startSerialReader() {
    _serialReader?.close();
    _serialSubscription?.cancel();

    if (_serialPort == null || !_serialPort!.isOpen) return;

    _serialReader = SerialPortReader(_serialPort!);
    _serialSubscription = _serialReader!.stream.listen(
      (Uint8List bytes) async {
        // libserialport gives bytes, we decode as UTF-8 (best-effort)
        final text = utf8.decode(bytes, allowMalformed: true);
        setState(() {
          serialLogs += text;
        });
        _scrollToBottom();

        // Bridge serial output into backend readings so the main dashboard can show live data.
        // Each received chunk/line is stored under readings.serial_line.
        try {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;

          await http.post(
            Uri.parse('${GithubApi.baseUrl}/realtime/data'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'project_id': widget.projectId,
              'hardware_id': widget.port ?? widget.board ?? 'esp32',
              'sensor_type': 'serial',
              'readings': {
                'serial_line': trimmed,
              },
            }),
          );
        } catch (_) {
          // Never break serial monitoring due to backend issues.
        }
      },
      onError: (error) {
        setState(() {
          serialLogs += '[Serial Monitor] Read error: $error\n';
        });
      },
      onDone: () {
        setState(() {
          serialLogs += '[Serial Monitor] Disconnected.\n';
          _portOpen = false;
        });
      },
      cancelOnError: true,
    );
  }

  void _disconnectSerial() {
    _serialSubscription?.cancel();
    _serialSubscription = null;

    _serialReader?.close();
    _serialReader = null;

    if (_serialPort?.isOpen == true) {
      _serialPort?.close();
    }

    _serialPort?.dispose();
    _serialPort = null;

    setState(() {
      _portOpen = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_serialScrollController.hasClients) {
        _serialScrollController.jumpTo(_serialScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.projectId != null && widget.remotePath != null) {
      loadRemoteContent(widget.remotePath!, widget.projectId!).then((_) {
        if (widget.autoCompile) _compileAndFlash();
      });
    } else if (widget.autoCompile) {
      _compileAndFlash();
    }
  }

  @override
  void dispose() {
    _serialSubscription?.cancel();
    _serialReader?.close();
    _serialPort?.dispose();
    _serialScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${widget.fileName}'),
        actions: [
          IconButton(
            icon: isCompiling
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.play_arrow),
            onPressed: isCompiling ? null : _compileAndFlash,
            tooltip: 'Compile & Flash',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      readOnly: _loadingRemote,
                      maxLines: null,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  if (widget.board != null || widget.port != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Board: ${widget.board ?? 'None'} ‧ Port: ${widget.port ?? 'None'}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Serial Monitor',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  if (!_serialAvailable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: .4)),
                      ),
                      child: const Text(
                        'Serial port access is not available on web. Run this app as a desktop target using `flutter run -d windows`.',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                      ),
                    ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: !_serialAvailable || _portOpen || _portConnecting
                            ? null
                            : _connectSerial,
                        child: const Text('Connect'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _portOpen ? _disconnectSerial : null,
                        child: const Text('Disconnect'),
                      ),
                      const SizedBox(width: 12),
                      if (!_serialAvailable)
                        const Text('Desktop only',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      if (_portConnecting)
                        const Text('Connecting...',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      if (_portOpen)
                        const Text('Connected',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _serialScrollController,
                      child: Text(
                        serialLogs,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
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
}

