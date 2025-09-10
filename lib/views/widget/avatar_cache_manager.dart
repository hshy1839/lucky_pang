// avatar_cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AvatarCacheManager {
  static final CacheManager instance = CacheManager(
    Config(
      'avatarCache',
      stalePeriod: const Duration(days: 30), // 디스크 캐시 30일
      maxNrOfCacheObjects: 20,
    ),
  );
}
