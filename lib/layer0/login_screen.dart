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
    if (!mounted) return;

    try {
      await dotenv.load(fileName: ".env");
      final webClientId = dotenv.env['WEBCLIENT_ID'];
      final iosClientId = dotenv.env['IOSCLIENT_ID'];

      if (webClientId == null || iosClientId == null) {
        throw '클라이언트 ID가 설정되지 않았습니다.';
      }

      final googleUser = await GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      ).signIn();

      if (googleUser == null) throw '구글 로그인이 취소되었습니다.';

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw '구글 인증 토큰을 가져오는데 실패했습니다.';
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user?.id != null) {
        try {
          Navigator.pushReplacementNamed(context, '/home');
        } catch (_) {
          Navigator.pushReplacementNamed(context, '/signup');
        }
      }
    } catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(
        message: error is AuthException
            ? '인증 오류: ${error.message}'
            : '오류가 발생했습니다: $error',
      );
      debugPrint('로그인 오류: $error');
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
