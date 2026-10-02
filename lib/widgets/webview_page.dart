import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/theme/app_color.dart';

// ponytail: 只認網址結尾的副檔名；沒有副檔名的下載連結（例如 ?task=download）抓不到，遇到再加
final _fileLink = RegExp(r'\.(pdf|docx?|xlsx?|pptx?|od[tsp]|zip|rar|7z)$', caseSensitive: false);

class WebViewPage extends StatefulWidget {
  WebViewPage({Key? key, required this.url, this.title}) : super(key: key);

  final String url;
  final String? title;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool hasError = false;
  // 主頁還沒有內容時蓋一層「載入中」，免得使用者只看到空白頁；關閉時機跟逾時計時器一致（_finishLoading）
  bool loading = true;
  late final WebViewController controller;
  Timer? _loadTimeout;
  // 頂部細進度條（不擋畫面）：每次載入頁面的進度，100 = 不顯示。第一頁有自己的載入畫面，這條是給之後換頁用的
  final ValueNotifier<int> _progress = ValueNotifier<int>(100);
  Timer? _slowHint;

  @override
  void initState() {
    super.initState();
    _startTimer();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // 只有醫院網站在 App 內開，其他網址（外部網站、tel:、mailto:）交給手機的瀏覽器或對應 App，
        // 避免外部網頁在 App 裡看起來像醫院的頁面。iframe 不攔，內嵌影片、地圖照常載入。
        // PDF／Office／壓縮檔（門診表就是 PDF）也交給手機：WebView 不會顯示它們、App 也沒有下載處理，留在 App 裡點了完全沒反應。
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          final isFile = request.isMainFrame && _fileLink.hasMatch(uri.path);
          if (!isFile && (!request.isMainFrame || (uri.scheme == 'https' && uri.host == Uri.parse(AppController.BASE_URL).host))) {
            if (request.isMainFrame) _navStarted();
            return NavigationDecision.navigate;
          }
          AppController.openExternal(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
        onPageStarted: (_) => _progress.value = 0,
        // 主頁已經開始有內容（不是卡在連線）就取消計時，子資源拖慢 onPageFinished 不該讓能用的頁面被換成錯誤畫面
        // ponytail: 30 是估計值未實測，真機觀察後再調
        onProgress: (p) {
          // 換頁時 WebView 會先送幾次假的 10／100（導航被攔下再重送造成，實測），不能當進度：只信中間值，結束交給 onPageFinished
          if (p > 10 && p < 100) _progress.value = p;
          // 假的 100 也不能解除第一頁的逾時與遮罩（第一頁若轉址，被攔下再重送時會送假 100）；真的載完由 onPageFinished 收尾
          if (p >= 30 && p < 100) _finishLoading();
        },
        onPageFinished: (_) {
          _progress.value = 100;
          _slowHint?.cancel();
          _finishLoading();
        },
        onWebResourceError: (e) {
          // 只有主頁失敗才顯示錯誤畫面；圖片、script 等子資源失敗不影響整頁
          if (e.isForMainFrame == false || !mounted) return; // 使用者已經離開頁面就不用處理
          _loadTimeout?.cancel();
          _slowHint?.cancel();
          setState(() {
            hasError = true;
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  // 首次載入超過 15 秒（例如海外連不上醫院網站）就顯示錯誤畫面，不要讓使用者一直等空白頁。
  // 曾改成 30 秒但等太久；實測回應約 0.1～0.2 秒、最慢一次約 5 秒，15 秒還有餘裕。只計到頁面開始出現內容為止（見 onProgress）
  // ponytail: 只管第一頁；頁面內再跳轉不計時，網路很慢的使用者可能被誤判，需要時再調大秒數
  void _startTimer() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(Duration(seconds: 15), () {
      if (mounted) setState(() => hasError = true);
    });
  }

  // 第一頁之後換頁（使用者點連結的當下）：頂部細進度條開始跑；卡住不換掉還能用的舊頁，15 秒還沒載完只提示一聲
  // 不能靠 onPageStarted／onProgress：WebView 要等伺服器有回應才會呼叫，卡住時等不到（實測），所以掛在 onNavigationRequest
  // ponytail: 只提示、不逾時；真的連不上時 WebView 會自己報錯，走錯誤畫面
  void _navStarted() {
    _progress.value = 0;
    if (loading) return; // 第一頁有自己的載入畫面與逾時
    _slowHint?.cancel();
    _slowHint = Timer(Duration(seconds: 15), () {
      if (!mounted) return;
      _progress.value = 100; // 卡住或是檔案下載（沒有結束事件）時別讓進度條一直跑；頁面真的有進度時 onProgress 會再叫回來
      Get.snackbar('網路較慢', '仍在載入中，請稍候');
    });
  }

  // 主頁有內容了（或載入完成）：取消計時、拿掉「載入中」
  void _finishLoading() {
    _loadTimeout?.cancel();
    if (mounted && loading) setState(() => loading = false);
  }

  void _retry() {
    setState(() {
      hasError = false;
      loading = true;
    });
    _startTimer();
    controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _slowHint?.cancel();
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
            ? Stack(children: [
                WebViewWidget(controller: controller),
                // 只蓋在頁面上，AppBar 的返回鍵一直能按；錯誤或逾時到時 hasError 會換成錯誤畫面
                if (loading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('載入中，請稍候…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 換頁時的細進度條；IgnorePointer 免得吃掉頁面頂端 3px 的觸控
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _progress,
                      builder: (_, p, __) => (loading || p >= 100)
                          ? SizedBox.shrink()
                          : LinearProgressIndicator(
                              value: p == 0 ? null : p / 100,
                              minHeight: 3,
                              color: AppColors.PRIMARY_COLOR,
                              backgroundColor: Colors.transparent),
                    ),
                  ),
                ),
              ])
            : Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 圖片可縮小：平板橫向時圖片太大會把文字和按鈕擠出畫面
                      Flexible(child: Image.asset('assets/images/error.jpg', fit: BoxFit.contain)),
                      SizedBox(height: 25),
                      Text('伺服器忙碌中，請稍後再試!'),
                      SizedBox(height: 25),
                      ElevatedButton(
                          onPressed: _retry,
                          child: Text('重新載入'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.PRIMARY_COLOR)),
                      SizedBox(height: 10),
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
