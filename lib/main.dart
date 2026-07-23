import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/local/database_helper.dart';
import 'data/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _seedDemoUsers();
  runApp(const ProviderScope(child: MyApp()));
}

/// Create demo accounts on first run
Future<void> _seedDemoUsers() async {
  final db = DatabaseHelper();
  final existing = await db.getUserByEmail('demo@gmail.com');
  if (existing == null) {
    await db.insertUser(
      const UserModel(id: 'user-demo', email: 'demo@gmail.com', name: 'Demo User'),
      '123456',
    );
    await db.insertUser(
      const UserModel(id: 'user-admin', email: 'admin@gmail.com', name: 'Admin', role: 'admin'),
      '123456',
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'PC Parts Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

