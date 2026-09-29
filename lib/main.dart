import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ymuh_app/routes/app_pages.dart';
import 'package:ymuh_app/theme/app_theme.dart';

import 'controllers/app_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App 只有淺色畫面：明確指定三按鈕導覽列用深色圖示，避免部分手機（如 POCO/HyperOS）預設白色圖示疊在淺色背景上看不清楚
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: true,
  ));
  // Register Global Controller
  Get.put(AppController());
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: Routes.INITIAL,
    theme: appThemeData,
    defaultTransition: Transition.native,
    getPages: AppPages.pages,
    locale: Get.deviceLocale,
  ));
}