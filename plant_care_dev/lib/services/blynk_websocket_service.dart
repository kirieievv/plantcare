import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class BlynkWebSocketService {
  WebSocketChannel? _channel;
  final String _authToken;
  final String _serverUrl;
  final StreamController<Map<String, dynamic>> _sensorDataController = 
      StreamController<Map<String, dynamic>>.broadcast();

  BlynkWebSocketService({
    required String authToken,
    String serverUrl = 'wss://blynk.cloud/websockets',
  }) : _authToken = authToken,
       _serverUrl = serverUrl;

  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataController.stream;

  /// Connect to Blynk WebSocket
  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_serverUrl?token=$_authToken'),
      );

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      throw Exception('Failed to connect to Blynk WebSocket: $e');
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      
      if (message['type'] == 'sensor_data') {
        _sensorDataController.add({
          'soilMoisture': message['v0'] ?? 0.0,
          'temperature': message['v1'] ?? 0.0,
          'humidity': message['v2'] ?? 0.0,
          'lightLevel': message['v3'] ?? 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Send command to ESP32
  Future<void> sendCommand(String command, dynamic value) async {
    if (_channel != null) {
      final message = {
        'type': 'command',
        'command': command,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _sensorDataController.close();
  }
} 