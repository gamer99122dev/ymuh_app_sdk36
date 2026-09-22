import 'package:get/get.dart';
import 'package:load/load.dart';
import 'package:ymuh_app/models/grid_item.dart';

// Global Controller: 共用Method
class AppController extends GetxController {
  // 正式上線前要將域名更改為 https://www.hosp.nycu.edu.tw
  // static const String BASE_URL = 'https://www.ymuh.ym.edu.tw';
  static const String BASE_URL = 'https://www.hosp.nycu.edu.tw';
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
    return await showLoadingDialog(tapDismiss: false);
  }

  // Hide loading overlay
  static void hideLoading() {
    return hideLoadingDialog();
  }
}
