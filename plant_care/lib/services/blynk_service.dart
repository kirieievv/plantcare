import 'dart:convert';
import 'package:http/http.dart' as http;

class BlynkService {
  final String _authToken;
  final String _serverUrl;
  
  BlynkService({
    required String authToken,
    String serverUrl = 'https://blynk.cloud/external/api',
  }) : _authToken = authToken,
       _serverUrl = serverUrl;

  /// Get sensor data from ESP32
  Future<Map<String, dynamic>> getSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/get?token=$_authToken&v0&v1&v2&v3'),
      );

      if (response.statusCode == 200) {
        final data = response.body.split('\n');
        return {
          'soilMoisture': double.tryParse(data[0]) ?? 0.0,
          'temperature': double.tryParse(data[1]) ?? 0.0,
          'humidity': double.tryParse(data[2]) ?? 0.0,
          'lightLevel': double.tryParse(data[3]) ?? 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Failed to get sensor data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting sensor data: $e');
    }
  }

  /// Control water pump
  Future<bool> controlWaterPump(bool turnOn) async {
    try {
      final value = turnOn ? '1' : '0';
      final response = await http.get(
        Uri.parse('$_serverUrl/update?token=$_authToken&v4=$value'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error controlling water pump: $e');
    }
  }

  /// Set watering schedule
  Future<bool> setWateringSchedule(int durationSeconds) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/update?token=$_authToken&v5=$durationSeconds'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error setting watering schedule: $e');
    }
  }

  /// Get device status
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/isHardwareConnected?token=$_authToken'),
      );

      if (response.statusCode == 200) {
        final isConnected = response.body == 'true';
        return {
          'connected': isConnected,
          'lastSeen': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'connected': false,
          'lastSeen': null,
        };
      }
    } catch (e) {
      return {
        'connected': false,
        'lastSeen': null,
        'error': e.toString(),
      };
    }
  }

  /// Send notification to Blynk app
  Future<bool> sendNotification(String message) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/notify?token=$_authToken&body=${Uri.encodeComponent(message)}'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }
} 