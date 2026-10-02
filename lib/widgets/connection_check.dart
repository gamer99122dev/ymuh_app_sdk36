import 'dart:async';
import 'dart:io';

// 出錯時的連線自我檢查，用來分辨：手機沒網路／網域解析不到／連不上伺服器／安全連線失敗／連得上但這次太慢。
// 只在錯誤畫面出現後才跑，結果只顯示在畫面上，不傳到任何伺服器。
// 對照用的 generate_204 是 Android 自己判斷「有沒有網路」用的端點。
// ponytail: dart:io 的 HttpClient 不走 Android 系統代理，與 WebView 走的路徑可能不同；需要時再改

class CheckStep {
  final bool ok;
  final String text;
  CheckStep(this.ok, this.text);
}

Future<CheckStep> _step(String name, Future<String> Function() run) async {
  final sw = Stopwatch()..start();
  try {
    final r = await run().timeout(Duration(seconds: 6));
    return CheckStep(true, '$name：$r（${sw.elapsedMilliseconds} ms）');
  } on TimeoutException {
    return CheckStep(false, '$name：逾時（6 秒）');
  } on TlsException {
    return CheckStep(false, '$name：安全連線失敗（憑證或 TLS）');
  } on SocketException catch (e) {
    return CheckStep(false, '$name：${e.osError?.message ?? e.message}');
  } catch (e) {
    return CheckStep(false, '$name：$e');
  }
}

// 只看有沒有拿到回應（不讀內容）
Future<String> _httpStatus(String url) async {
  final c = HttpClient()..connectionTimeout = Duration(seconds: 5);
  try {
    final r = await (await c.getUrl(Uri.parse(url))).close();
    return 'HTTP ${r.statusCode}';
  } finally {
    c.close(force: true);
  }
}

// 四個檢查同時跑，順序固定：[網際網路, 網域解析, 連線 443, 醫院網站 HTTPS]
Future<List<CheckStep>> runConnectionCheck(String host) => Future.wait([
      _step('網際網路（Google）', () => _httpStatus('https://connectivitycheck.gstatic.com/generate_204')),
      _step('網域解析', () async => (await InternetAddress.lookup(host)).map((a) => a.address).take(2).join(', ')),
      _step('連線 $host:443', () async {
        final s = await Socket.connect(host, 443, timeout: Duration(seconds: 5));
        s.destroy();
        return '成功';
      }),
      _step('醫院網站 HTTPS', () => _httpStatus('https://$host/')),
    ]);

// 依四個檢查的結果下結論，由前往後第一個失敗的就是卡住的地方
String verdictOf(List<CheckStep> s) {
  if (!s[0].ok) return '手機目前連不上網際網路';
  if (!s[1].ok) return '有網路，但解析不到醫院網站的網域';
  if (!s[2].ok) return '有網路、網域解析正常，但連不上醫院伺服器';
  if (!s[3].ok) return '連得上醫院伺服器，但 HTTPS 請求失敗';
  return '醫院網站現在連得上；剛才可能是暫時性或太慢，請按「重新載入」';
}
