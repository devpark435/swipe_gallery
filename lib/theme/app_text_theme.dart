import 'package:flutter/material.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';

/// 앱 전역 텍스트 스타일 정의
class AppTextTheme {
  AppTextTheme._();

  static const _baseDisplayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const _baseHeadlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const _baseBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const _baseBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const _baseLabelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const _baseLabelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // 하위 호환성을 위해 유지 (삭제해도 되지만 기존 코드 수정을 최소화하기 위해)
  // 하지만 색상은 Theme에서 덮어씌워져야 함.
  static const displayLarge = _baseDisplayLarge;
  static const headlineMedium = _baseHeadlineMedium;
  static const bodyLarge = _baseBodyLarge;
  static const bodyMedium = _baseBodyMedium;
  static const labelLarge = _baseLabelLarge;
  static const labelMedium = _baseLabelMedium;

  static TextTheme getTheme(AppColorTheme colors) {
    return TextTheme(
      displayLarge: _baseDisplayLarge.copyWith(color: colors.textPrimary),
      headlineMedium: _baseHeadlineMedium.copyWith(color: colors.textPrimary),
      bodyLarge: _baseBodyLarge.copyWith(color: colors.textPrimary),
      bodyMedium: _baseBodyMedium.copyWith(color: colors.textSecondary),
      labelLarge: _baseLabelLarge.copyWith(color: colors.surface),
      labelMedium: _baseLabelMedium.copyWith(color: colors.textSecondary),
    ).apply(fontFamily: 'Pretendard');
  }
}
