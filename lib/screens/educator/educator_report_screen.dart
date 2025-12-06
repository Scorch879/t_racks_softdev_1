import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/report_model.dart';
import 'package:fl_chart/fl_chart.dart';

class EducatorReportScreen extends StatefulWidget {
  const EducatorReportScreen({super.key});

  @override
  State<EducatorReportScreen> createState() => _EducatorReportScreenState();
}

class _EducatorReportScreenState extends State<EducatorReportScreen> {
  // Use the existing DatabaseService
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  String? _error;
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _databaseService.getEducatorDashboardData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Define the Background Widget
    // We define it once so we can use it for loading, error, and content states
    Widget buildBackground() {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF194B61),
              Color(0xFF2A7FA3),
              Color(0xFF267394),
              Color(0xFF349BC7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Opacity(
          opacity: 0.3,
          child: Image.asset(
            'assets/images/squigglytexture.png', // Ensure this matches your asset path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    // 2. Determine the Content Widget based on state
    Widget content;
    
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (_error != null) {
      content = Center(
        child: Text(
          'Error loading data: $_error',
          style: const TextStyle(color: Colors.white),
        ),
      );
    } else if (_data == null) {
      content = const SizedBox();
    } else {
      // The actual data content
      content = SingleChildScrollView(
        // AlwaysScrollableScrollPhysics allows pull-to-refresh behavior later if needed
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0), // Add padding at bottom
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildKPICards(),
              const SizedBox(height: 16),
              _buildAttendanceTrendsCard(),
              const SizedBox(height: 16),
              _buildClassAttendanceSection(),
              const SizedBox(height: 16),
              if (_data!.alerts.isNotEmpty) ...[
                _buildAttendanceAlertSection(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(

      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // LAYER 1: The Background (Fixed to fill screen)
          Positioned.fill(child: buildBackground()),

          // LAYER 2: The Content (Scrollable)
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              icon: Icons.person,
              value: _data?.overallAttendance ?? '-',
              label: 'Overall Attendance',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              icon: Icons.calendar_today,
              value: _data?.presentToday ?? '-',
              label: 'Present Today',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // inside lib/educator_report_screen.dart

  Widget _buildAttendanceTrendsCard() {
    // If no data, show a simple message
    if (_data?.trendData == null || _data!.trendData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3951).withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
        ),
        child: const Center(
          child: Text(
            "No attendance history available yet",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Attendance Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // THE GRAPH CONTAINER
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Only show specific indices to avoid clutter
                        int index = value.toInt();
                        if (index < 0 || index >= _data!.trendData.length)
                          return const SizedBox();

                        // Show date every few days depending on data size
                        if (index % 5 != 0 &&
                            index != _data!.trendData.length - 1)
                          return const SizedBox();

                        final date = _data!.trendData[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "${date.month}/${date.day}", // e.g. 10/27
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_data!.trendData.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _data!.trendData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.percentage);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF4CAF50), // Green Line
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(
                        0xFF4CAF50,
                      ).withOpacity(0.2), // Gradient fill
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassAttendanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Class Attendance (Today)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_data!.classMetrics.isEmpty)
            const Text(
              "No classes found",
              style: TextStyle(color: Colors.white70),
            ),

          ..._data!.classMetrics.map(
            (metric) => Column(
              children: [
                _buildClassCard(
                  className: metric.className,
                  totalStudents: metric.totalStudents,
                  present: metric.presentCount,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String className,
    required int totalStudents,
    required int present,
  }) {
    final percentage = totalStudents == 0
        ? 0
        : (present / totalStudents * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF133A53),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            className,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage < 50
                    ? const Color(0xFFE53935)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalStudents Students',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$present Present',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAlertSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Attendance Alert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._data!.alerts.map(
            (alert) => Column(
              children: [
                _buildAlertCard(
                  title: alert.title,
                  message: alert.message,
                  color: alert.isCritical
                      ? const Color(0xFFE53935)
                      : const Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
