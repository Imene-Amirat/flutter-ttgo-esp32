import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  // adapte si ton deviceId change
  static const String deviceId = 'ttgo-01';

  CollectionReference<Map<String, dynamic>> _eventsCol() {
    return FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .collection('events');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream() {
    return _eventsCol()
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots();
  }

  //  Parsing helpers

  String _extractType(Map<String, dynamic> data) {
    // Dans ton Firestore, type est dans payload.type
    final payload = data['payload'];
    if (payload is Map) {
      final t = payload['type'];
      if (t != null) return t.toString();
    }
    // fallback si un jour tu mets "type" au top-level
    final t2 = data['type'];
    if (t2 != null) return t2.toString();
    return '';
  }

  DateTime? _extractCreatedAt(Map<String, dynamic> data) {
    final v = data['createdAt'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  LatLng? _extractLatLng(Map<String, dynamic> data) {
    final lat = data['lat'];
    final lng = data['lng'];
    if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
    return null;
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y  $h:$m';
  }

  //  Device activity state
  _DeviceState _deviceStateFromLast(DateTime? last) {
    if (last == null) return _DeviceState.unknown;
    final diff = DateTime.now().difference(last);

    if (diff.inMinutes <= 2) return _DeviceState.active;
    if (diff.inMinutes <= 10) return _DeviceState.idle;
    return _DeviceState.problem;
  }

  //  Count usage
  _UsageCounters _buildCounters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int ledOn = 0;
    int ledOff = 0;
    int toggle = 0;
    int autoOff = 0;
    int apiErr = 0;

    for (final d in docs) {
      final data = d.data();
      final type = _extractType(data).toUpperCase();

      if (type == 'LED_ON')
        ledOn++;
      else if (type == 'LED_OFF')
        ledOff++;
      else if (type == 'LED_TOGGLE')
        toggle++;
      else if (type == 'AUTO_OFF')
        autoOff++;
      else if (type.contains('ERROR') || type.contains('API_ERROR'))
        apiErr++;
    }

    return _UsageCounters(
      ledOn: ledOn,
      ledOff: ledOff,
      toggle: toggle,
      autoOff: autoOff,
      apiErrors: apiErr,
    );
  }

  //  UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats & Debug')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Firestore error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          final counters = _buildCounters(docs);

          // Last event (most recent because orderBy desc)
          DateTime? lastEventAt;
          LatLng? lastLatLng;

          if (docs.isNotEmpty) {
            final lastData = docs.first.data();
            lastEventAt = _extractCreatedAt(lastData);
            lastLatLng = _extractLatLng(lastData);
          }

          // If first event has no location, search next one that has lat/lng
          if (lastLatLng == null) {
            for (final d in docs) {
              final ll = _extractLatLng(d.data());
              if (ll != null) {
                lastLatLng = ll;
                break;
              }
            }
          }

          final state = _deviceStateFromLast(lastEventAt);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              //  Device state (2 lignes comme tu veux)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lastEventAt != null)
                        Text(
                          'Dernière activité: ${_fmtDateTime(lastEventAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          'Dernière activité: —',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              //  Usage
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usage',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _usageRow(
                        label: 'LED ON',
                        value: counters.ledOn,
                        icon: Icons.lightbulb,
                        iconColor: Colors.green,
                      ),
                      _usageRow(
                        label: 'LED OFF',
                        value: counters.ledOff,
                        icon: Icons.lightbulb_outline,
                        iconColor: Colors.black54,
                      ),
                      _usageRow(
                        label: 'TOGGLE',
                        value: counters.toggle,
                        icon: Icons.sync,
                        iconColor: Colors.indigo,
                      ),
                      _usageRow(
                        label: 'AUTO OFF',
                        value: counters.autoOff,
                        icon: Icons.power_settings_new,
                        iconColor: Colors.orange,
                      ),
                      _usageRow(
                        label: 'Erreurs API',
                        value: counters.apiErrors,
                        icon: Icons.close,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              //  Localisation
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localisation (dernier point)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (lastLatLng == null)
                        Text(
                          'Aucune localisation trouvée dans les events.',
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: lastLatLng!,
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags:
                                      InteractiveFlag.drag |
                                      InteractiveFlag.pinchZoom |
                                      InteractiveFlag.doubleTapZoom,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.ttgo_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: lastLatLng!,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.location_pin,
                                        size: 44,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Lat: ${lastLatLng!.latitude.toStringAsFixed(6)}   Lng: ${lastLatLng!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          );
        },
      ),
    );
  }

  Widget _usageRow({
    required String label,
    required int value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

//  Small models
class _UsageCounters {
  final int ledOn;
  final int ledOff;
  final int toggle;
  final int autoOff;
  final int apiErrors;

  const _UsageCounters({
    required this.ledOn,
    required this.ledOff,
    required this.toggle,
    required this.autoOff,
    required this.apiErrors,
  });
}

enum _DeviceState { active, idle, problem, unknown }

extension on _DeviceState {
  String get label {
    switch (this) {
      case _DeviceState.active:
        return 'Activité récente (< 2 min)';
      case _DeviceState.idle:
        return 'Inactif';
      case _DeviceState.problem:
        return 'Problème possible';
      case _DeviceState.unknown:
        return 'Inconnu';
    }
  }

  IconData get icon {
    switch (this) {
      case _DeviceState.active:
        return Icons.circle;
      case _DeviceState.idle:
        return Icons.circle_outlined;
      case _DeviceState.problem:
        return Icons.warning_amber_rounded;
      case _DeviceState.unknown:
        return Icons.help_outline;
    }
  }

  Color get bg {
    switch (this) {
      case _DeviceState.active:
        return Colors.green.shade100;
      case _DeviceState.idle:
        return Colors.orange.shade100;
      case _DeviceState.problem:
        return Colors.red.shade100;
      case _DeviceState.unknown:
        return Colors.grey.shade200;
    }
  }
}
