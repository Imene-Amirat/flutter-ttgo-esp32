import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../core/json_pretty.dart';
import '../../data/models/esp32_values.dart';

class SensorsPage extends ConsumerWidget {
  const SensorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Sensors"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Texte"),
              Tab(text: "JSON"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TextCombinedView(), _JsonCombinedView()],
        ),
      ),
    );
  }
}

//  TEXTE VIEW
// values + sensors COMBINED
//
class _TextCombinedView extends ConsumerWidget {
  const _TextCombinedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        ref.read(ttgoRepoProvider.future).then((r) => r.fetchValuesOnly()),
        ref.read(ttgoRepoProvider.future).then((r) => r.fetchSensors()),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // CASTS EXPLICITES
        final Esp32Values values = snapshot.data![0] as Esp32Values;
        final Map<String, dynamic> sensorsJson =
            snapshot.data![1] as Map<String, dynamic>;
        final List sensors = sensorsJson['sensors'] as List;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Données capteurs",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...sensors.map((s) {
              final String name = s['name'];
              final int pin = s['pin'];
              final String type = s['type'];
              final String unit = s['unit'] ?? '-';

              String valueText = "--";

              if (name == 'temperature') {
                valueText =
                    "${values.temperatureC?.toStringAsFixed(1) ?? '--'} °C";
              } else if (name == 'light') {
                valueText = values.lightRaw?.toString() ?? '--';
              } else if (name == 'led') {
                valueText = values.ledOn == true ? "ON" : "OFF";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //  TITLE + VALUE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            valueText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      //  SENSOR DETAILS
                      _InfoLine(label: "GPIO", value: pin.toString()),
                      _InfoLine(label: "Type", value: type),
                      _InfoLine(label: "Unit", value: unit),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

//
//  JSON VIEW
// /api/values + /api/sensors
//
class _JsonCombinedView extends ConsumerWidget {
  const _JsonCombinedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        ref.read(ttgoRepoProvider.future).then((r) => r.fetchValuesOnly()),
        ref.read(ttgoRepoProvider.future).then((r) => r.fetchSensors()),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // CASTS EXPLICITES
        final Esp32Values values = snapshot.data![0] as Esp32Values;
        final Map<String, dynamic> sensors =
            snapshot.data![1] as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "/api/values",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(prettyJson(values.raw)),
            ),

            const SizedBox(height: 20),

            const Text(
              "/api/sensors",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(prettyJson(sensors)),
            ),
          ],
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label : $value",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
