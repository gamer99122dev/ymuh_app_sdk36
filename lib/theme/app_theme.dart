import 'package:flutter/material.dart';
import 'app_color.dart';

final ThemeData appThemeData = ThemeData(
  useMaterial3: false,
  primaryColor: AppColors.PRIMARY_COLOR,
  // Flutter 2 的 AppBar 用 primaryColor，現在用 colorScheme.primary，兩個都設才會和舊版一樣
  colorScheme: ColorScheme.fromSwatch(accentColor: AppColors.ACCENT_COLOR).copyWith(primary: AppColors.PRIMARY_COLOR),
  splashColor: Colors.grey,
  // highlightColor: Colors.purple,
  // fontFamily: 'Poppins',
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
  ),
);
