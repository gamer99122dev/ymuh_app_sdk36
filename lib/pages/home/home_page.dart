import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ymuh_app/controllers/home_page_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ymuh_app/models/grid_item.dart';
import 'package:ymuh_app/theme/app_color.dart';
import 'package:ymuh_app/widgets/telephone_bar.dart';
import 'package:ymuh_app/widgets/vertical_button.dart';
import 'widgets/aligned_grid.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(context) {
    // Instantiate your class using Get.put()
    final HomePageController controller = Get.put(HomePageController());

    return Scaffold(
      backgroundColor: AppColors.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppColors.PRIMARY_COLOR,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Get.toNamed('/menu'),
        ),
        title: SvgPicture.asset('assets/images/logo.svg'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 25),
        child: GetBuilder<HomePageController>(
          builder: (_) {
            return AlignedGrid(
              buildItems: (double width) {
                return List.generate(
                  controller.gridItems.length,
                  (index) {
                    GridItem gridItem = controller.gridItems[index];
                    return InkWell(
                      onTap: () => gridItem.launchURL(),
                      child: Ink(
                        width: width,
                        height: 100,
                        decoration: new BoxDecoration(
                          color: AppColors.hex('#F7F8F8'),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.hex('#CCCCCC'),
                              offset: Offset(3, 5), //陰影y軸偏移量
                              blurRadius: 3, //陰影模糊程度
                              spreadRadius: 1, //陰影擴散程度
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              gridItem.icon!,
                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR, BlendMode.srcIn),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(gridItem.title!),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TelephoneBar(),
            GetBuilder<HomePageController>(
              builder: (_) {
                return Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/banner.png'),
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.srcOver),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(
                      controller.bottomNavItems.length,
                      (index) {
                        GridItem bottomNavItem = controller.bottomNavItems[index];
                        return VerticalButton(
                          onPressed: () => bottomNavItem.launchURL(),
                          icon: SvgPicture.asset(bottomNavItem.icon!),
                          label: Padding(
                            padding: EdgeInsets.only(top: bottomNavItem.type == "EMAIL" ? 8.0 : 0),
                            child: Text(
                              bottomNavItem.title!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
