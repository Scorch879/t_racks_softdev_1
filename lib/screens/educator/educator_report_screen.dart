import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:t_racks_softdev_1/screens/educator/class_selection_dialog.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/report_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EducatorReportScreen extends StatefulWidget {
  const EducatorReportScreen({super.key});

  @override
  State<EducatorReportScreen> createState() => _EducatorReportScreenState();
}

class _EducatorReportScreenState extends State<EducatorReportScreen> {
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

  Future<void> _generateReport() async {
    // 1. Show class selection dialog
    final selectedClass = await showClassSelectionDialog(context);
    if (selectedClass == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating report for ${selectedClass.className}...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      // Permissions are no longer needed for this saving method.
      // 1. Fetch Data
      final reportData = await _databaseService.getAttendanceForReport(
        selectedClass.id,
      );

      final students = reportData['students'] as List;
      final dates = reportData['dates'] as List;
      final matrix = reportData['attendanceMatrix'] as Map<String, dynamic>;

      if (students.isEmpty) {
        throw 'This class has no students to report on.';
      }

      // 2. Create Excel File
      final excel = Excel.createExcel();
      final String sheetName = selectedClass.className.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      ); // Sanitize sheet name
      final Sheet sheet = excel[sheetName];
      excel.delete(excel.getDefaultSheet()!);

      // 3. Build Header Row
      final header = ['Student Name', ...dates];
      sheet.appendRow(
        header.map((e) => TextCellValue(e.toString())).toList(),
      ); // Use TextCellValue

      // 4. Build Student Rows
      for (final student in students) {
        final studentId = student['id'];
        final row = [
          TextCellValue(student['name']),
        ]; // Use TextCellValue for name
        for (final date in dates) {
          final status = matrix[studentId]?[date] ?? 'N/A'; // Default to N/A
          row.add(TextCellValue(status)); // Use TextCellValue for status
        }
        sheet.appendRow(row);
      }

      // 5. Save the file
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not access the Downloads folder.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Stop if we can't get the directory
      }

      final fileName =
          '${selectedClass.className}_Attendance_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
      final filePath = '${downloadsDir.path}/$fileName';
      final fileBytes = excel.save();

      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report saved to Downloads folder as "$fileName"'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: "OPEN",
                textColor: Colors.white,
                onPressed: () {
                  OpenFile.open(filePath);
                },
              ),
            ),
          );
          // Open the file automatically
          OpenFile.open(filePath);
        }
      } else {
        throw 'Failed to save Excel file.';
      }
    } catch (e, s) {
      debugPrint('Error generating report: $e');
      debugPrint('Stack trace: $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'assets/images/squigglytexture.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

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
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
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
          Positioned.fill(child: buildBackground()),
          Positioned.fill(child: SafeArea(bottom: false, child: content)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateReport,
        backgroundColor: const Color(0xFF7FE26B),
        child: const Icon(
          Icons.description,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
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

  Widget _buildAttendanceTrendsCard() {
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
                        int index = value.toInt();
                        if (index < 0 || index >= _data!.trendData.length)
                          return const SizedBox();

                        if (index % 5 != 0 &&
                            index != _data!.trendData.length - 1)
                          return const SizedBox();

                        final date = _data!.trendData[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "${date.month}/${date.day}",
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
                    color: const Color(0xFF4CAF50),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
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
