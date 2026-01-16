import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ttgo_flutter_app/data/models/esp32_values.dart';

import '../data/storage/preferences_service.dart';
import '../data/api/esp32_api_client.dart';
import '../data/repository/ttgo_repository.dart';

//  Preferences
final prefsProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

//  Base URL
final baseUrlProvider = FutureProvider<String>((ref) async {
  return ref.read(prefsProvider).getBaseUrl();
});

//  API Client
final apiClientProvider = FutureProvider<Esp32ApiClient>((ref) async {
  final baseUrl = await ref.watch(baseUrlProvider.future);
  return Esp32ApiClient(baseUrl: baseUrl);
});

//  Repository
final ttgoRepoProvider = FutureProvider<TTGORepository>((ref) async {
  final api = await ref.watch(apiClientProvider.future);
  return TTGORepository(api);
});

final valuesStreamProvider = StreamProvider<Esp32Values>((ref) async* {
  final repo = await ref.watch(ttgoRepoProvider.future);

  while (true) {
    final values = await repo.fetchValuesOnly();
    yield values;
    await Future.delayed(const Duration(seconds: 2));
  }
});
