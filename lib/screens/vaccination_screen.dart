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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.streamVaccinations(),
        builder: (context, snapshot) {
          final vaccinations = snapshot.data ?? [];
          final now = DateTime.now();

          // --- Notification logic: notify if within a week of nextDate ---
          for (final v in vaccinations) {
            if (v['nextDate'] != null) {
              final nextDate = (v['nextDate'] as Timestamp).toDate();
              final days = nextDate.difference(DateTime(now.year, now.month, now.day)).inDays;
              if (days >= 0 && days <= 7) {
                final key = '${v['type']}_${nextDate.toIso8601String()}';
                if (!_notifiedToday.contains(key)) {
                  _notifiedToday.add(key);
                  NotificationHelper.showDogOutNotification(
                    title: 'Vaccination Reminder',
                    body: 'Your dog needs ${v['type']} vaccination in $days day${days == 1 ? '' : 's'} (${_formatDate(nextDate)})',
                  );
                }
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                              final nextDate = (v['nextDate'] as Timestamp).toDate();
                                              final now = DateTime.now();
                                              return nextDate.isAfter(now) && nextDate.difference(now).inDays <= 7;
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
                              children: vaccinations
                                  .map((v) => Column(
                                        children: [
                                          _buildVaccinationItem(
                                            type: v['type'],
                                            date: (v['date'] as Timestamp).toDate(),
                                            nextDate: (v['nextDate'] as Timestamp).toDate(),
                                            duration: v['duration'],
                                          ),
                                          const Divider(color: Color(0xFFF3F4F6)),
                                        ],
                                      ))
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
                                onPressed: () => _showAddVaccinationDialog(context),
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
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                  decoration: const InputDecoration(labelText: 'Duration (months)'),
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
}