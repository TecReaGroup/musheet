import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/admin_api_client.dart';
import 'core/router.dart';
import 'shared/theme/admin_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the admin API client with the server URL
  // In production, this would come from environment variables
  AdminApiClient.initialize(
    baseUrl: const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );

  runApp(
    const ProviderScope(
      child: AdminApp(),
    ),
  );
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MuSheet Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme,
      routerConfig: router,
    );
  }
}
