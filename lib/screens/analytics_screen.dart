import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsData? _data;
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await AppState.of(context).api.getAnalytics();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: kBrown)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kAmber),
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAmber))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          _KpiRow(data: d),
          const SectionHeader('Top Detected Breeds'),
          _TopBreedsChart(data: d),
          const SectionHeader('Confidence Distribution'),
          _ConfidenceChart(data: d),
          const SectionHeader('14-Day Activity'),
          _DailyChart(data: d),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Data stored on server · refreshed on each load',
              style:
                  GoogleFonts.spaceMono(fontSize: 9, color: kMuted2),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final AnalyticsData data;
  const _KpiRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final kpis = [
      ('Total\nDetections', '${data.totalDetections}', Icons.search_rounded),
      ('Unique\nBreeds', '${data.uniqueBreedsDetected}', Icons.pets_rounded),
      ('Breeds\nin DB', '${data.totalBreedsInDb}', Icons.storage_rounded),
      ('High\nConfidence', '${data.highConfidenceCount}', Icons.verified_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: kpis
          .map((k) => _KpiCard(label: k.$1, value: k.$2, icon: k.$3))
          .toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: kBrown.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kWarm,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kAmber, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kBrown),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 11, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Breeds Bar Chart ─────────────────────────────────────────────────────

class _TopBreedsChart extends StatelessWidget {
  final AnalyticsData data;
  const _TopBreedsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.topBreeds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No detections yet',
            style: GoogleFonts.dmSans(color: kMuted)),
      );
    }
    final maxCount =
        data.topBreeds.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: kBrown.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: data.topBreeds
            .take(7)
            .map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          b.breed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: kDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: b.count / maxCount,
                            minHeight: 10,
                            backgroundColor: kWarm,
                            valueColor:
                                const AlwaysStoppedAnimation(kAmber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${b.count}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.spaceMono(
                              fontSize: 11, color: kMuted),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Confidence Pie / Bar ─────────────────────────────────────────────────────

class _ConfidenceChart extends StatelessWidget {
  final AnalyticsData data;
  const _ConfidenceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final buckets = data.confidenceBuckets;
    final keys = ['0-40', '40-60', '60-80', '80-100'];
    final colors = [kRed, kAmber, const Color(0xFF7BAE57), kGreen];
    final labels = ['Low', 'Fair', 'Good', 'High'];

    final total = keys.fold(0, (s, k) => s + (buckets[k] ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: keys.asMap().entries.map((e) {
          final count = buckets[e.value] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: colors[e.key], shape: BoxShape.circle)),
                SizedBox(
                    width: 36,
                    child: Text(labels[e.key],
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: kMuted))),
                const SizedBox(width: 4),
                Text(e.value,
                    style: GoogleFonts.spaceMono(
                        fontSize: 10, color: kMuted2)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: kWarm,
                      valueColor:
                          AlwaysStoppedAnimation(colors[e.key]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count',
                    style: GoogleFonts.spaceMono(
                        fontSize: 11, color: kMuted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 14-Day Activity ─────────────────────────────────────────────────────────

class _DailyChart extends StatelessWidget {
  final AnalyticsData data;
  const _DailyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final counts = data.dailyCounts;
    if (counts.isEmpty) {
      return Text('No data', style: GoogleFonts.dmSans(color: kMuted));
    }

    final maxY = counts
        .map((c) => c.count.toDouble())
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    final bars = counts.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.count.toDouble(),
            color: kAmber,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY, color: kWarm),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: BarChart(
        BarChartData(
          barGroups: bars,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= counts.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every 3rd label
                  if (idx % 3 != 0) return const SizedBox.shrink();
                  final parts = counts[idx].date.split('-');
                  final label = parts.length >= 3
                      ? '${parts[2]}/${parts[1]}'
                      : counts[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                        style: GoogleFonts.spaceMono(
                            fontSize: 8, color: kMuted2)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📊', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: kMuted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}