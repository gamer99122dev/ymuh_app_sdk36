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
    new GridItem(icon: 'assets/images/ic_search.svg', title: '查詢', link: '/regis/indexmdsList.php'),
    new GridItem(icon: 'assets/images/ic_hospital.svg', title: '掛號', link: '/regis/indexHospital.php'),
    new GridItem(icon: 'assets/images/ic_pay.svg', title: '繳費', link: '/regis/indexHospital.php'),
    new GridItem(icon: 'assets/images/ic_other.svg', title: '其它', link: '/regis/indexHospital.php'),
  ];
  // 選單頁下方的按鈕: 真正要顯示的資料
  List<GridItem> _bottomNavItems;

  // 選單
  List<MenuModel> _menus = [];

  get bottomNavItems => _bottomNavItems;
  List<MenuModel> get menus => _menus;

  @override
  void onInit() {
    _getMenu();
    _getDefaultMenu();
    _getBottomMenu();
    super.onInit();
  }

  // 取得Menu資料
  void _getMenu() async {
    try {
      AppController.showLoading();
      var response =
          await Dio().get('https://www.hosp.nycu.edu.tw/tw/?option=com_ajax&plugin=mobile&task=get.menu&format=json');
      if (response.data['success']) {
        var data = response.data['data'][0];
        // 將Json轉成Class
        _parseMenuData(data);
        update();
        AppController.hideLoading();
      } else {
        throw 'Error';
      }
      // print(response);
    } catch (e) {
      print(e);
      // 讀取預設資料
      _parseMenuData(await _getDefaultMenu());
      update();
      AppController.hideLoading();
    }
  }

  void _parseMenuData(data) {
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

      _menus.add(menu);

      // print(menu);
    });
  }

  // 從json file取得預設的選單
  Future<Map<String, dynamic>> _getDefaultMenu() async {
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
