import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/models/grid_item.dart';

class HomePageController extends GetxController {
  // 首頁中間的按鈕: 預設值
  List<GridItem> _defaultGridItems = [
    new GridItem(
      icon: 'assets/images/ic_schedule.svg',
      title: '門診時間表',
      link: 'tw/information/outpatient-schedule.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_appointment.svg',
      title: '網路掛號',
      link: 'reservation1.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_progress.svg',
      title: '查詢看診進度',
      link: 'reservation1.html?component=regist&view=realtime',
    ),
    new GridItem(
      icon: 'assets/images/ic_message.svg',
      title: '訊息專區',
      link: 'index/message.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_convenience_service.svg',
      title: '便民服務',
      link: 'index/convenience-services.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_health_management_center.svg',
      title: '健康管理中心',
      link: 'index/convenience-services.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_epidemic_prevention.svg',
      title: '疫情防疫專區',
      link: 'index/convenience-services.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_search_branch.svg',
      title: '查詢科別',
      link: 'reservation1.html?component=regist&view=section',
    ),
    new GridItem(
      icon: 'assets/images/ic_hospital_introduction.svg',
      title: '兩院區介紹',
      link: 'ymuhbranch.html',
    ),
    new GridItem(
      icon: 'assets/images/ic_consult.svg',
      title: '網站諮詢服務',
      link: 'info-note1.html',
    ),
  ];
  // 首頁中間的按鈕: 真正要顯示的資料
  List<GridItem> _gridItems = [];

  // 首頁下方的按鈕: 預設值
  List<GridItem> _defaultBottomNavItems = [
    new GridItem(
      icon: 'assets/images/ic_employee.svg',
      title: '員工專區',
      link: '${AppController.BASE_URL}/tw/index/staff.html',
      type: 'BROWSER',
    ),
    new GridItem(
      icon: 'assets/images/ic_mail.svg',
      title: '院長信箱',
      link: '0110@ymuh.ym.edu.tw',
      type: 'EMAIL',
    ),
    new GridItem(
      icon: 'assets/images/ic_youtube.svg',
      title: 'Youtube',
      link: 'https://www.youtube.com/channel/UCy7gdeQ5LdOFwit6XSGRj8g?view_as=subscriber',
      type: 'BROWSER',
    ),
  ];
  // 首頁下方的按鈕: 真正要顯示的資料
  List<GridItem> _bottomNavItems = [];

  get gridItems => this._gridItems;
  get bottomNavItems => this._bottomNavItems;

  @override
  void onInit() {
    _getHomeData();
    super.onInit();
  }

  // 透過API取得資料
  void _getHomeData() async {
    try {
      AppController.showLoading();
      var response = await Dio().get(
          'https://www.hosp.nycu.edu.tw/tw/index.php?option=com_ajax&plugin=mobile&task=get.main_menu&format=json');
      if (response.data['success']) {
        var data = response.data['data'][0];
        // print(data);

        // 將Json轉成Class
        // 首頁中間按鈕資料
        var jsonMainMenu = data['main_menu'];
        _parseMainMenu(jsonMainMenu);

        // 首頁下方按鈕資料
        var jsonBottomMenu = data['bottom_menu'];
        _parseBottomMenu(jsonBottomMenu);

        update();
        AppController.hideLoading();
      } else {
        throw 'Error';
      }
    } catch (e) {
      // API處理失敗就設定成預設值
      _gridItems = _defaultGridItems;
      _bottomNavItems = _defaultBottomNavItems;
      update();
      AppController.hideLoading();
    }
  }

  // Parse Main Menu Json Data
  void _parseMainMenu(List jsonMainMenu) {
    _gridItems.clear();
    for (int i = 0; i < jsonMainMenu.length; i++) {
      _gridItems.add(GridItem.fromJson(jsonMainMenu[i], _defaultGridItems[i].icon));
      // print(_gridItems);
    }
  }

  // Parse Bottom Menu Json Data
  void _parseBottomMenu(List jsonBottomMenu) {
    // 兩個頁面都要用到，先放到共用的Controller
    AppController.BOTTOM_MENUS = jsonBottomMenu.map((dynamic e) => e as Map<String, dynamic>).toList();

    // API順序固定，組出Home Bottom Menu
    var staff = AppController.getBottomMenuItem('Staff');
    var youtube = AppController.getBottomMenuItem('Youtube');
    GridItem bottomStaffItem = new GridItem(
      icon: 'assets/images/ic_employee.svg',
      title: staff['title'],
      link: "${AppController.BASE_URL}/${staff['url']}",
      type: 'BROWSER',
    );
    GridItem bottomYoutubeItem = new GridItem(
      icon: 'assets/images/ic_youtube.svg',
      title: youtube['title'],
      link: youtube['url'],
      type: 'BROWSER',
    );
    GridItem bottomMailItem = new GridItem(
      icon: 'assets/images/ic_mail.svg',
      title: '院長信箱',
      link: '0110@ymuh.ym.edu.tw',
      type: 'EMAIL',
    );

    _bottomNavItems = [bottomStaffItem, bottomMailItem, bottomYoutubeItem];
  }
}
