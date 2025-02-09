import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  String introduce = dotenv.env['INTRODUCE'] ?? "";

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
}
