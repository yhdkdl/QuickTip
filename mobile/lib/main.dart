import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/router.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const QuickTipApp(),
    ),
  );
}

class QuickTipApp extends StatefulWidget {
  const QuickTipApp({super.key});

  @override
  State<QuickTipApp> createState() => _QuickTipAppState();
}

class _QuickTipAppState extends State<QuickTipApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(
      context.read<AuthProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.surface,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.brandGreen,
          surface: AppConstants.surface,
        ),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
          bodyMedium: TextStyle(color: Color(0xFFA0A0A0)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
