import 'package:flutter/material.dart';
import '../services/github_api.dart';

class CodeEditorPage extends StatefulWidget {
  final String fileName;
  final int? projectId;
  final String? remotePath;
  final bool autoCompile;
  const CodeEditorPage({
    super.key,
    required this.fileName,
    this.projectId,
    this.remotePath,
    this.autoCompile = false,
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
  Serial.println("LED ON");
  delay(1000);
  digitalWrite(2, LOW);
  Serial.println("LED OFF");
  delay(1000);
}""",
  );

  String serialLogs = "Serial Monitor Started...\n";
  bool isCompiling = false;
  bool _loadingRemote = false;

  Future<void> loadRemoteContent(String projectFilePath, int projectId) async {
    setState(() => _loadingRemote = true);
    try {
      final content = await GithubApi.fetchFile(projectId, projectFilePath);
      _codeController.text = content;
    } catch (e) {
      // ignore for now
    } finally {
      setState(() => _loadingRemote = false);
    }
  }

  void _compileAndFlash() async {
    setState(() => isCompiling = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate compilation
    setState(() {
      isCompiling = false;
      serialLogs += "[System] Compilation Successful!\n[System] Flashing to ESP32...\n[System] Done!\n";
    });
  }

  @override
  void initState() {
    super.initState();
    // If opened with a remote path, load it
    if (widget.projectId != null && widget.remotePath != null) {
      loadRemoteContent(widget.remotePath!, widget.projectId!)
          .then((_) {
        if (widget.autoCompile) _compileAndFlash();
      });
    } else if (widget.autoCompile) {
      // no-op: compile the default example if requested
      _compileAndFlash();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${widget.fileName}'),
        actions: [
          IconButton(
            icon: isCompiling ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.play_arrow),
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
              child: TextField(
                controller: _codeController,
                readOnly: _loadingRemote,
                maxLines: null,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                decoration: const InputDecoration(border: InputBorder.none),
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
                  const Text('Serial Monitor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        serialLogs,
                        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
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
