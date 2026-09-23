import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/theme/app_color.dart';

class WebViewPage extends StatefulWidget {
  WebViewPage({Key? key, required this.url, this.title}) : super(key: key);

  final String url;
  final String? title;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool hasError = false;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // 只有醫院網站在 App 內開，其他網址（外部網站、tel:、mailto:）交給手機的瀏覽器或對應 App，
        // 避免外部網頁在 App 裡看起來像醫院的頁面。iframe 不攔，內嵌影片、地圖照常載入。
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (!request.isMainFrame || (uri.scheme == 'https' && uri.host == Uri.parse(AppController.BASE_URL).host)) {
            return NavigationDecision.navigate;
          }
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
        onWebResourceError: (e) {
          // print(e);
          setState(() {
            hasError = true;
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.title ?? '國立陽明交通大學附設醫院')),
      // edge-to-edge (API 35+): keep the page's own footer above the system navigation bar
      body: SafeArea(
        top: false,
        child: !hasError
            ? WebViewWidget(controller: controller)
            : Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/error.jpg'),
                      SizedBox(height: 25),
                      Text('伺服器忙碌中，請稍後再試!'),
                      SizedBox(height: 25),
                      ElevatedButton(
                          onPressed: Get.back,
                          child: Text('返回'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.PRIMARY_COLOR))
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
