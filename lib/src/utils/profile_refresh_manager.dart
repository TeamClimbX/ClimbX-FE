import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// 프로필 새로고침 상태를 관리하는 싱글톤 클래스
/// 사용자 이벤트 발생 시 프로필 새로고침 필요 여부를 플래그로 관리
class ProfileRefreshManager {
  static final ProfileRefreshManager _instance = ProfileRefreshManager._internal();
  factory ProfileRefreshManager() => _instance;
  ProfileRefreshManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _needsRefreshKey = 'profile_needs_refresh';
  static const String _lastRefreshTimeKey = 'profile_last_refresh_time';

  /// 프로필 새로고침이 필요한지 확인
  Future<bool> needsRefresh() async {
    try {
      final needsRefreshStr = await _storage.read(key: _needsRefreshKey);
      final needsRefresh = needsRefreshStr == 'true';
      developer.log('프로필 새로고침 필요 여부: $needsRefresh', name: 'ProfileRefreshManager');
      return needsRefresh;
    } catch (e) {
      developer.log('새로고침 필요 여부 확인 실패: $e', name: 'ProfileRefreshManager', error: e);
      return false;
    }
  }

  /// 프로필 새로고침 필요 플래그 설정
  Future<void> setNeedsRefresh(bool needs) async {
    try {
      await _storage.write(key: _needsRefreshKey, value: needs.toString());
      developer.log('프로필 새로고침 플래그 설정: $needs', name: 'ProfileRefreshManager');
    } catch (e) {
      developer.log('새로고침 플래그 설정 실패: $e', name: 'ProfileRefreshManager', error: e);
    }
  }

  /// 마지막 프로필 새로고침 시간 조회
  Future<DateTime?> getLastRefreshTime() async {
    try {
      final timestampStr = await _storage.read(key: _lastRefreshTimeKey);
      if (timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          final lastRefreshTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          developer.log('마지막 프로필 새로고침 시간: $lastRefreshTime', name: 'ProfileRefreshManager');
          return lastRefreshTime;
        }
      }
      return null;
    } catch (e) {
      developer.log('마지막 새로고침 시간 조회 실패: $e', name: 'ProfileRefreshManager', error: e);
      return null;
    }
  }

  /// 프로필 새로고침 완료 처리
  /// 플래그를 false로 설정하고 현재 시간을 마지막 새로고침 시간으로 저장
  Future<void> markRefreshed() async {
    try {
      final now = DateTime.now();
      
      await _storage.write(key: _needsRefreshKey, value: 'false');
      await _storage.write(key: _lastRefreshTimeKey, value: now.millisecondsSinceEpoch.toString());
      
      developer.log('프로필 새로고침 완료 처리: $now', name: 'ProfileRefreshManager');
    } catch (e) {
      developer.log('새로고침 완료 처리 실패: $e', name: 'ProfileRefreshManager', error: e);
    }
  }

  /// 5분이 경과했는지 확인
  Future<bool> isFiveMinutesElapsed() async {
    final lastRefreshTime = await getLastRefreshTime();
    if (lastRefreshTime == null) {
      return true; // 최초 실행시에는 새로고침 필요
    }
    
    final elapsed = DateTime.now().difference(lastRefreshTime).inMinutes >= 5;
    developer.log('5분 경과 여부: $elapsed (마지막 새로고침: $lastRefreshTime)', name: 'ProfileRefreshManager');
    return elapsed;
  }

  /// 프로필 새로고침이 필요한지 종합적으로 판단
  /// 플래그가 true이거나 5분이 경과했으면 새로고침 필요
  Future<bool> shouldRefresh() async {
    final needsFlag = await needsRefresh();
    final timeElapsed = await isFiveMinutesElapsed();
    final should = needsFlag || timeElapsed;
    
    developer.log('프로필 새로고침 필요 여부: $should (플래그: $needsFlag, 시간경과: $timeElapsed)', 
                  name: 'ProfileRefreshManager');
    return should;
  }
}