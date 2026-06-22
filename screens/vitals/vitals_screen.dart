// ─────────────────────────────────────────────────────────────────────────────
// screens/vitals/vitals_screen.dart  —  Health Vitals Tab
//
// FEATURES:
//  - 4 vital type tabs: Blood Pressure, Blood Sugar, Weight, Heart Rate
//  - Line chart showing readings over time (using fl_chart)
//  - List of past readings with delete (swipe left)
//  - FAB to log a new reading
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/vital.dart';
import '../../services/firestore_service.dart';
import 'add_vital_screen.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Each tab corresponds to a vital type
  static const _types = [
    'blood_pressure',
    'blood_sugar',
    'weight',
    'heart_rate',
  ];

  static const _labels = [
    'Blood Pressure',
    'Blood Sugar',
    'Weight',
    'Heart Rate',
  ];

  static const _icons = [
    Icons.favorite,
    Icons.water_drop,
    Icons.monitor_weight,
    Icons.timeline,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: const Text('Health Vitals'),
            pinned: true,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: List.generate(
                _types.length,
                (i) => Tab(
                  icon: Icon(_icons[i], size: 18),
                  text: _labels[i],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _types
              .map((type) => _VitalTab(type: type))
              .toList(),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Pass current tab's type as default selection in the add screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddVitalScreen(
                defaultType: _types[_tabController.index],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Reading'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VitalTab  —  Content for each tab (chart + list)
// ─────────────────────────────────────────────────────────────────────────────
class _VitalTab extends StatelessWidget {
  final String type;
  const _VitalTab({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Vital>>(
      stream: FirestoreService.getVitals(type: type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vitals = snapshot.data ?? [];

        if (vitals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No readings logged yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "Log Reading" to add one',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Chart uses data oldest → newest
        final chartData = vitals.reversed.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Line Chart ────────────────────────────────────────────────
            if (vitals.length >= 2) ...[
              Container(
                padding: const EdgeInsets.all(16),
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (val, _) => Text(
                            val.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= chartData.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat('d MMM')
                                  .format(chartData[idx].recordedAt),
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.value);
                        }).toList(),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Latest Reading Card ───────────────────────────────────────
            _LatestCard(vital: vitals.first),
            const SizedBox(height: 16),

            // ── History List ─────────────────────────────────────────────
            Text(
              'History',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            ...vitals
                .map((v) => _VitalListTile(vital: v))
                .toList(),

            const SizedBox(height: 100), // space for FAB
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LatestCard  —  Big card showing the most recent reading
// ─────────────────────────────────────────────────────────────────────────────
class _LatestCard extends StatelessWidget {
  final Vital vital;
  const _LatestCard({required this.vital});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Reading',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            vital.displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEE, d MMM yyyy  hh:mm a').format(vital.recordedAt),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (vital.notes != null && vital.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '📝 ${vital.notes}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VitalListTile  —  Each past reading row (swipe left to delete)
// ─────────────────────────────────────────────────────────────────────────────
class _VitalListTile extends StatelessWidget {
  final Vital vital;
  const _VitalListTile({required this.vital});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(vital.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => FirestoreService.deleteVital(vital.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vital.displayValue,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            Text(
              DateFormat('d MMM, hh:mm a').format(vital.recordedAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
