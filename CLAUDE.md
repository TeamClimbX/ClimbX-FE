# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
```bash
# Get dependencies
flutter pub get

# Generate code for Freezed/json_serializable
dart run build_runner build --delete-conflicting-outputs

# Run app in debug mode
flutter run \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"

# Run on specific device
flutter run -d "device-id" \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"

# Run iOS simulator
flutter run -d "iOS Simulator" \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"

# Run Android emulator  
flutter run -d "Android Emulator" \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"
```

### Build & Release
```bash
# Build iOS release
flutter build ios --release \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"

# Build Android APK
flutter build apk --release \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"

# Build Android App Bundle
flutter build appbundle --release \
  --dart-define=NAVER_MAP_CLIENT_ID="3u7pzbs2ft" \
  --dart-define=BASE_URL="https://dev.climbx.me" \
  --dart-define=KAKAO_NATIVE_APP_KEY="3a7eb659055f220167307cebdadc52f9" \
  --dart-define=APPLE_SERVICE_ID="com.example.climbxFe.service" \
  --dart-define=APPLE_APP_ID="com.example.climbxFe" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="798391464641-pa8167jo8eusga2qlc3snjcabmu2fs3v.apps.googleusercontent.com" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="798391464641-osbfon603i2bc1jfgeen24f4354tjc4c.apps.googleusercontent.com"
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Platform Tools
```bash
# iOS simulator
open -a Simulator

# Android emulator list
emulator -list-avds

# Android emulator run
emulator -avd [avd_name]
```

## Architecture Overview

This is a Flutter climbing analysis app following functional monadic patterns for API calls and clean architecture principles.

### Project Structure
```
lib/
├── main.dart                    # App entry point with SDK initialization
├── features/                    # Feature-based modules
│   └── gym_map/                # Naver Maps integration feature
└── src/
    ├── api/                    # API modules (functional monadic style)
    │   ├── util/               # API utilities (client, interceptors, error handling)
    │   ├── auth.dart           # Authentication API
    │   ├── user.dart           # User API
    │   └── gym.dart            # Climbing gym API
    ├── models/                 # Data models with JSON serialization
    ├── screens/                # UI screens/pages
    ├── utils/                  # Utility functions and constants
    └── widgets/                # Reusable UI components
```

### Key Technologies
- **State Management**: Flutter Hooks + fquery (React Query style)
- **HTTP Client**: Dio with interceptors for auth/error handling
- **Authentication**: Kakao, Google, Apple Sign In
- **Maps**: Naver Maps SDK
- **Media**: image_picker, video_player, light_compressor
- **Storage**: flutter_secure_storage for tokens

### API Pattern (Functional Monadic)
API calls follow a functional monadic pattern with `.then()` chaining:

```dart
class UserApi {
  static final _dio = ApiClient.instance.dio;
  
  static final getCurrentUserProfile = () {
    return _dio.get('/api/users/current')
      .then((response) => response.data as ApiResponse<dynamic>)
      .then((apiResponse) {
        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.error ?? 'Profile fetch failed');
        }
        return apiResponse.data as Map<String, dynamic>;
      })
      .then((data) => UserProfile.fromJson(data))
      .catchError((e) {
        throw Exception('Unable to load profile: $e');
      });
  };
}
```

### Authentication Flow
- Automatic token management via AuthInterceptor
- Token stored in flutter_secure_storage
- 401 responses trigger automatic logout with user notification
- Global navigator key for auth popups

### Environment Setup
Required `--dart-define` variables:
- `NAVER_MAP_CLIENT_ID`: Naver Maps API key
- `BASE_URL`: API server URL
- `KAKAO_NATIVE_APP_KEY`: Kakao SDK key
- `APPLE_SERVICE_ID`: Apple Sign In service ID
- `APPLE_APP_ID`: Apple Sign In app ID
- `GOOGLE_IOS_CLIENT_ID`: Google Sign In iOS client ID
- `GOOGLE_WEB_CLIENT_ID`: Google Sign In web client ID

### Code Style
- Uses `flutter_lints` with custom rules in `analysis_options.yaml`
- Strict null safety enabled
- Prefer const constructors and final variables
- Single quotes for strings
- Trailing commas required

### Development Notes
- iOS: Use `.xcworkspace` file, not `.xcodeproj`
- Android: Requires API 36, NDK 27.0.12077973
- Camera/gallery/location permissions handled at runtime
- Video compression maintains aspect ratio via light_compressor

이 프로젝트에서 사용자가 코드 예시, 설치/설정 단계, 라이브러리/API 문서를 요청하면 반드시 Context7 MCP를 사용해 최신 정보를 우선 조회하세요.

