import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:load/load.dart';
import 'package:ymuh_app/controllers/menu_page_controller.dart';
import 'package:ymuh_app/pages/menu/widgets/menu_item.dart';
import 'package:ymuh_app/pages/menu/widgets/menu_section.dart';
import 'package:ymuh_app/pages/menu/widgets/top_banner.dart';
import 'package:ymuh_app/theme/app_color.dart';
import 'package:ymuh_app/widgets/telephone_bar.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MenuPageController controller = Get.put(MenuPageController());

    return LoadingProvider(
      themeData: LoadingThemeData(tapDismiss: false),
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.PRIMARY_COLOR,
            title: Text('功能選單'),
          ),
          body: GetBuilder<MenuPageController>(
            init: MenuPageController(),
            builder: (c) {
              return ListView.builder(
                itemCount: c.menus.length,
                itemBuilder: (context, index) {
                  // if(index == 0) return TopBanner();
                  return MenuSection(menuModel: c.menus[index]);
                },
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: List.generate(
                    controller.bottomNavItems.length,
                    (index) => BottomNavigationBarItem(
                      icon: SvgPicture.asset(controller.bottomNavItems[index].icon, height: 22, fit: BoxFit.scaleDown),
                      label: controller.bottomNavItems[index].title,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  selectedItemColor: Colors.grey,
                  unselectedItemColor: Colors.grey,
                  onTap: (index) {
                    if (index == 0) {
                      // 回首頁
                      Get.back();
                    } else {
                      controller.bottomNavItems[index].launchURL();
                    }
                  },
                ),
                TelephoneBar(),
              ],
            ),
          )),
    );
  }
}
