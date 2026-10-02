import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/models/grid_item.dart';
import 'package:ymuh_app/models/menu_model.dart';

class MenuPageController extends GetxController {
  // 選單頁下方的按鈕: 預設值
  List<GridItem> _defaultBottomNavItems = [
    new GridItem(icon: 'assets/images/ic_home.svg', title: '首頁'),
    new GridItem(icon: 'assets/images/ic_search.svg', title: '查詢', link: 'regist/mapp.php?component=regist&view=search&tmpl=mobile'),
    new GridItem(icon: 'assets/images/ic_hospital.svg', title: '公告', link: 'index/message.html'),
    new GridItem(icon: 'assets/images/ic_pay.svg', title: '門診時刻表', link: 'information/outpatient-schedule.html'),
    new GridItem(icon: 'assets/images/ic_other.svg', title: '網站', link: ''),
  ];
  // 選單頁下方的按鈕: 真正要顯示的資料
  List<GridItem>? _bottomNavItems;

  // 選單
  List<MenuModel> _menus = [];

  get bottomNavItems => _bottomNavItems;
  List<MenuModel> get menus => _menus;

  @override
  void onInit() {
    _getMenu();
    _getBottomMenu();
    super.onInit();
  }

  // 取得Menu資料
  void _getMenu() async {
    // 先用 App 內附的選單（線上資料的快照），畫面馬上有內容；線上資料回來再換掉，連不上也不會卡住
    try {
      _menus = _parseMenuData(await _getDefaultMenu());
      update();
    } catch (e) {
      print(e);
    }
    try {
      var response = await Dio(BaseOptions(connectTimeout: Duration(seconds: 5), receiveTimeout: Duration(seconds: 8)))
          .get('https://www.hosp.nycu.edu.tw/tw/?option=com_ajax&plugin=mobile&task=get.menu&format=json');
      if (response.data['success']) {
        // 先完整解析完再換掉，解析到一半失敗就留著內附的選單
        _menus = _parseMenuData(response.data['data'][0]);
        update();
      }
      // print(response);
    } catch (e) {
      print(e);
    }
  }

  List<MenuModel> _parseMenuData(data) {
    final menus = <MenuModel>[];
    data.forEach((key, values) {
      // print("Key : $k, Value : $v");
      MenuModel menu = new MenuModel();
      menu.title = values['title'];
      if (values.containsKey('childs')) {
        values['childs'].forEach((child) {
          LevelOneMenu levelOneMenu = new LevelOneMenu();
          levelOneMenu.title = child['title'];
          levelOneMenu.icon = child.containsKey('icon') ? child['icon'] : '';
          if (child.containsKey('childs')) {
            levelOneMenu.levelTwoMenus =
                child['childs'].map<LevelTwoMenu>((b) => LevelTwoMenu(b['title'] ?? '', b['url'] ?? '', b['icon'] ?? '')).toList();
          }
          menu.levelOneMenus.add(levelOneMenu);
        });
      }

      menus.add(menu);

      // print(menu);
    });
    return menus;
  }

  // 從json file取得預設的選單
  Future<Map<String, dynamic>?> _getDefaultMenu() async {
    String strMenuJson = await rootBundle.loadString('assets/menu.json');
    return jsonDecode(strMenuJson);
  }

  // 取得在首頁呼叫API取得的資料
  void _getBottomMenu() {
    try {
      if (AppController.BOTTOM_MENUS.length <= 0) throw 'NO MENU DATA';
      var search = AppController.getBottomMenuItem('Search');
      var reservation = AppController.getBottomMenuItem('Reservation');
      var pay = AppController.getBottomMenuItem('Pay');
      var other = AppController.getBottomMenuItem('Other');

      _bottomNavItems = [
        new GridItem(icon: 'assets/images/ic_home.svg', title: '首頁'),
        new GridItem(icon: 'assets/images/ic_search.svg', title: search['title'], link: search['url']),
        new GridItem(icon: 'assets/images/ic_hospital.svg', title: reservation['title'], link: reservation['url']),
        new GridItem(icon: 'assets/images/ic_pay.svg', title: pay['title'], link: pay['url']),
        new GridItem(icon: 'assets/images/ic_other.svg', title: other['title'], link: other['url']),
      ];
    } catch (e) {
      // API沒取到資料就使用預設值
      _bottomNavItems = _defaultBottomNavItems;
    }
    update();
  }
}
