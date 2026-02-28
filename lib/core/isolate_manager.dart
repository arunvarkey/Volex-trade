import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'app_logger.dart';
import '../data/binance/binance_stream_mapper.dart';

/// Spawns a background isolate to handle heavy JSON parsing.
/// Input: Raw JSON Strings (from WebSocket).
/// Output: Candle objects (to Engine).
class IsolateManager {
  late Isolate _isolate;
  late SendPort _sendPort;
  final _receivePort = ReceivePort();

  final StreamController<dynamic> _outputController =
      StreamController.broadcast();
  Stream<dynamic> get outputStream => _outputController.stream;

  bool _isReady = false;
  Future<void> get ready => _readyCompleter.future;
  final Completer<void> _readyCompleter = Completer();

  Future<void> start() async {
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
    _sendPort.send(data);
  }

  void dispose() {
    _receivePort.close();
    _outputController.close();
    _isolate.kill();
  }

  /// The entry point for the background Isolate
  static void _isolateEntry(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort); // Send our address back

    port.listen((message) {
      try {
        if (message is String) {
          final json = jsonDecode(message);

          // Combined Stream Handling
          // Payload: {"stream": "<name>", "data": <payload>}
          dynamic data = json;
          if (json is Map &&
              json.containsKey('stream') &&
              json.containsKey('data')) {
            data = json['data'];
          }

          // Case A: Stream Event (Single Object, e.g. kline)
          if (data is Map && data.containsKey('e')) {
            if (data['e'] == 'kline') {
              final candle = BinanceStreamMapper.mapKlineToCandle(data);
              if (candle != null) mainSendPort.send(candle);
            }
            // NOTE: MiniTickers sometimes come as single events too
          }
          // Case B: Array (Snapshot OR MiniTicker List)
          else if (data is List) {
            if (data.isNotEmpty &&
                data[0] is Map &&
                data[0].containsKey('e') &&
                data[0]['e'] == '24hrMiniTicker') {
              final tickers = BinanceStreamMapper.mapMiniTickerList(data);
              mainSendPort.send(tickers);
            } else {
              // Must be Kline Snapshot (List of Lists)
              final candles = BinanceStreamMapper.mapSnapshot(data);
              mainSendPort.send(candles);
            }
          }
        }
      } catch (e) {
        // AppLogger is not available in Isolate usually unless passed or pure dart
        // Use debugPrint which is safer in Flutter contexts
        AppLogger.error('ISOLATE ERROR', e);
      }
    });
  }
}
