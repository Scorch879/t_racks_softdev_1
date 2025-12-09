import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';

Future<EducatorClassSummary?> showClassSelectionDialog(
    BuildContext context) async {
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
    return AlertDialog(
      title: const Text('Select a Class'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<EducatorClassSummary>>(
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
            return ListView.builder(
              shrinkWrap: true,
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final aClass = classes[index];
                return ListTile(
                  title: Text(aClass.className),
                  subtitle: Text(aClass.schedule),
                  onTap: () {
                    Navigator.of(context).pop(aClass);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
