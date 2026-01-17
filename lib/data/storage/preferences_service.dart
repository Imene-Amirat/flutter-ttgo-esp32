import 'package:shared_preferences/shared_preferences.dart';


// Service responsable de la gestion des préférences locales
// de l'application à l'aide de SharedPreferences.
class PreferencesService {
  static const _kBaseUrl = 'base_url';
  static const _kDeviceId = 'device_id';

  Future<String> getBaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBaseUrl) ?? 'http://10.201.126.133';
  }

  Future<void> setBaseUrl(String url) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBaseUrl, url);
  }

  Future<String> getDeviceId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kDeviceId) ?? 'ttgo-01';
  }

  Future<void> setDeviceId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDeviceId, id);
  }
}
