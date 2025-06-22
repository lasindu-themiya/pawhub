import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/notification_helper.dart';
import '../services/firestore_service.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  bool _notifiedHigh = false;
  bool _notifiedLow = false;
  bool _notifiedDanger = false;

  void _checkAndNotify(double temp) {
    final status = _getTemperatureStatus(temp);
    if (status['status'] == 'Dangerously High' && !_notifiedDanger) {
      _notifiedDanger = true;
      _notifiedHigh = false;
      _notifiedLow = false;
      NotificationHelper.showDogOutNotification(
        title: 'Dangerously High Temperature!',
        body: '🚨 Your dog\'s temperature is dangerously high: $temp°C',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚨 Dangerously high temperature: $temp°C'),
              backgroundColor: Colors.deepOrange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } else if (status['status'] == 'High' && !_notifiedHigh) {
      _notifiedHigh = true;
      _notifiedLow = false;
      _notifiedDanger = false;
      NotificationHelper.showDogOutNotification(
        title: 'High Temperature Alert',
        body: '⚠️ Your dog\'s temperature is high: $temp°C',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ High temperature detected: $temp°C'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else if (status['status'] == 'Low' && !_notifiedLow) {
      _notifiedLow = true;
      _notifiedHigh = false;
      _notifiedDanger = false;
      NotificationHelper.showDogOutNotification(
        title: 'Low Temperature Alert',
        body: '⚠️ Your dog\'s temperature is low: $temp°C',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Low temperature detected: $temp°C'),
              backgroundColor: Colors.blueAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else if (status['status'] == 'Normal') {
      _notifiedHigh = false;
      _notifiedLow = false;
      _notifiedDanger = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<double?>(
        stream: FirestoreService.streamCurrentTemperature(),
        builder: (context, snapshot) {
          final temp = snapshot.data ?? 0.0;
          final tempStatus = _getTemperatureStatus(temp);

          if (snapshot.hasData) {
            _checkAndNotify(temp);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'Health Monitor',
                          style: TextStyle(
                            fontSize: 36,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track your pet\'s temperature',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Color(0xCCFFFFFF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
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
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: tempStatus['color']!.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.thermostat,
                            size: 48,
                            color: tempStatus['color'],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          temp > 0 ? '$temp°C' : '--',
                          style: const TextStyle(
                            fontSize: 40,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tempStatus['icon'],
                              size: 20,
                              color: tempStatus['color'],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tempStatus['status']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: tempStatus['color'],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().scale(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getTemperatureStatus(double temp) {
    if (temp > 41.1) {
      return {
        'status': 'Dangerously High',
        'color': const Color.fromARGB(255, 109, 2, 2),
        'icon': Icons.warning_amber_rounded,
      };
    }
    if (temp > 39.4) {
      return {
        'status': 'High',
        'color': const Color(0xFFEF4444),
        'icon': Icons.trending_up,
      };
    }
    if (temp < 37.2) {
      return {
        'status': 'Low',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.trending_down,
      };
    }
    return {
      'status': 'Normal',
      'color': const Color(0xFF22C55E),
      'icon': Icons.check_circle,
    };
  }
}