class MenuModel {
  // 標題: 放院區名稱
  String title;
  // 第一層選單
  List<LevelOneMenu> levelOneMenus;

  MenuModel({this.title, List<LevelOneMenu> levelOneMenus}) : this.levelOneMenus = levelOneMenus ?? [];
}

class LevelOneMenu {
  String title;
  String icon;
  // 第二層選單
  List<LevelTwoMenu> levelTwoMenus;

  LevelOneMenu({this.title, this.icon, List<LevelTwoMenu> levelTwoMenus}) : this.levelTwoMenus = levelTwoMenus ?? [];
}

class LevelTwoMenu {
  String title;
  String url;
  String icon;

  LevelTwoMenu(this.title, this.url, this.icon);
}
