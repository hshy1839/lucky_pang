import 'dart:io';

import 'package:attedance_app/routes/app_routes.dart';
import 'package:attedance_app/views/luckybox_acitivity/luckyBoxPurchase_screen.dart';
import 'package:attedance_app/views/luckybox_acitivity/ranking_activity/ranking_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// 화면들 import
import 'package:attedance_app/views/login_activity/login.dart';
import 'package:attedance_app/views/main_activity/main_screen.dart';
import 'package:attedance_app/views/profile_activity/profile_screen.dart';
import 'controllers/box_controller.dart';
import 'controllers/login/signup_controller.dart';
import 'firebase_options.dart';
import 'footer.dart';
import 'views/order_activity/order_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

   Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  KakaoSdk.init(nativeAppKey: '89857ed78c6e2c92bab47311bbea5546', loggingEnabled: true);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => BoxController()),
        // 필요한 Provider 더 추가 가능
      ],

      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'luckytang',
      theme: ThemeData(
        primaryColor: const Color(0xFFF24E1E),
        useMaterial3: true, // Material3 사용하는 경우도 대응
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          // ✅ AppBar 배경색 고정
          elevation: 0,
          // ✅ 그림자 제거
          centerTitle: true,
          surfaceTintColor: Colors.white,
          // ✅ Material 3 대응
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: ThemeData
            .light()
            .textTheme
            .apply(
          fontFamily: 'pretendard-regular',
        ),
      ),
      home: _determineInitialScreen(),
      routes: AppRoutes.routes,
    );
  }


  Widget _determineInitialScreen() {
    return FutureBuilder<Widget>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error occurred'));
        } else {
          // 로그인 상태에 맞는 화면 반환
          if (snapshot.data is LoginScreen) {
            return LoginScreen(); // 로그인 화면 반환
          } else {
            return MainScreenWithFooter(); // 로그인 후 메인 화면
          }
        }
      },
    );
  }

  Future<Widget> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final token = prefs.getString('token'); // 토큰을 확인

    // 로그인 안 된 경우 로그인 화면
    if (!isLoggedIn || token == null) {
      return LoginScreen();
    }
    return MainScreenWithFooter(); // 로그인 후 메인 화면
  }
}

class MainScreenWithFooter extends StatefulWidget {
  final int initialTabIndex;

  const MainScreenWithFooter({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _MainScreenWithFooterState createState() => _MainScreenWithFooterState();
}

class _MainScreenWithFooterState extends State<MainScreenWithFooter> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(_currentIndex);
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 여기서 pages 리스트를 빌드 타이밍에 생성
    final List<Widget> pages = [
      MainScreen(onTabTapped: _onTabTapped, ),

      RankingScreen(),
      OrderScreen(pageController: _pageController,
        onTabChanged: _onTabTapped,),
      ProfileScreen(),
      LuckyBoxPurchasePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: pages,
        ),
      ),
      bottomNavigationBar:
      Footer(onTabTapped: _onTabTapped, selectedIndex: _currentIndex),
    );
  }
}

