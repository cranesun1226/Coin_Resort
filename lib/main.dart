// import packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import files
import 'package:cr_frontend/layer0/homepage_screen.dart';
import 'package:cr_frontend/layer0/login_screen.dart';
import 'package:cr_frontend/layer0/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(
        fileName:
            "/Users/haksunlee/CraneSunCompany/CoinResort/cr_frontend/.env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    runApp(const CoinResortApp());
  } catch (e) {
    if (kDebugMode) {
      print('Error loading .env file or initializing Supabase: $e');
    }
  }
}

class CoinResortApp extends StatefulWidget {
  const CoinResortApp({super.key});

  @override
  State<CoinResortApp> createState() => _CoinResortAppState();
}

class _CoinResortAppState extends State<CoinResortApp> {
  bool _isAuthenticating = true;
  Widget? _homeScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _isAuthenticating = false;
      _homeScreen = session != null
          ? const CoinResortHomePage()
          : const CoinResortLoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const MaterialApp(
          home: Center(child: CircularProgressIndicator()));
    }

    final ThemeData theme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
          primary: Color(0xFF2EC4B6), secondary: Color(0xFFFF7F50)),
    );

    return MaterialApp(
      title: 'Coin Resort',
      theme: theme,
      home: _homeScreen,
      routes: {
        '/home': (context) => const CoinResortHomePage(),
        '/login': (context) => const CoinResortLoginScreen(),
        '/signup': (context) => const CoinResortSignupScreen(),
      },
    );
  }
}
