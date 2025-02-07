import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import files
import 'package:cr_frontend/layer1/cointhumbnail_screen.dart';
import 'package:cr_frontend/layer1/community_screen.dart';
import 'package:cr_frontend/layer1/myprofile_screen.dart';

class CoinResortHomePage extends StatefulWidget {
  const CoinResortHomePage({
    super.key,
  });

  @override
  CoinResortHomePageState createState() => CoinResortHomePageState();
}

class CoinResortHomePageState extends State<CoinResortHomePage> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    CoinThumbnailScreen(), // 코인 썸네일 화면
    FeedScreen(
      code: 'KRW-BTC',
    ), // 피드 화면
    MyProfileScreen(), // 프로필 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(8, 0, 0, 8),
              child: const Text(
                'Coin Resort',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
              alignment: Alignment.bottomCenter,
              child: SvgPicture.asset(
                'asset/coin_resort_logo.svg',
                width: 35, // IconButton과 같은 크기
                height: 35,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2EC4B6), Color(0xFFFF7F50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.4, 1.0],
            ),
          ),
        ),
        elevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: IconButton(
              icon: Icon(Icons.info, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: Text(introduce),
                      ),
                      actions: [
                        TextButton(
                          child: Text("닫기"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Main Body
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2EC4B6), Color(0xFFFF7F50)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pie_chart, size: 24),
                  ),
                  label: "코인",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.article, size: 24),
                  ),
                  label: "커뮤니티",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 24),
                  ),
                  label: "프로필",
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String introduce = """
안녕하세요, 코인 리조트 가족 여러분! 🌟

저는 "Coin Resort"를 만든 가난한 개발자입니다. 
그나마 있던 적은 돈도 코인으로 날려버리고, 
밤낮으로 코딩하며 ☀️🌙, 때론 커피 한 잔의 위안을 받으며 이 프로젝트를 키워왔습니다 ☕️

여러분과 함께하는 새로운 암호화폐 커뮤니티에 오신 것을
진심을 담아 환영합니다! 🚀

📱 현재의 코인 리조트
• 업비트 실시간 데이터 기반 전문 차트 분석
• 국내 Top 5 코인 실시간 모니터링 (BTC, ETH, XRP, DOGE, SOL)
• 여러 트레이더들과 실시간 토론
• 자신의 관점을 공유하는 커뮤니티
• 직관적인 UI로 누구나 쉽게 사용
• 여러분의 사랑으로 운영되는 안정적인 서버 💝

🎯 꿈과 약속
• Binance, Bybit 등 글로벌 거래소 통합
• TradingView 프리미엄 차트 도입
• 자체개발 AI 기반 맞춤형 투자 어시스턴트
• 대형 LLM 모델 도입
• 실시간 마켓 뉴스 알림
• 전문 투자자와의 1:1 멘토링
• 커스텀 알림 설정

💎 함께 성장하는 이야기
• 여러분의 의견을 반영한 업데이트
• 끊임없는 소통과 개선
• 열정적인 기술 지원

✨ 작은 도움의 손길이 큰 힘이 됩니다
• 따뜻한 앱스토어 리뷰 남기기 ⭐️
• 여러 코인 커뮤니티에 홍보해주기!
• 주변 친구들에게 소개하기

솔직히 말씀드리면, 아직은 부족한 점이 많습니다.
하지만 여러분의 매 클릭, 매 피드백이 저에게는 밤새 코딩할 수 있는 
에너지가 됩니다 💪

코인 리조트는 단순한 코인 커뮤니티 플랫폼을 넘어서,
여러분의 가장 가까운 트레이딩 동반자가 되고 싶습니다.
여러분의 모든 의견은 저에게 소중한 보물입니다 💫

이 작은 앱이 여러분의 투자 여정에 든든한 친구가 되길 바라며,
오늘도 열심히 개발하고 있습니다.
투자의 새로운 미래를 함께 만들어갈 
코인 리조트 가족이 되어주세요! 🤝

진심을 담아 감사드립니다 🙇‍♂️

#코인리조트 #암호화폐투자 #커뮤니티 #ToTheMoon

개발자 메일: cranesun1226@gmail.com
""";
}
