class Esp32Values {
  final double? temperatureC; // temp_c
  final int? thermRaw; // therm_raw
  final int? lightRaw; // light_raw
  final bool? ledOn; // led
  final bool? autoEnabled; // auto_enabled
  final String? autoSensor; // auto_sensor
  final int? lightThresholdRaw; // light_threshold_raw
  final double? tempThresholdC; // temp_threshold_c
  final Map<String, dynamic> raw;

  Esp32Values({
    required this.raw,
    this.temperatureC,
    this.thermRaw,
    this.lightRaw,
    this.ledOn,
    this.autoEnabled,
    this.autoSensor,
    this.lightThresholdRaw,
    this.tempThresholdC,
  });

  factory Esp32Values.fromJson(Map<String, dynamic> json) {
    num? _num(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    bool? _bool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'on';
      }
      return null;
    }

    // ✅ PRIORITÉ AUX VRAIES CLÉS DE TON API /api/values
    final tempC = _num(
      json['temp_c'] ??
          json['temperature_c'] ??
          json['temperature'] ??
          json['temp'],
    );
    final light = _num(json['light_raw'] ?? json['light'] ?? json['lumiere']);
    final therm = _num(json['therm_raw']);
    final led = _bool(json['led'] ?? json['led_state'] ?? json['state']);

    return Esp32Values(
      raw: json,
      temperatureC: tempC?.toDouble(),
      lightRaw: light?.toInt(),
      thermRaw: therm?.toInt(),
      ledOn: led,
      autoEnabled: _bool(json['auto_enabled']),
      autoSensor: json['auto_sensor']?.toString(),
      lightThresholdRaw: _num(json['light_threshold_raw'])?.toInt(),
      tempThresholdC: _num(json['temp_threshold_c'])?.toDouble(),
    );
  }
}
