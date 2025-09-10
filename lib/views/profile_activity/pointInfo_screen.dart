import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../controllers/point_controller.dart';
import '../../controllers/userinfo_screen_controller.dart';
import '../../routes/base_url.dart';
// ★ 프로젝트 구조에 맞게 경로 수정
import '../widget/avatar_cache_manager.dart';

class PointInfoScreen extends StatefulWidget {
  const PointInfoScreen({super.key});

  @override
  State<PointInfoScreen> createState() => _PointInfoScreenState();
}

class _PointInfoScreenState extends State<PointInfoScreen> {
  // ──────────────────────────────
  // 기본 상태
  // ──────────────────────────────
  String selectedTab = 'total'; // 'total' | 'scheduled'
  final PointController _pointController = PointController();
  final UserInfoScreenController _controller = UserInfoScreenController();
  bool _initialLoading = true;      // 최초 전체 로딩
  bool _isLoadingMore = false;      // 다음 페이지 로딩 오버레이

  String? profileImage = '';
  final storage = const FlutterSecureStorage();
  String nickname = '';
  String? myUserId = '';
  int totalPoints = 0;

  // ──────────────────────────────
  // 포인트 데이터 (전체/노출)
  // ──────────────────────────────
  final int _pageSize = 15;
  int _loadedCount = 0;              // 지금까지 화면에 올린 개수
  bool _hasMore = true;              // 더 가져올 수 있는지
  List<dynamic> _allPoints = [];     // 서버 전체
  List<dynamic> _allScheduled = [];  // 서버 전체 중 소멸예정만
  List<dynamic> _visiblePoints = []; // 현재 탭 기준으로 노출 리스트

  // ──────────────────────────────
  // 스크롤
  // ──────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ──────────────────────────────
  // 아바타 캐시 유틸
  // ──────────────────────────────
  String _avatarCacheKeyFor({String? userId, String? nickname}) {
    final base = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim()
        : (nickname ?? 'unknown');
    return 'avatar_$base';
  }

