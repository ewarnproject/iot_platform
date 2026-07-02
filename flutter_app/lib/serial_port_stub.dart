// Stub implementations for platforms where FFI is unavailable.

import 'dart:async';
import 'dart:typed_data';

class SerialPort {
  SerialPort(String name);
  void dispose() {}
  bool openRead() => false;
  bool get isOpen => false;
  set config(dynamic _) {}
  String? get name => null;
  bool close() => false;
}

class SerialPortReader {
  SerialPortReader(SerialPort port, {int? timeout});
  Stream<Uint8List> get stream => const Stream.empty();
  void close() {}
}

class SerialPortConfig {
  int baudRate = 0;
  int bits = 8;
  int parity = 0;
  int stopBits = 1;
  void setFlowControl(int value) {}
  void dispose() {}
}

abstract class SerialPortParity {
  static const int none = 0;
}

abstract class SerialPortFlowControl {
  static const int none = 0;
}
