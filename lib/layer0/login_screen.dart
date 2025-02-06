// import packages
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import files

class CoinResortLoginScreen extends StatefulWidget {
  const CoinResortLoginScreen({super.key});

  @override
  State<CoinResortLoginScreen> createState() => _CoinResortLoginScreenState();
}

class _CoinResortLoginScreenState extends State<CoinResortLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _nativeGoogleSignIn() async {
    try {
      await dotenv.load(
          fileName:
              "/Users/haksunlee/CraneSunCompany/CoinResort/cr_frontend/.env");

      String webClientId = dotenv.env['WEBCLIENT_ID']!;
      String iosClientId = dotenv.env['IOSCLIENT_ID']!;

      final GoogleSignIn googleSignIn =
          GoogleSignIn(clientId: iosClientId, serverClientId: webClientId);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In cancelled.';
      }

      if (!mounted) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw 'Failed to obtain Google auth tokens.';
      }

      if (!mounted) return;

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final userId = response.user?.id;
      if (userId != null) {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        if (profileResponse.isEmpty) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/signup');
        }
      }
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } on Exception catch (error) {
      context.showErrorSnackBar(
          message: 'An unexpected error occurred: $error');
      debugPrintStack(label: 'Sign-in Error', stackTrace: StackTrace.current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2EC4B6), // Mint Green
              Color(0xFFFF7F50), // Sunset Orange
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      // 이미지를 중앙에 배치
                      child: SizedBox(
                        width: 120, // 컨테이너의 절반 크기
                        height: 120, // 컨테이너의 절반 크기
                        child: Image.asset('asset/coin_resort_logo.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    'Coin Resort',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "암호화폐 투자자들의 리조트",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "⚡🔥 실시간 토론으로 황금 기회를 잡아라 💰🚀",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Google Sign In Button
                  ElevatedButton(
                    onPressed: _nativeGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 45, // 좌우 여백 증가
                        vertical: 18, // 상하 여백 증가
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35), // 더 부드러운 곡선
                      ),
                      elevation: 3, // 그림자 효과 감소로 모던한 느낌
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'asset/google_logo.png',
                          height: 28, // 로고 크기 증가
                        ),
                        const SizedBox(width: 15), // 간격 증가
                        const Text(
                          'Google로 로그인',
                          style: TextStyle(
                            fontSize: 17, // 폰트 크기 증가
                            fontWeight: FontWeight.bold, // 두께 조정
                            letterSpacing: 0.5, // 자간 추가
                            color: Color(0xFFFF7F50), // 텍스트 색상 명시
                          ),
                        ),
                      ],
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

extension ShowErrorSnackBar on BuildContext {
  void showErrorSnackBar({required String message}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
