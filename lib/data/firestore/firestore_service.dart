import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({required this.deviceId});
  final String deviceId;

  CollectionReference<Map<String, dynamic>> get _readings => FirebaseFirestore
      .instance
      .collection('devices')
      .doc(deviceId)
      .collection('readings');

  CollectionReference<Map<String, dynamic>> get _events => FirebaseFirestore
      .instance
      .collection('devices')
      .doc(deviceId)
      .collection('events');

  Future<void> saveReading({
    required double? temperature,
    required double? light,
    double? lat,
    double? lng,
    required Map<String, dynamic> raw,
  }) async {
    await _readings.add({
      'temperature': temperature,
      'light': light,
      'lat': lat,
      'lng': lng,
      'raw': raw,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveEvent({
    required String type,
    Map<String, dynamic>? payload,
    double? lat,
    double? lng,
  }) async {
    await _events.add({
      'type':
          type, // LED_ON, LED_OFF, LED_TOGGLE, THRESHOLD_SET, AUTO_OFF, API_ERROR
      'payload': payload ?? {},
      'lat': lat,
      'lng': lng,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> readingsStream({int limit = 50}) {
    return _readings
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> eventsStream({int limit = 200}) {
    return _events
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}
