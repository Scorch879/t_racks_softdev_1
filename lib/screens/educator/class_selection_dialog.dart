import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';

Future<EducatorClassSummary?> showClassSelectionDialog(
  BuildContext context,
) async {
  return await showDialog<EducatorClassSummary>(
    context: context,
    builder: (BuildContext dialogContext) {
      return const _ClassSelectionDialog();
    },
  );
}

class _ClassSelectionDialog extends StatefulWidget {
  const _ClassSelectionDialog();

  @override
  State<_ClassSelectionDialog> createState() => _ClassSelectionDialogState();
}

class _ClassSelectionDialogState extends State<_ClassSelectionDialog> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<EducatorClassSummary>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _dbService.getEducatorClasses();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? const Color(0xFF0C3343) : Colors.white;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1A2B3C);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFBFD5E3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a class to generate a report for',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<EducatorClassSummary>>(
              future: _classesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading classes.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No classes found.'));
                }

                final classes = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: classes.map((aClass) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(aClass);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: primaryTextColor,
                            ),
                            child: Text(
                              aClass.className,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
