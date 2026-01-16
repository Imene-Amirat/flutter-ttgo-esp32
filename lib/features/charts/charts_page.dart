import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  String tempStatus(double v) {
    if (v > 30) return "HOT";
    if (v < 10) return "COLD";
    return "NORMAL";
  }

  String lightStatus(double v, double threshold) {
    return v < threshold ? "DARK" : "BRIGHT";
  }

  Stream<QuerySnapshot> _historyStream() {
    return FirebaseFirestore.instance
        .collection('devices')
        .doc('ttgo-01') // ID de ton ESP32
        .collection('readings')
        .orderBy('createdAt')
        .limit(30)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Charts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final tempSpots = <FlSpot>[];
          final lightSpots = <FlSpot>[];

          for (int i = 0; i < docs.length; i++) {
            final d = docs[i].data() as Map<String, dynamic>;

            final raw = d['raw'] as Map<String, dynamic>?;

            final temp = (raw?['temp_c'] as num?)?.toDouble();
            final light = (raw?['light_raw'] as num?)?.toDouble();

            if (temp != null) {
              tempSpots.add(FlSpot(i.toDouble(), temp));
            }
            if (light != null) {
              lightSpots.add(FlSpot(i.toDouble(), light));
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChartCard(
                title: "Température (°C)",
                color: Colors.orange,
                spots: tempSpots,
              ),
              const SizedBox(height: 20),
              _ChartCard(
                title: "Lumière (raw)",
                color: Colors.blue,
                spots: lightSpots,
              ),
            ],
          );
        },
      ),
    );
  }
}

//  CHART CARD 
class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<FlSpot> spots;

  const _ChartCard({
    required this.title,
    required this.color,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
