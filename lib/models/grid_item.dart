import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/widgets/webview_page.dart';

class GridItem {
  // 圖片
  String icon;

  // 標題文字
  String title;

  // 連結路徑: WEBVIEW放路徑，連結需包含DOMAIN(因有可能是其他網域的網站)
  String link;

  // 開啟型態: WEBVIEW、BROWSER、EMAIL
  String type;

  // WebView的連結網址(Full Path): FOR WEBVIEW使用
  String get fullUrl => AppController.BASE_URL + '/' + this.link;

  // 開啟網址
  void launchURL() async {
    switch (this.type) {
      case 'WEBVIEW':
        await Get.to(WebViewPage(url: this.fullUrl, title: this.title));
        break;
      case 'BROWSER':
        await canLaunch(this.link) ? launch(this.link) : throw 'Cannot launch url: ${this.link}';
        break;
      case 'EMAIL':
        String mailScheme = 'mailto:${this.link}';
        await canLaunch(mailScheme) ? launch(mailScheme) : throw 'Cannot send mail to: ${this.link}';
        break;
      default:
    }
  }

  GridItem.fromJson(Map<String, dynamic> json, String icon, {String type}) {
    this.link = json['url'];
    this.title = json['title'];
    this.icon = icon;
    this.type = (type == null || type.isEmpty) ? 'WEBVIEW' : type;
  }


  GridItem({this.icon, this.title, this.link, this.type = 'WEBVIEW'});
}
