import 'package:get/get.dart';
import 'package:ymuh_app/pages/home/home_page.dart';
import 'package:ymuh_app/pages/menu/menu_page.dart';
part 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.INITIAL,
      page: () => HomePage(),
    ),
    GetPage(
      name: Routes.MENU,
      page: () => MenuPage(),
    ),
  ];
}
