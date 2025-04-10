import 'package:flutter/material.dart';
import '../views/login_activity/login.dart';
import '../views/login_activity/signup.dart';
import '../views/login_activity/findEmail_screen.dart';
import '../views/login_activity/findPassword_screen.dart';
import '../views/login_activity/singup_agree_screen.dart';
import '../views/main_activity/main_screen.dart';
import '../views/setting_activity/notice_activity/notice_screen.dart';
import '../views/main_activity/search_product_screen.dart';
import '../views/main_activity/userinfo_detail_screen.dart';
import '../views/main_activity/2order_screen.dart';
import '../views/main_activity/2order_detail_screen.dart';
import '../views/main_activity/account_screen.dart';
import '../views/main_activity/cart_detail_screen.dart';
import '../views/order_activity/order_screen.dart';
import '../views/profile_activity/pointInfo_screen.dart';
import '../views/profile_activity/coupon_code_screen.dart';
import '../views/profile_activity/gift_code_screen.dart';
import '../views/profile_activity/friends_recommand_screen.dart';
import '../views/profile_activity/shipping_activity/shipping_info_screen.dart';
import '../views/profile_activity/shipping_activity/shipping_create_screen.dart';
import '../views/setting_activity/setting_screen.dart';
import '../views/setting_activity/privacy_screen.dart';
import '../views/setting_activity/terms_screen.dart';
import '../views/setting_activity/QnA_activity/qna_screen.dart';
import '../views/setting_activity/QnA_activity/qna_create_screen.dart';
import '../views/setting_activity/faq_screen.dart';
import '../views/shopping_screen/shopping_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    '/login': (_) => LoginScreen(),
    '/signup': (_) => SignUpScreen(),
    '/signupAgree': (_) => SignupAgreeScreen(),
    '/findEmail': (_) => FindEmailScreen(),
    '/findPassword': (_) => FindPasswordScreen(),
    '/notice': (_) => NoticeScreen(),
    '/qna': (_) => QnaScreen(),
    '/qnaCreate': (_) => QnaCreateScreen(),
    '/accountInfo': (_) => AccountScreen(),
    '/userinfo': (_) => UserDetailScreen(),
    '/cart': (_) => CartDetailScreen(),
    '/order': (_) => OrderScreen(),
    '/2orderdetail': (_) => aOrderDetailScreen(),
    '/pointInfo': (_) => PointInfoScreen(),
    '/couponCode': (_) => CouponCodeScreen(),
    '/giftCode': (_) => GiftCodeScreen(),
    '/recommend': (_) => FriendsRecommendScreen(),
    '/shippingInfo': (_) => ShippingInfoScreen(),
    '/shippingCreate': (_) => ShippingCreateScreen(),
    '/setting': (_) => SettingScreen(),
    '/privacy': (_) => PrivacyScreen(),
    '/terms': (_) => TermsOfServicePage(),
    '/faq': (_) => FaqScreen(),
    '/searchProduct': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
      return SearchProductScreen(searchQuery: args?['query'] ?? '');
    },
    '/shoppingscreen': (context) {
      final category = ModalRoute.of(context)!.settings.arguments as String? ?? '카테고리 없음';
      return ShoppingScreen(category: category);
    },
    '/2order': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null || args['items'] == null || args['items'].isEmpty) {
        return Scaffold(body: Center(child: Text('잘못된 접근입니다')));
      }

      final firstItem = args['items'][0] as Map<String, dynamic>;
      final productId = firstItem['productId'] ?? '';
      final sizes = (firstItem['sizes'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
      final totalAmount = firstItem['totalPrice'] ?? 0;

      return aOrderScreen(productId: productId, sizes: sizes, totalAmount: totalAmount);
    },
  };
}
