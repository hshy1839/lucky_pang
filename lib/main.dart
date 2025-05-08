import 'package:attedance_app/routes/app_routes.dart';
import 'package:attedance_app/views/login_activity/findEmail_screen.dart';
import 'package:attedance_app/views/login_activity/findPassword_screen.dart';
import 'package:attedance_app/views/login_activity/singup_agree_screen.dart';
import 'package:attedance_app/views/luckybox_acitivity/luckyBoxPurchase_screen.dart';
import 'package:attedance_app/views/luckybox_acitivity/ranking_activity/ranking_screen.dart';
import 'package:attedance_app/views/main_activity/account_screen.dart';
import 'package:attedance_app/views/main_activity/cart_detail_screen.dart';
import 'package:attedance_app/views/main_activity/2order_screen.dart';
import 'package:attedance_app/views/setting_activity/QnA_activity/qna_create_screen.dart';
import 'package:attedance_app/views/setting_activity/QnA_activity/qna_screen.dart';
import 'package:attedance_app/views/main_activity/search_product_screen.dart';
import 'package:attedance_app/views/main_activity/userinfo_detail_screen.dart';
import 'package:attedance_app/views/profile_activity/coupon_code_screen.dart';
import 'package:attedance_app/views/profile_activity/friends_recommand_screen.dart';
import 'package:attedance_app/views/profile_activity/gift_code_screen.dart';
import 'package:attedance_app/views/profile_activity/pointInfo_screen.dart';
import 'package:attedance_app/views/profile_activity/shipping_activity/shipping_create_screen.dart';
import 'package:attedance_app/views/profile_activity/shipping_activity/shipping_info_screen.dart';
import 'package:attedance_app/views/setting_activity/faq_screen.dart';
import 'package:attedance_app/views/setting_activity/privacy_screen.dart';
import 'package:attedance_app/views/setting_activity/setting_screen.dart';
import 'package:attedance_app/views/setting_activity/terms_screen.dart';
import 'package:attedance_app/views/shopping_screen/shopping_screen.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// 화면들 import
import 'package:attedance_app/views/login_activity/login.dart';
import 'package:attedance_app/views/login_activity/signup.dart';
import 'package:attedance_app/views/main_activity/main_screen.dart';
import 'package:attedance_app/views/setting_activity/notice_activity/notice_screen.dart';
import 'package:attedance_app/views/profile_activity/profile_screen.dart';
import 'package:attedance_app/views/main_activity/2order_detail_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'controllers/box_controller.dart';
import 'controllers/login/signup_controller.dart';
import 'footer.dart';
import 'views/order_activity/order_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  KakaoSdk.init(nativeAppKey: 'b45a934bfd09b6d5513a4080c9bf7990');
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
  @override
  _MainScreenWithFooterState createState() => _MainScreenWithFooterState();
}

class _MainScreenWithFooterState extends State<MainScreenWithFooter> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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
      MainScreen(),
      RankingScreen(),
      OrderScreen(pageController: _pageController,
        onTabChanged: _onTabTapped,),
      ProfileScreen(),
      LuckyBoxPurchasePage(),
    ];

    return Scaffold(
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

