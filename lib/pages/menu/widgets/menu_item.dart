import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/models/menu_model.dart';
import 'package:ymuh_app/theme/app_color.dart';
import 'package:ymuh_app/widgets/webview_page.dart';

class MenuItem extends StatefulWidget {
  MenuItem({Key? key, required this.levelOneMenu}) : super(key: key);

  final LevelOneMenu levelOneMenu;

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> with SingleTickerProviderStateMixin {
  late AnimationController rotationController;
  @override
  void initState() {
    rotationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 35),
      childrenPadding: EdgeInsets.symmetric(horizontal: 35),
      // leading: Icon(Icons.local_hospital),
      backgroundColor: AppColors.BACKGROUND_COLOR,
      collapsedBackgroundColor: AppColors.BACKGROUND_COLOR,
      trailing: RotationTransition(
        turns: rotationController.drive(CurveTween(curve: Curves.easeIn)).drive(Tween(begin: 0.0, end: 0.25)),
        child: Icon(Icons.chevron_right),
      ),
      onExpansionChanged: (isExpanded) {
        // print(isExpanded);
        if (isExpanded) {
          rotationController.forward();
        } else {
          rotationController.reverse();
        }
      },
      leading: widget.levelOneMenu.icon != null && widget.levelOneMenu.icon!.isNotEmpty ? Image.network('${AppController.BASE_URL}/${widget.levelOneMenu.icon}') : null,
      title: Text(widget.levelOneMenu.title!),
      children: List.generate(
        widget.levelOneMenu.levelTwoMenus!.length,
        (index) {
          var menuItem = widget.levelOneMenu.levelTwoMenus![index];
          return ListTile(
            leading: menuItem.icon != null && menuItem.icon.isNotEmpty ? Image.network('${AppController.BASE_URL}/${menuItem.icon}') : null,
            title: Text(menuItem.title),
            onTap: () => Get.to(WebViewPage(
                url: '${AppController.BASE_URL}/${menuItem.url}',
                title: menuItem.title)),
          );
        },
      ),
    );
  }
}
