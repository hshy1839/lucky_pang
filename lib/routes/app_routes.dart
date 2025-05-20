import 'package:attedance_app/main.dart';
import 'package:attedance_app/views/luckybox_acitivity/luckyBoxOrder.dart';
import 'package:attedance_app/views/main_activity/error_screen.dart';
import 'package:attedance_app/views/order_activity/delivery_request_screen.dart';
import 'package:attedance_app/views/setting_activity/event_activity/event_detail_screen.dart';
import 'package:attedance_app/views/setting_activity/terms_activity/purchaseTerm_screen.dart';
import 'package:attedance_app/views/setting_activity/terms_activity/refundTerm_screen.dart';
import 'package:flutter/material.dart';
import '../views/login_activity/login.dart';
import '../views/login_activity/signup.dart';
import '../views/login_activity/findEmail_screen.dart';
import '../views/login_activity/findPassword_screen.dart';
import '../views/login_activity/singup_agree_screen.dart';
import '../views/luckybox_acitivity/createGiftCode_screen.dart';
import '../views/main_activity/main_screen.dart';
import '../views/setting_activity/event_activity/event_screen.dart';
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
import '../views/setting_activity/terms_activity/setting_screen.dart';
import '../views/setting_activity/terms_activity/privacy_screen.dart';
import '../views/setting_activity/terms_activity/terms_screen.dart';
import '../views/setting_activity/QnA_activity/qna_screen.dart';
import '../views/setting_activity/QnA_activity/qna_create_screen.dart';
import '../views/setting_activity/faq_screen.dart';
import '../views/shopping_screen/shopping_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    '/main': (_) => MainScreenWithFooter(),
    '/login': (_) => LoginScreen(),
    '/signup': (_) => SignUpScreen(),
    '/signupAgree': (_) => SignupAgreeScreen(),
    '/findEmail': (_) => FindEmailScreen(),
    '/findPassword': (_) => FindPasswordScreen(),
    '/notice': (_) => NoticeScreen(),
    '/event': (_) => EventScreen(),
    '/qna': (_) => QnaScreen(),
    '/qnaCreate': (_) => QnaCreateScreen(),
    '/accountInfo': (_) => AccountScreen(),
    '/luckyboxOrder': (_) => LuckyBoxOrderPage(),
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
    '/error': (_) => ErrorScreen(),
    '/purchase_term': (_) => PurchasetermScreen(),
    '/refund_term': (_) => RefundTermScreen(),
    '/giftcode/create': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CreateGiftCodeScreen(boxId: args['boxId'], orderId:  args['orderId'], productId: args['productId'], type: args['type'],);
    },
    '/serviceTerm': (_) => TermsOfServicePage(),
    '/faq': (_) => FaqScreen(),
    '/searchProduct': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
      return SearchProductScreen(searchQuery: args?['query'] ?? '');
    },
    '/shoppingscreen': (context) {
      final category = ModalRoute.of(context)!.settings.arguments as String? ?? '카테고리 없음';
      return ShoppingScreen(category: category);
    },
    '/deliveryscreen': (_) => DeliveryRequestScreen(),
  };
}
