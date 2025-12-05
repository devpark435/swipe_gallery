# swipe_gallery

스와이프로 갤러리 사진을 정리하는 Flutter 애플리케이션입니다. 오래된 사진부터 순차적으로 보여 주면서 좌/우 스와이프, 휴지통, 다중 선택 등 정리 경험에 필요한 UX를 담았습니다.

## 주요 특징

- **스와이프 기반 정리**: 카드형 인터페이스에서 좌측 스와이프는 삭제, 우측 스와이프는 패스로 처리합니다.
- **오래된 사진 우선 정렬**: 단말의 갤러리에서 촬영일순(오래된 → 최신)으로 로컬 이미지를 불러옵니다.
- **휴지통 & 영구 삭제**: 삭제한 사진은 먼저 휴지통에 보관되고, 앱을 재시작해도 `shared_preferences`에 저장된 상태가 유지됩니다.
- **다중 선택 그리드 UI**: 휴지통 탭에서는 2열 그리드와 하단 액션바를 통해 복수의 사진을 한 번에 복구하거나 삭제할 수 있습니다.
- **하단 네비게이션**: 갤러리/휴지통 두 탭을 GoRouter Stateful Shell로 관리하며, 휴지통 탭에는 사진 수에 따라 뱃지가 표시됩니다.

## 기술 스택

- **Flutter** (3.x) + **Riverpod**: 상태 관리 및 DI
- **GoRouter**: 화면 라우팅 및 하단 탭 전환
- **photo_manager**: 단말 갤러리 접근 및 권한 처리
- **shared_preferences**: 휴지통 사진 ID 영구 저장
- **Dart build_runner**: Riverpod 코드 제너레이션

## 프로젝트 구조

```
lib/
├── data/
│   ├── models/        # PhotoModel 등 데이터 모델
│   └── services/      # 갤러리/휴지통 서비스
├── presentation/
│   └── features/
│       └── gallery/   # 스와이프 화면, 휴지통 화면, 프로바이더
├── router/            # GoRouter 설정
└── theme/             # 테마 및 공통 스타일링
```

## 실행 방법

1. **환경 준비**
   - Flutter SDK 및 IDE (VS Code, Android Studio 등)
   - iOS/Android 에뮬레이터 또는 실기기 (사진 접근 권한 필요)

2. **의존성 설치 및 코드 생성**
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **애플리케이션 실행**
   ```bash
   flutter run
   ```

> 로컬 갤러리 접근을 위해 Android는 `READ_MEDIA_IMAGES`/`READ_EXTERNAL_STORAGE`, iOS는 `NSPhotoLibraryUsageDescription` 권한 설명을 Info.plist에 포함하고 있습니다. 실제 단말에서 테스트할 때 권한을 허용해야 정상 동작합니다.

## 향후 계획

- “작년 이맘때” 등 날짜 기반 필터/리마인드 기능
- 클라우드 백업 및 동기화
- 더 다양한 정렬/필터 및 자동 추천 정리 모드
