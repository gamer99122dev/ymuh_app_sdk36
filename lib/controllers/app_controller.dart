import 'package:get/get.dart';
import 'package:load/load.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ymuh_app/models/grid_item.dart';

// Global Controller: 共用Method
class AppController extends GetxController {
  // 正式上線前要將域名更改為 https://www.hosp.nycu.edu.tw
  // static const String BASE_URL = 'https://www.ymuh.ym.edu.tw';
  static const String BASE_URL = 'https://www.hosp.nycu.edu.tw';
  // 錯誤畫面的診斷資訊用；要跟 pubspec.yaml 的 version 一起改（Flutter 沒有內建讀版本號，不為這個多加套件）
  static const String VERSION = '1.1.1+11';
  // 首頁和選單頁下方按鈕資料
  static List<Map<String, dynamic>> BOTTOM_MENUS = [];
  @override
  void onInit() {
    super.onInit();
  }

  static Map<String, dynamic> getBottomMenuItem(String key) {
    if (BOTTOM_MENUS.length > 0) {
      switch (key) {
        // 員工專區
        case 'Staff':
          return BOTTOM_MENUS[5];
        // Youtube
        case 'Youtube':
          return BOTTOM_MENUS[0];
        // 查詢
        case 'Search':
          return BOTTOM_MENUS[1];
        // 掛號
        case 'Reservation':
          return BOTTOM_MENUS[2];
        // 繳費
        case 'Pay':
          return BOTTOM_MENUS[3];
        // 其它
        case 'Other':
          return BOTTOM_MENUS[4];
        default:
          // 沒在關鍵字內都丟其它
          return BOTTOM_MENUS[4];
      }
    }
    return {};
  }

  // Show loading overlay
  static Future<void> showLoading() async {
    await showLoadingDialog(tapDismiss: false);
  }

  // Hide loading overlay
  static void hideLoading() {
    return hideLoadingDialog();
  }

  // 開啟外部 App（瀏覽器、郵件、電話）。沒裝對應 App 等失敗情況要跟使用者說，不要按了沒反應
  // 不用 canLaunchUrl：Manifest 沒宣告對應的 <queries> 時它會誤回 false
  static Future<void> openExternal(Uri uri, {LaunchMode mode = LaunchMode.platformDefault, String? failHint}) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: mode);
    } catch (_) {}
    if (!ok) Get.snackbar('無法開啟', failHint ?? '手機上找不到可以開啟這個連結的應用程式');
  }
}