  Future<void> _warmAvatarCache(String url, String key) async {
    try {
      await AvatarCacheManager.instance.getSingleFile(url, key: key); // 디스크 캐시
      await precacheImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: AvatarCacheManager.instance,
          cacheKey: key,
        ),
        context, // 메모리 캐시 (다음 빌드 즉시 표시)
      );
    } catch (_) {}
  }

  // ──────────────────────────────
  // 프로필 URL 빌더 (S3/절대/상대 경로 모두 처리)
  // ──────────────────────────────
  String _sanitizeAbsoluteProfile(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final httpsIdx = value.indexOf('https://');
    if (httpsIdx > 0) return value.substring(httpsIdx);
    final httpIdx = value.indexOf('http://');
    if (httpIdx > 0) return value.substring(httpIdx);
    return value;
  }

  String? _buildProfileImageUrl(dynamic raw) {
    if (raw == null) return null;
    final s0 = raw.toString().trim();
    if (s0.isEmpty) return null;

    String out;
    if (s0.startsWith('http://') || s0.startsWith('https://')) {
      out = _sanitizeAbsoluteProfile(s0); // 절대 URL (S3 포함)
    } else if (s0.startsWith('/uploads/')) {
      out = '${BaseUrl.value}:7778$s0';
    } else {
      // 서버 media 키 기반 (파일키/상대경로)
      out = '${BaseUrl.value}:7778/media/${Uri.encodeComponent(s0)}';
    }

    debugPrint('[PointInfo] raw profileImage: $s0');
    debugPrint('[PointInfo] resolved imageUrl: $out');
    return out;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAll();       // 전체(once) 가져옴
    _loadUserInfo();  // 헤더 유저 정보 + 아바타 캐시 프리워밍
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ──────────────────────────────
  // 데이터 로드
  // ──────────────────────────────
  Future<void> _loadAll() async {
    setState(() => _initialLoading = true);

    try {
      final userId = await storage.read(key: 'userId');
      final token  = await storage.read(key: 'token');
      if (userId == null || token == null) {
        setState(() => _initialLoading = false);
        return;
      }

      // 총합
      totalPoints = await _pointController.fetchUserTotalPoints(userId);

      // 포인트 내역 (서버가 페이징 없다는 가정: 전체를 받아 로컬 페이징)
      final res = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/points/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = List<dynamic>.from(data['points'] ?? []);
        // 최신순 정렬 가정(서버가 이미 정렬해주면 생략 가능)
        list.sort((a, b) {
          final sa = (a['createdAt'] ?? '') as String;
          final sb = (b['createdAt'] ?? '') as String;
          return sb.compareTo(sa);
        });

        _allPoints = list;
        _allScheduled = list.where((e) {
          final exp = e['expired_at'];
          return exp != null && exp.toString().isNotEmpty;
        }).toList();

        _resetAndShowFirstPage(); // 현재 탭 기준으로 1페이지 세팅
      }
    } catch (_) {
      // 필요시 에러 로그
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      myUserId = await storage.read(key: 'userId');
      await _controller.fetchUserInfo(context);
      setState(() {
        nickname = _controller.nickname;
        profileImage = _controller.profileImage;
      });

      // 프로필 이미지 프리워밍
      final url = _buildProfileImageUrl(profileImage);
      if (url != null && url.isNotEmpty) {
        final key = _avatarCacheKeyFor(userId: myUserId, nickname: nickname);
        _warmAvatarCache(url, key);
      }
    } catch (_) {}
  }

  // ──────────────────────────────
  // 페이징 헬퍼
  // ──────────────────────────────
  void _resetAndShowFirstPage() {
    _visiblePoints.clear();
    _loadedCount = 0;
    _hasMore = true;
    _appendNextPage();
  }

  List<dynamic> _currentSource() {
    return (selectedTab == 'scheduled') ? _allScheduled : _allPoints;
  }

  void _appendNextPage() {
    final source = _currentSource();
    if (_loadedCount >= source.length) {
      _hasMore = false;
      return;
    }
    final nextEnd = (_loadedCount + _pageSize > source.length)
        ? source.length
        : _loadedCount + _pageSize;

    _visiblePoints.addAll(source.sublist(_loadedCount, nextEnd));
    _loadedCount = nextEnd;
    _hasMore = _loadedCount < source.length;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _initialLoading) return;
    setState(() => _isLoadingMore = true);

    // 서버 재호출 없이 로컬 페이징 (UX를 위해 약간의 지연을 줄 수도 있음)
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      _appendNextPage();
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final threshold = 250.0; // 바닥 250px 남았을 때 다음 로드
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMore();
    }
  }

  // ──────────────────────────────
  // UI
  // ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    final String? imageUrl = _buildProfileImageUrl(profileImage);
    final String cacheKey =
    _avatarCacheKeyFor(userId: myUserId, nickname: nickname);

    // 최초 로딩(전체)
    if (_initialLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const BackButton(color: Colors.black),
          centerTitle: true,
          title: const Text(
            '현재 포인트 내역',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '현재 포인트 내역',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 본문
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // 상단 카드
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1121), Color(0xFF0D1121)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6.r, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 이미지 + 닉네임
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFFFF5722), offset: Offset(2, -2), blurRadius: 0, spreadRadius: 0),
                                BoxShadow(color: Color(0xFFC622FF), offset: Offset(-2, 2), blurRadius: 0, spreadRadius: 0),
                              ],
                            ),
                            child: ClipOval(
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                cacheManager: AvatarCacheManager.instance,
                                cacheKey: cacheKey,
                                useOldImageOnUrlChange: true,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                placeholderFadeInDuration: Duration.zero,
                                memCacheWidth: 40 * 3,
                                memCacheHeight: 40 * 3,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => _defaultProfileIcon(),
                              )
                                  : _defaultProfileIcon(),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '$nickname 님',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // 잔여 포인트
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('현재 잔여 포인트', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                          Text(
                            '${NumberFormat('#,###').format(totalPoints)} P',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // 탭 선택
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (selectedTab == 'total') return;
                            setState(() {
                              selectedTab = 'total';
                              _resetAndShowFirstPage();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: selectedTab == 'total' ? Theme.of(context).primaryColor : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '현재 포인트 내역',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedTab == 'total' ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (selectedTab == 'scheduled') return;
                            setState(() {
                              selectedTab = 'scheduled';
                              _resetAndShowFirstPage();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: selectedTab == 'scheduled' ? Theme.of(context).primaryColor : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '소멸예정 포인트',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedTab == 'scheduled' ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // 리스트
                _buildPointList(),
                SizedBox(height: 24.h),

                // 바닥 여백 + 더 없음 표시
                if (!_hasMore && _visiblePoints.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: Text(
                      '더 이상 내역이 없습니다',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                    ),
                  ),
              ],
            ),
          ),

          // 다음 페이지 로딩 오버레이 (반투명 배경 + 프라이머리 컬러 인디케이터)
          if (_isLoadingMore)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25), // 반투명 배경
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────
  // 리스트 위젯
  // ──────────────────────────────
  Widget _buildPointList() {
    if (selectedTab == 'scheduled' && _currentSource().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            '소멸예정 포인트가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _visiblePoints.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) {
        final item = _visiblePoints[i];
        final amount = int.tryParse(item['amount'].toString()) ?? 0;
        final isPlus = item['type'] == '추가' || item['type'] == '환불';

        final formattedAmount = NumberFormat('#,###').format(amount.abs());
        final createdAt = item['createdAt']?.toString() ?? '';
        final formattedDate = createdAt.isNotEmpty
            ? createdAt.substring(0, 19).replaceAll('T', ' ')
            : '';

        final String? expiredAt = item['expired_at'];
        String expiredText = '';
        if (selectedTab == 'scheduled' && expiredAt != null && expiredAt.isNotEmpty) {
          expiredText = '소멸 예정일: ${expiredAt.substring(0, 10)}';
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['description'] ?? '-', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              if (expiredText.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(expiredText, style: TextStyle(fontSize: 12.sp, color: Colors.red)),
              ],
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                  Text(
                    '${isPlus ? '+' : '-'}$formattedAmount P',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isPlus ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────
  // 기본 프로필 아이콘
  // ──────────────────────────────
  Widget _defaultProfileIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Colors.grey, size: 24),
    );
  }
}
