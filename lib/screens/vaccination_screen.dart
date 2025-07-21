import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/notification_helper.dart';

class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final Set<String> _notifiedToday = {};
  String _lastNotificationDate = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.streamVaccinations(),
        builder: (context, snapshot) {
          final vaccinations = snapshot.data ?? [];
          final now = DateTime.now();
          final today =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          // Reset notifications if it's a new day
          if (_lastNotificationDate != today) {
            _notifiedToday.clear();
            _lastNotificationDate = today;
          }

          // --- Notification logic: notify if within a week of nextDate ---
          List<Map<String, dynamic>> upcomingVaccinations = [];

          for (final v in vaccinations) {
            if (v['nextDate'] != null) {
              final nextDate = (v['nextDate'] as Timestamp).toDate();
              final days =
                  nextDate
                      .difference(DateTime(now.year, now.month, now.day))
                      .inDays;
              if (days >= 0 && days <= 7) {
                final key = '${v['type']}_${_formatDate(nextDate)}';
                if (!_notifiedToday.contains(key)) {
                  upcomingVaccinations.add({
                    'key': key,
                    'type': v['type'],
                    'nextDate': nextDate,
                    'days': days,
                  });
                }
              }
            }
          }

          // Send notifications for all upcoming vaccinations with sequential delays
          for (int i = 0; i < upcomingVaccinations.length; i++) {
            final vaccination = upcomingVaccinations[i];
            _notifiedToday.add(vaccination['key']);

            Future.delayed(Duration(milliseconds: i * 500), () {
              NotificationHelper.showVaccinationNotification(
                id: i,
                title: 'Vaccination Reminder',
                body:
                    'Your dog needs ${vaccination['type']} vaccination in ${vaccination['days']} day${vaccination['days'] == 1 ? '' : 's'} (${_formatDate(vaccination['nextDate'])})',
              );
            });
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 183, 111, 216),
                        Color.fromARGB(255, 203, 125, 223),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  child: Column(
                    children: const [
                      Text(
                        'Vaccination Records',
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your pet\'s vaccination schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vaccination Status Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services,
                                    size: 32,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Vaccination Status',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Color(0xFF22C55E),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            vaccinations.any((v) {
                                                  final nextDate =
                                                      (v['nextDate']
                                                              as Timestamp)
                                                          .toDate();
                                                  final now = DateTime.now();
                                                  return nextDate.isAfter(
                                                        now,
                                                      ) &&
                                                      nextDate
                                                              .difference(now)
                                                              .inDays <=
                                                          7;
                                                })
                                                ? 'Upcoming Vaccinations'
                                                : 'Up to Date',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Vaccination History
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccination History',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children:
                                  vaccinations
                                      .map(
                                        (v) => Column(
                                          children: [
                                            _buildVaccinationItem(
                                              id: v['id'],
                                              type: v['type'],
                                              date:
                                                  (v['date'] as Timestamp)
                                                      .toDate(),
                                              nextDate:
                                                  (v['nextDate'] as Timestamp)
                                                      .toDate(),
                                              duration: v['duration'],
                                            ),
                                            const Divider(
                                              color: Color(0xFFF3F4F6),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                      // Actions
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    () => _showAddVaccinationDialog(context),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medical_services,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Vaccination',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVaccinationItem({
    required String id,
    required String type,
    required DateTime date,
    required DateTime nextDate,
    required int duration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services,
              size: 20,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Given: ${_formatDate(date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Next: ${_formatDate(nextDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditVaccinationDialog(
                  context,
                  id: id,
                  type: type,
                  date: date,
                  duration: duration,
                );
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, id);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showAddVaccinationDialog(BuildContext context) {
    final _typeController = TextEditingController();
    DateTime? _selectedDate;
    final _durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Vaccination'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Vaccine Type'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (months)',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Select Vaccination Date'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_typeController.text.isNotEmpty &&
                    _durationController.text.isNotEmpty &&
                    _selectedDate != null) {
                  await FirestoreService.addVaccination(
                    type: _typeController.text,
                    date: _selectedDate!,
                    duration: int.parse(_durationController.text),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Vaccination'),
            content: const Text(
              'Are you sure you want to delete this vaccination record?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirestoreService.deleteVaccination(docId);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showEditVaccinationDialog(
    BuildContext context, {
    required String id,
    required String type,
    required DateTime date,
    required int duration,
  }) {
    final _typeController = TextEditingController(text: type);
    DateTime _selectedDate = date;
    final _durationController = TextEditingController(
      text: duration.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Vaccination'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Vaccine Type'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (months)',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _selectedDate = picked;
                    }
                  },
                  child: const Text('Select Vaccination Date'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_typeController.text.isNotEmpty &&
                    _durationController.text.isNotEmpty) {
                  await FirestoreService.updateVaccination(
                    docId: id,
                    type: _typeController.text,
                    date: _selectedDate,
                    duration: int.parse(_durationController.text),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
