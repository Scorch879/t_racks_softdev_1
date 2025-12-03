import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

class CreateClassModal extends StatefulWidget {
  const CreateClassModal({super.key});

  @override
  State<CreateClassModal> createState() => _CreateClassModalState();
}

class _CreateClassModalState extends State<CreateClassModal> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _subjectController = TextEditingController();

  // Days of the week selection
  final List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _selectedDays = [];

  String _getFormattedSchedule() {
    // 1. Sort the days to ensure they are in order (Sun -> Sat)
    // We create a reference list to sort by
    final allDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    _selectedDays.sort(
      (a, b) => allDays.indexOf(a).compareTo(allDays.indexOf(b)),
    );

    // 2. Check for specific patterns
    // Check for MWF
    bool isMWF =
        _selectedDays.length == 3 &&
        _selectedDays.contains('Mon') &&
        _selectedDays.contains('Wed') &&
        _selectedDays.contains('Fri');

    if (isMWF) return "MWF";

    // Check for TTh (Tue, Thu)
    bool isTTh =
        _selectedDays.length == 2 &&
        _selectedDays.contains('Tue') &&
        _selectedDays.contains('Thu');

    if (isTTh) return "TTh";

    // 3. Default: Convert to short codes (e.g., "M", "T", "W", "Th")
    // You can customize these abbreviations
    StringBuffer buffer = StringBuffer();
    for (var day in _selectedDays) {
      switch (day) {
        case 'Sun':
          buffer.write('Su');
          break;
        case 'Mon':
          buffer.write('M');
          break;
        case 'Tue':
          buffer.write('T');
          break;
        case 'Wed':
          buffer.write('W');
          break;
        case 'Thu':
          buffer.write('Th');
          break;
        case 'Fri':
          buffer.write('F');
          break;
        case 'Sat':
          buffer.write('S');
          break;
      }
    }
    return buffer.toString();
  }

  // Time Range
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  // --- FIXED TIME FORMATTER ---
  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Select Time";

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";

    return "$hour:$minute $period";
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- USE THE NEW HELPER HERE ---
      String daysString = _getFormattedSchedule();
      // -------------------------------

      String timeString = "${_formatTime(_startTime)}-${_formatTime(_endTime)}";

      final dbService = DatabaseService();
      await dbService.createClass(
        className: _classNameController.text,
        subject: _subjectController.text,
        day: daysString,
        time: timeString,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Add a new class",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C3343),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Class Name ---
                  const Text(
                    "Class Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C3343),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _classNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFEBEBEB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Class Subject ---
                  const Text(
                    "Class Subject",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C3343),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFEBEBEB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Select Schedule (Days) ---
                  const Text(
                    "Select Schedule",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C3343),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _days.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isSelected
                                ? _selectedDays.remove(day)
                                : _selectedDays.add(day);
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0C3343),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0C3343)
                                    : const Color(0xFFEBEBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? null
                                    : Border.all(color: Colors.grey.shade400),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- Time Range (Fixed Display Logic) ---
                  Row(
                    children: [
                      // Start Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Starting Time",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C3343),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(true),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBEBEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTime(_startTime), // Use helper
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _startTime == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // End Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ending Time",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C3343),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(false),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBEBEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTime(_endTime), // Use helper
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _endTime == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Create Classroom Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AB389),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create Classroom",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
