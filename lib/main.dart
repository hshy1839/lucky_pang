import 'dart:async';
import 'dart:io';

import 'package:attedance_app/routes/app_routes.dart';
import 'package:attedance_app/views/luckybox_acitivity/luckyBoxPurchase_screen.dart';
import 'package:attedance_app/views/luckybox_acitivity/ranking_activity/ranking_screen.dart';
import 'package:attedance_app/views/main_activity/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
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


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true, // 안정적
    resetOnError: true,               // BAD_DECRYPT 등 나면 자동 리셋
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  KakaoSdk.init(
    nativeAppKey: 'a428d1d9ce58d6f01884573a8a801131',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => BoxController()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _startApp();
  }


  Future<void> _startApp() async {
    setState(() => _startScreen = const SplashScreen());
    await Future.delayed(const Duration(seconds: 2)); // 2초 대기
    final Widget next = await _checkLoginStatus();
    setState(() => _startScreen = next);
  }
  Future<String?> safeRead(String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException {
      // 복호화 실패 시(=지금 겪는 케이스) 전체 리셋 후 null 반환
      await storage.deleteAll();
      return null;
    } catch (_) {
      return null;
    }
  }
  Future<Widget> _checkLoginStatus() async {
    final isLoggedIn = (await safeRead('isLoggedIn')) == 'true';
    final token = await safeRead('token');

    if (isLoggedIn && token != null && token.isNotEmpty) {
      return MainScreenWithFooter();
    }
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 0.8),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'luckytang',
        theme: ThemeData(
          primaryColor: const Color(0xFFF24E1E),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'pretendard-regular',
          ),
        ),
        home: _startScreen ?? const SplashScreen(),
        routes: AppRoutes.routes,
        onGenerateRoute: (settings) {
          if (settings.name == '/main') {
            final args = settings.arguments as Map<String, dynamic>?;
            final index = args?['initialTabIndex'] ?? 0;
            return MaterialPageRoute(
              builder: (_) => MainScreenWithFooter(initialTabIndex: index),
            );
          }
          return null;
        },
      ),
    );
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
    final List<Widget> pages = [
      MainScreen(onTabTapped: _onTabTapped),
      RankingScreen(),
      OrderScreen(pageController: _pageController, onTabChanged: _onTabTapped),
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
