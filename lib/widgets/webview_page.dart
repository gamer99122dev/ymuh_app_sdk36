import 'dart:async';
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
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    // 首次載入超過 15 秒（例如海外連不上醫院網站）就顯示錯誤畫面，不要讓使用者一直等空白頁
    // ponytail: 只管第一頁；頁面內再跳轉不計時，網路很慢的使用者可能被誤判，需要時再調大秒數
    _loadTimeout = Timer(Duration(seconds: 15), () {
      if (mounted) setState(() => hasError = true);
    });
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
        // 主頁已經開始有內容（不是卡在連線）就取消計時，子資源拖慢 onPageFinished 不該讓能用的頁面被換成錯誤畫面
        // ponytail: 30 是估計值未實測，真機觀察後再調
        onProgress: (p) {
          if (p >= 30) _loadTimeout?.cancel();
        },
        onPageFinished: (_) => _loadTimeout?.cancel(),
        onWebResourceError: (e) {
          // 只有主頁失敗才顯示錯誤畫面；圖片、script 等子資源失敗不影響整頁
          if (e.isForMainFrame == false) return;
          _loadTimeout?.cancel();
          setState(() {
            hasError = true;
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
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
