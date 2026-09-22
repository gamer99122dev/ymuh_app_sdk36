import 'package:flutter/material.dart';
import 'package:ymuh_app/models/menu_model.dart';
import 'package:ymuh_app/pages/menu/widgets/menu_item.dart';
import 'package:ymuh_app/theme/app_color.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({Key key, @required this.menuModel}) : super(key: key);

  final MenuModel menuModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            menuModel.title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.PRIMARY_COLOR),
          ),
        ),
        for (int i = 0; i < menuModel.levelOneMenus.length; i++) MenuItem(levelOneMenu: menuModel.levelOneMenus[i]),
      ],
    );
  }
}
