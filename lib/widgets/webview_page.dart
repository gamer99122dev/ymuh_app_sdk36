import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ymuh_app/controllers/app_controller.dart';
import 'package:ymuh_app/theme/app_color.dart';
import 'package:ymuh_app/widgets/connection_check.dart';

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
  // 錯誤畫面用：原因、技術代碼、網址、時間，以及連線自我檢查的結果（null = 檢查中）
  String _errWeb = ''; // WebView 回報的原因（白話）
  String _errCode = '';
  String _errUrl = '';
  String _errTime = '';
  bool _timedOut = false; // 我們自己的 15 秒逾時
  int _lastProgress = 0;
  int _timeoutProgress = 0;
  String _wvVer = ''; // 手機上的 WebView 版本（拿不到審核員的裝置資訊時，靠錯誤畫面上這一行知道他用哪一版）
  List<CheckStep>? _check;
  int _checkId = 0;

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
          if (p < 100) _lastProgress = p; // 錯誤畫面顯示「卡在幾 %」用
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
          _fail(web: _causeOf(e), code: '${e.description} (${e.errorCode})');
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    // WebView 的版本就是使用者代理字串裡的 Chrome/版本號
    controller.getUserAgent().then((ua) {
      final m = RegExp(r'Chrome/([\d.]+)').firstMatch(ua ?? '');
      if (mounted) setState(() => _wvVer = m == null ? '未知' : 'Chrome ${m.group(1)}');
    });
  }

  // 首次載入超過 15 秒（例如海外連不上醫院網站）就顯示錯誤畫面，不要讓使用者一直等空白頁。
  // 曾改成 30 秒但等太久；實測回應約 0.1～0.2 秒、最慢一次約 5 秒，15 秒還有餘裕。只計到頁面開始出現內容為止（見 onProgress）
  // 15 秒是軟逾時（見 _finishLoading）：到了先顯示診斷畫面，之後頁面載到了會自動換回網頁，所以不必為了慢網路把秒數拉長
  // ponytail: 只管第一頁；頁面內再跳轉不計時
  void _startTimer() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(Duration(seconds: 15), () => _fail(timedOut: true));
  }

  // WebView 回報的錯誤型態 → 白話原因（HTTP 404／403／500 不算錯誤，頁面照常顯示，不會進到這裡）
  String _causeOf(WebResourceError e) {
    switch (e.errorType) {
      case WebResourceErrorType.hostLookup:
        return '找不到伺服器（網域解析失敗）';
      case WebResourceErrorType.connect:
        return '無法連線（連線被拒絕或中斷）';
      case WebResourceErrorType.timeout:
        return '連線逾時';
      case WebResourceErrorType.failedSslHandshake:
        return '安全連線失敗（憑證或 TLS）';
      case WebResourceErrorType.redirectLoop:
        return '網址一直轉址';
      default:
        return '載入失敗';
    }
  }

  // 進入錯誤畫面：記下原因並做連線自我檢查。WebView 的具體錯誤可能比我們的 15 秒逾時晚到，晚到的補在同一個畫面上
  void _fail({String? web, String? code, bool timedOut = false}) {
    if (!mounted) return;
    _loadTimeout?.cancel();
    _slowHint?.cancel();
    final first = !hasError;
    setState(() {
      hasError = true;
      if (web != null) _errWeb = web;
      if (code != null) _errCode = code;
      if (timedOut) {
        _timedOut = true;
        _timeoutProgress = _lastProgress; // 逾時當下的進度；之後 WebView 的進度還會動，不能用即時值
      }
      if (first) {
        _errUrl = widget.url;
        _errTime = DateTime.now().toString().substring(0, 19);
      }
    });
    if (first) _runCheck();
    print('YMUH_ERR ${_errWeb.isEmpty ? '逾時' : _errWeb} $_errCode ${Uri.tryParse(_errUrl)?.path} ${AppController.VERSION} $_wvVer');
  }

  Future<void> _runCheck() async {
    final id = ++_checkId;
    final r = await runConnectionCheck(Uri.parse(AppController.BASE_URL).host);
    if (!mounted || id != _checkId) return; // 已離開或已按「重新載入」
    setState(() => _check = r);
    print('YMUH_CHECK ${r.map((s) => '${s.ok ? 'OK' : 'NG'} ${s.text}').join(' | ')} => ${verdictOf(r)}');
  }

  String get _headline => _errWeb.isNotEmpty ? _errWeb : (_timedOut ? '連線逾時（15 秒內沒有回應）' : '載入失敗');

  // 畫面上與「複製診斷資訊」共用的明細
  String _details() {
    final u = Uri.tryParse(_errUrl);
    final c = _check;
    return [
      if (_errCode.isNotEmpty) '錯誤代碼：$_errCode',
      if (_timedOut) '15 秒內進度沒到 30%（當時進度 $_timeoutProgress%）',
      '網址：${u == null ? _errUrl : '${u.host}${u.path}'}',
      '時間：$_errTime　版本：${AppController.VERSION}',
      'WebView：${_wvVer.isEmpty ? '取得中…' : _wvVer}',
      '',
      '連線自我檢查：',
      if (c == null) '檢查中…' else ...[...c.map((s) => '${s.ok ? '✓' : '✗'} ${s.text}'), '判斷：${verdictOf(c)}'],
    ].join('\n');
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
  // 15 秒是「軟逾時」：只有我們的逾時、WebView 自己沒報錯（_errWeb 空）時，頁面之後真的載到了（慢但最後會載完，WebView 在背景一直在載），就換回網頁；
  // WebView 回報了具體錯誤（約 30 秒才會）就是最終判決，不換回（它的內建錯誤頁也會觸發 onPageFinished）
  void _finishLoading() {
    _loadTimeout?.cancel();
    if (!mounted) return;
    if (hasError && _errWeb.isEmpty) {
      _checkId++; // 還在跑的自我檢查結果作廢
      setState(() {
        hasError = false;
        loading = false;
        _timedOut = false;
        _check = null;
      });
      print('YMUH_RECOVER 逾時後頁面載到了（慢但成功） ${AppController.VERSION}');
    } else if (loading) {
      setState(() => loading = false);
    }
  }

  void _retry() {
    _checkId++; // 還在跑的自我檢查結果作廢
    setState(() {
      hasError = false;
      loading = true;
      _errWeb = _errCode = '';
      _timedOut = false;
      _check = null;
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
            // 內容會比一屏長（診斷明細），所以可捲動；平板橫向、大字體也都看得到按鈕
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(_headline,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                    SizedBox(height: 8),
                    Text('無法載入醫院網站，請檢查網路後重試', textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    SelectableText(_details(), style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                    SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _retry,
                        child: Text('重新載入'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.PRIMARY_COLOR)),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '$_headline\n${_details()}'));
                          Get.snackbar('已複製', '診斷資訊已複製到剪貼簿');
                        },
                        child: Text('複製診斷資訊'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.PRIMARY_COLOR)),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: Get.back,
                        child: Text('返回'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.PRIMARY_COLOR)),
                  ],
                ),
              ),
      ),
    );
  }
}
