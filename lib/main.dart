// import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cr_frontend/layer0/homepage_screen.dart';
import 'package:cr_frontend/layer0/login_screen.dart';
import 'package:cr_frontend/layer0/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CoinResortApp());
}

class CoinResortApp extends StatelessWidget {
  const CoinResortApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Coin Resort',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2EC4B6),
          secondary: Color(0xFFFF7F50),
        ),
      ),
      home: isLoggedIn
          ? const CoinResortHomePage()
          : const CoinResortLoginScreen(),
      routes: {
        '/home': (context) => const CoinResortHomePage(),
        '/login': (context) => const CoinResortLoginScreen(),
        '/signup': (context) => const CoinResortSignupScreen(),
      },
    );
  }
}
