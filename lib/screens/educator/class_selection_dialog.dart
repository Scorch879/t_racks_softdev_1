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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a class to generate a report for',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A2B3C), // Dark blueish color
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
                              side: const BorderSide(color: Color(0xFFBFD5E3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: const Color(0xFF1A2B3C),
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
