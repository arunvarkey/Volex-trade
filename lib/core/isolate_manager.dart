import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_logger.dart';
import '../data/binance/binance_stream_mapper.dart';

/// Spawns a background isolate to handle heavy JSON parsing.
/// Input: Raw JSON Strings (from WebSocket).
/// Output: Candle objects (to Engine).
///
/// On web, dart:isolate is unavailable, so messages are parsed inline on the
/// main thread instead (the browser is single-threaded anyway).
class IsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();

  final StreamController<dynamic> _outputController =
      StreamController.broadcast();
  Stream<dynamic> get outputStream => _outputController.stream;

  bool _isReady = false;
  Future<void> get ready => _readyCompleter.future;
  final Completer<void> _readyCompleter = Completer();

  Future<void> start() async {
    if (kIsWeb) {
      // No isolates on web: parse inline in processData.
      _isReady = true;
      _readyCompleter.complete();
      return;
    }

    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort.sendPort,
    );

    // Handshake
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _isReady = true;
        _readyCompleter.complete();
      } else {
        _outputController.add(message);
      }
    });
  }

  void processData(dynamic data) {
    if (!_isReady) return;
    if (kIsWeb) {
      // Inline parse on the main thread.
      if (data is String) {
        final parsed = _parseMessage(data);
        if (parsed != null) _outputController.add(parsed);
      }
      return;
    }
    _sendPort?.send(data);
  }

  void dispose() {
    _receivePort.close();
    _outputController.close();
    _isolate?.kill();
  }

  /// Parses one raw WebSocket message into a Candle, List<Candle>, or
  /// List<MiniTicker>. Returns null for unrecognised/broken payloads.
  /// Pure function shared by the isolate entry and the web inline path.
  static dynamic _parseMessage(String message) {
    try {
      final json = jsonDecode(message);

      // Combined Stream Handling
      // Payload: {"stream": "<name>", "data": <payload>}
      dynamic data = json;
      if (json is Map && json.containsKey('stream') && json.containsKey('data')) {
        data = json['data'];
      }

      // Case A: Stream Event (Single Object, e.g. kline)
      if (data is Map && data.containsKey('e')) {
        if (data['e'] == 'kline') {
          return BinanceStreamMapper.mapKlineToCandle(data);
        }
        // NOTE: MiniTickers sometimes come as single events too
      }
      // Case B: Array (Snapshot OR MiniTicker List)
      else if (data is List) {
        if (data.isNotEmpty &&
            data[0] is Map &&
            data[0].containsKey('e') &&
            data[0]['e'] == '24hrMiniTicker') {
          return BinanceStreamMapper.mapMiniTickerList(data);
        } else {
          // Must be Kline Snapshot (List of Lists)
          return BinanceStreamMapper.mapSnapshot(data);
        }
      }
    } catch (e) {
      AppLogger.error('PARSE ERROR', e);
    }
    return null;
  }

  /// The entry point for the background Isolate
  static void _isolateEntry(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort); // Send our address back

    port.listen((message) {
      if (message is String) {
        final parsed = _parseMessage(message);
        if (parsed != null) mainSendPort.send(parsed);
      }
    });
  }
}
