// import packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
// import files
import 'package:cr_frontend/layer1/cointhumbnail_screen.dart';
import 'package:cr_frontend/layer1/feed_screen.dart';
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
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined, // 알림 아이콘
                color: Colors.white,
                size: 26,
              ),
              splashRadius: 24,
              onPressed: () {
                // 알림 기능
              },
            ),
            IconButton(
              padding: EdgeInsets.zero, // leading 영역에 2개 아이콘을 넣기 위해 패딩 제거
              icon: const Icon(
                Icons.favorite_outline, // 즐겨찾기 아이콘
                color: Colors.white,
                size: 26,
              ),
              splashRadius: 24,
              onPressed: () {
                // 즐겨찾기 기능
              },
            ),
          ],
        ),
        leadingWidth: 96, // 왼쪽 아이콘 2개를 위한 공간 확보
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'asset/coin_resort_logo.svg',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Coin Resort',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
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
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 26,
            ),
            splashRadius: 24,
            onPressed: () {
              // 검색 기능
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 26,
            ),
            splashRadius: 24,
            onPressed: () {
              // 메뉴 기능
            },
          ),
          const SizedBox(width: 4),
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
                  label: "피드",
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
}
