import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:asisten_keuangan/firebase_options.dart';
import 'package:asisten_keuangan/core/services/firebase_app_check_service.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/dashboard/presentation/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheckService().activate();
  } catch (e, stackTrace) {
    developer.log('Firebase initialization warning: $e', stackTrace: stackTrace);
  }

  runApp(
    const ProviderScope(
      child: AsistenKeuanganApp(),
    ),
  );
}

class AsistenKeuanganApp extends StatelessWidget {
  const AsistenKeuanganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asisten Keuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
