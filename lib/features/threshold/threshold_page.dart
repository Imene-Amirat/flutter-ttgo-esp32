import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';

class ThresholdPage extends ConsumerStatefulWidget {
  const ThresholdPage({super.key});

  @override
  ConsumerState<ThresholdPage> createState() => _ThresholdPageState();
}

class _ThresholdPageState extends ConsumerState<ThresholdPage> {
  String sensor = 'light';
  double threshold = 1800;

  @override
  Widget build(BuildContext context) {
    final valuesAsync = ref.watch(valuesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Seuil AUTO"), centerTitle: true),
      body: valuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("API error: $e")),
        data: (v) {
          final ledOn = v.ledOn ?? false;
          final autoEnabled = v.autoEnabled ?? false;
          final autoSensor = v.autoSensor ?? '-';
          final lightTh = v.lightThresholdRaw ?? 1800;
          final tempTh = v.tempThresholdC ?? 30.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              //  CURRENT STATE
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
                        "État actuel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _StatusChip(
                            icon: Icons.lightbulb,
                            label: ledOn ? "LED ON" : "LED OFF",
                            color: ledOn ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            icon: Icons.flash_on,
                            label: autoEnabled ? "AUTO ON" : "AUTO OFF",
                            color: autoEnabled ? Colors.indigo : Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Capteur AUTO : $autoSensor",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const Divider(height: 24),

                      Text("Seuil lumière : ${lightTh.toInt()}"),
                      Text(
                        "Seuil température : ${tempTh.toStringAsFixed(1)} °C",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //  SENSOR SELECTION
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
                        "Choix du capteur",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'light', label: Text("Lumière")),
                          ButtonSegment(
                            value: 'temp',
                            label: Text("Température"),
                          ),
                        ],
                        selected: {sensor},
                        onSelectionChanged: (s) {
                          setState(() {
                            sensor = s.first;
                            threshold = sensor == 'light'
                                ? lightTh.toDouble()
                                : tempTh;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      Text(
                        sensor == 'light'
                            ? "Seuil lumière (0–4095)"
                            : "Seuil température (°C)",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Slider(
                        min: 0,
                        max: sensor == 'light' ? 4095 : 60,
                        divisions: sensor == 'light' ? 4095 : 120,
                        value: threshold,
                        onChanged: (v) => setState(() => threshold = v),
                      ),

                      Center(
                        child: Text(
                          sensor == 'light'
                              ? threshold.toInt().toString()
                              : threshold.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),

                      const SizedBox(height: 16),

                      //  ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.flash_on),
                              label: const Text("Activer AUTO"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 19,
                                ),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                final repo = await ref.read(
                                  ttgoRepoProvider.future,
                                );
                                if (sensor == 'light') {
                                  await repo.enableAutoLight(threshold.toInt());
                                } else {
                                  await repo.enableAutoTemp(threshold);
                                }
                                ref.invalidate(valuesStreamProvider);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.power_settings_new),
                              label: const Text("Désactiver AUTO"),
                              onPressed: () async {
                                final repo = await ref.read(
                                  ttgoRepoProvider.future,
                                );
                                await repo.disableAuto();
                                ref.invalidate(valuesStreamProvider);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

//  STATUS CHIP
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
    );
  }
}
