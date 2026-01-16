import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../sensors/sensors_page.dart';
import '../charts/charts_page.dart';
import '../threshold/threshold_page.dart';
import '../stats/stats_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int i = 0;
  late final PageController controller = PageController(initialPage: i);

  final pages = const [
    DashboardPage(),
    SensorsPage(),
    ChartsPage(),
    ThresholdPage(),
    StatsPage(),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void go(int index) {
    setState(() => i = index);
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_rounded),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Charts',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Seuil'),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
