import 'dart:async';
import '../../core/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class BinanceSocketClient {
  static const String _url =
      'wss://stream.binance.com:9443/ws/btcusdt@kline_1m';

  WebSocketChannel? _channel;
  final StreamController<String> _streamController =
      StreamController.broadcast();

  Stream<String> get stream => _streamController.stream;

  final StreamController<bool> _connectionStatusController =
      StreamController.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  String? _currentUrl;

  void connect({String? urlOverride}) {
    // If already connected to the same URL, do nothing
    if (_isConnected && unmaskedUrl(urlOverride) == unmaskedUrl(_currentUrl)) {
      return;
    }

    // IF switching URL, disconnect first? Or just close current channel?
    // We should probably close current channel if we are reconnecting to a new one.
    if (_isConnected) {
      _channel?.sink.close(status.normalClosure);
      _isConnected = false;
    }

    _currentUrl = urlOverride ?? _currentUrl ?? _url;
    final targetUrl = _currentUrl!;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(targetUrl));
      _isConnected = true;
      _connectionStatusController.add(true); // Connected

      // Task 44: Reset retry count on successful connection or message
      _retryCount = 0;

      _channel!.stream.listen(
        (message) {
/*
          AppLogger.debug(
              "SOCKET: Msg received (len=${(message as String).length})");
*/
          _streamController.add(message);
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  String unmaskedUrl(String? url) => url ?? _url;

  // Task 44 Fix: Max retries and exponential backoff
  static const int _maxRetries = 10;

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    _connectionStatusController.add(false); // Disconnected

    if (_retryCount >= _maxRetries) {
      AppLogger.error('SOCKET: Max retries reached ($_maxRetries). Giving up.');
      return;
    }

    // Exponential backoff
    final delay = Duration(seconds: (1 << _retryCount).clamp(1, 60));
    _retryCount++;

    AppLogger.info(
        'Disconnected. Retrying in ${delay.inSeconds}s (Attempt $_retryCount/$_maxRetries)...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect(urlOverride: _currentUrl));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
    // Do NOT close stream controllers here, as we might reuse the instance.
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _streamController.close();
    _connectionStatusController.close();
  }
}
