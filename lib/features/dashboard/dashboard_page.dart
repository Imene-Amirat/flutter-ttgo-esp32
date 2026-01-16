import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../data/models/esp32_values.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final TextEditingController ipCtrl = TextEditingController(
    text: "192.168.1.29",
  );

  Timer? _timer;
  bool isRunning = true; // Connected/Stop state

  Esp32Values? last;
  String? lastError;
  DateTime? lastSuccess;

  @override
  void initState() {
    super.initState();
    // auto start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectAndStart();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ipCtrl.dispose();
    super.dispose();
  }

  //  Status helpers (as you asked)
  String lightStatus(int value, int threshold) =>
      value < threshold ? "DARK" : "BRIGHT";

  String tempStatus(double value) {
    if (value < 10) return "COLD";
    if (value > 30) return "HOT";
    return "NORMAL";
  }

  Color statusColor(String s) {
    switch (s) {
      case "DARK":
        return Colors.deepPurple;
      case "BRIGHT":
        return Colors.green;
      case "COLD":
        return Colors.blue;
      case "HOT":
        return Colors.red;
      case "NORMAL":
      default:
        return Colors.green;
    }
  }

  //  polling logic
  Future<void> _fetchOnce() async {
    try {
      final repo = await ref.read(ttgoRepoProvider.future);
      final v = await repo.fetchValuesOnly();
      setState(() {
        last = v;
        lastError = null;
        lastSuccess = DateTime.now();
      });
    } catch (e) {
      setState(() {
        lastError = e.toString();
      });
    }
  }

  void _startPolling() {
    _timer?.cancel();
    isRunning = true;
    _fetchOnce();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchOnce());
    setState(() {});
  }

  void _stopPolling() {
    _timer?.cancel();
    isRunning = false;
    setState(() {});
  }

  Future<void> _connectAndStart() async {
    // Save base URL and refresh providers chain
    await ref.read(prefsProvider).setBaseUrl("http://${ipCtrl.text}");
    ref.invalidate(baseUrlProvider);
    ref.invalidate(apiClientProvider);
    ref.invalidate(ttgoRepoProvider);

    _startPolling();
  }

  String fmtTime(DateTime? dt) {
    if (dt == null) return "--";
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final v = last;

    final light = v?.lightRaw; // light_raw
    final temp = v?.temperatureC; // temp_c
    final thermRaw = v?.thermRaw; // therm_raw
    final ledOn = v?.ledOn == true;

    final lightThreshold = v?.lightThresholdRaw ?? 0;

    final lightStatusText = (light != null)
        ? lightStatus(light, lightThreshold)
        : "--";
    final tempStatusText = (temp != null) ? tempStatus(temp) : "--";

    return Scaffold(
      appBar: AppBar(
        title: const Text("TTGO Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(isRunning ? "Connected" : "Stopped"),
              backgroundColor: isRunning
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          //  Top bar like web (Base URL + Connect + Stop)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Device connection",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 14),

                  // ===== IP field under buttons =====
                  TextField(
                    controller: ipCtrl,
                    decoration: InputDecoration(
                      labelText: "Device IP (ESP32)",
                      hintText: "192.168.1.29",
                      prefixIcon: const Icon(Icons.wifi),
                      prefixText: "http://",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ===== Buttons row (good spacing) =====
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text("Connect"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _connectAndStart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle),
                          label: const Text("Stop"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _stopPolling,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ===== Info row: last success/error + refresh =====
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "Last success: ${fmtTime(lastSuccess)}",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),
                      OutlinedButton.icon(
                        onPressed: _fetchOnce,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          //  LIGHT card (like web)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wb_sunny, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LIGHT (raw)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          light == null ? "--" : "$light",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text("Status: "),
                            Text(
                              lightStatusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor(lightStatusText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Rule (AUTO/LIGHT): LED turns ON when light_raw < threshold.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          //  TEMP card (like web)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.thermostat, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TEMPERATURE (°C)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          temp == null ? "--" : temp.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (thermRaw != null)
                          Text(
                            "therm_raw: $thermRaw",
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text("Status: "),
                            Text(
                              tempStatusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor(tempStatusText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Rule (AUTO/TEMP): LED turns ON when temp_c > threshold.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          //  LED control (buttons like web)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "LED",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: ledOn ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ledOn ? "ON (GPIO25)" : "OFF (GPIO25)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      //  ON / OFF (pill buttons)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lightbulb, size: 18),
                              label: const Text("ON"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ledOn
                                    ? const Color(0xFF5B5F97)
                                    : Colors.grey.shade200,
                                foregroundColor: ledOn
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                final repo = await ref.read(
                                  ttgoRepoProvider.future,
                                );
                                await repo.ledOn();
                                await _fetchOnce();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                              ),
                              label: const Text("OFF"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !ledOn
                                    ? const Color(0xFFE6E7F5)
                                    : Colors.grey.shade200,
                                foregroundColor: !ledOn
                                    ? const Color(0xFF5B5F97)
                                    : Colors.grey.shade700,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                final repo = await ref.read(
                                  ttgoRepoProvider.future,
                                );
                                await repo.ledOff();
                                await _fetchOnce();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      //  TOGGLE (outlined big button)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync),
                        label: const Text("TOGGLE"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B5F97),
                          side: const BorderSide(color: Color(0xFF5B5F97)),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 64,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          final repo = await ref.read(ttgoRepoProvider.future);
                          await repo.ledToggle();
                          await _fetchOnce();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
