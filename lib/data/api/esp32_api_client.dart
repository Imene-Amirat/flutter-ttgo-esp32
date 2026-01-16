import 'dart:convert';
import 'package:http/http.dart' as http;

class Esp32ApiClient {
  Esp32ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  // HEALTH
  Future<Map<String, dynamic>> health() async {
    final res = await http.get(_uri('/api/health'));
    _check(res);
    return jsonDecode(res.body);
  }

  // SENSORS
  Future<Map<String, dynamic>> sensors() async {
    final res = await http.get(_uri('/api/sensors'));
    _check(res);
    return jsonDecode(res.body);
  }

  // VALUES
  Future<Map<String, dynamic>> values() async {
    final res = await http.get(_uri('/api/values'));
    _check(res);
    return jsonDecode(res.body);
  }

  // LED
  Future<void> led({required String state}) async {
    final res = await http.get(_uri('/api/led', {'state': state}));
    _check(res);
  }

  // THRESHOLD
  Future<void> setThreshold({
    required int enabled,
    String? sensor,
    num? value,
  }) async {
    final query = <String, dynamic>{'enabled': enabled.toString()};

    if (enabled == 1 && sensor != null && value != null) {
      query['sensor'] = sensor;
      query['value'] = value.toString();
    }

    final res = await http.get(_uri('/api/threshold', query));
    _check(res);
  }

  // UTILS
  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
