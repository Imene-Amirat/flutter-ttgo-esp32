import '../api/esp32_api_client.dart';
import '../models/esp32_values.dart';

class TTGORepository {
  TTGORepository(this.api);

  final Esp32ApiClient api;

  //  Values (used by Dashboard polling)
  Future<Esp32Values> fetchValuesOnly() async {
    final raw = await api.values();
    return Esp32Values.fromJson(raw);
  }

  //  Sensors
  Future<Map<String, dynamic>> fetchSensors() async {
    return api.sensors();
  }

  //  LED
  Future<void> ledOn() => api.led(state: 'on');
  Future<void> ledOff() => api.led(state: 'off');
  Future<void> ledToggle() => api.led(state: 'toggle');

  //  AUTO thresholds
  Future<void> enableAutoLight(int thresholdRaw) async {
    await api.setThreshold(enabled: 1, sensor: 'light', value: thresholdRaw);
  }

  Future<void> enableAutoTemp(double thresholdC) async {
    await api.setThreshold(enabled: 1, sensor: 'temp', value: thresholdC);
  }

  Future<void> disableAuto() async {
    await api.setThreshold(enabled: 0);
  }
}
