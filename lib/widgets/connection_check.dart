import 'dart:async';
import 'dart:convert';
import 'dart:io';

// 出錯時的連線自我檢查，用來分辨：手機沒網路／網域解析不到／連不上伺服器／安全連線失敗／連得上但這次太慢。
// 只在錯誤畫面出現後才跑，結果只顯示在畫面上，不傳到醫院或我們的任何伺服器。
// 對外部的請求只有兩個：Google 的 generate_204（Android 自己判斷「有沒有網路」用的端點）與 Cloudflare 的連線資訊端點（見下）；
// 對方看得到的只有這支手機的 IP（任何網路請求都一樣），沒有送出其他資料。
// ponytail: dart:io 的 HttpClient 不走 Android 系統代理，與 WebView 走的路徑可能不同；需要時再改

class CheckStep {
  final bool ok;
  final String text;
  CheckStep(this.ok, this.text);
}

Future<CheckStep> _step(String name, Future<String> Function() run, {int seconds = 6}) async {
  final sw = Stopwatch()..start();
  try {
    final r = await run().timeout(Duration(seconds: seconds));
    return CheckStep(true, '$name：$r（${sw.elapsedMilliseconds} ms）');
  } on TimeoutException {
    return CheckStep(false, '$name：逾時（$seconds 秒）');
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

// 這支手機從哪個國家連出去：Cloudflare 公開的連線資訊端點，回傳公開 IP、國家代碼、機房、TLS 版本（不需金鑰、只查一次、只顯示在畫面上）。
// 只用 Cloudflare 一個來源；先走 IP（不經 DNS），失敗再走網域
// ponytail: 國家對照表只列常見的，沒列到的直接顯示代碼；地理位置是 Cloudflare 的 IP 資料，通常準但不是 100%
const _countries = {
  'TW': '台灣', 'US': '美國', 'JP': '日本', 'CN': '中國', 'HK': '香港', 'MO': '澳門', 'SG': '新加坡', 'KR': '南韓',
  'IN': '印度', 'DE': '德國', 'GB': '英國', 'FR': '法國', 'NL': '荷蘭', 'IE': '愛爾蘭', 'CA': '加拿大', 'AU': '澳洲',
  'BR': '巴西', 'RU': '俄羅斯', 'TH': '泰國', 'VN': '越南', 'MY': '馬來西亞', 'ID': '印尼', 'PH': '菲律賓', 'IT': '義大利',
  'ES': '西班牙', 'SE': '瑞典', 'FI': '芬蘭', 'PL': '波蘭', 'TR': '土耳其', 'IL': '以色列', 'AE': '阿聯', 'CH': '瑞士',
  'BE': '比利時', 'AT': '奧地利', 'NO': '挪威', 'DK': '丹麥', 'MX': '墨西哥', 'ZA': '南非', 'NZ': '紐西蘭', 'UA': '烏克蘭',
};

String countryName(String? code) {
  if (code == null || code.isEmpty) return '未知';
  final n = _countries[code];
  return n == null ? code : '$n（$code）';
}

Map<String, String> parseTrace(String body) => {
      for (final l in body.split('\n'))
        if (l.contains('=')) l.substring(0, l.indexOf('=')).trim(): l.substring(l.indexOf('=') + 1).trim(),
    };

String describeTrace(Map<String, String> t) =>
    'IP ${t['ip'] ?? '未知'}｜${countryName(t['loc'])}｜Cloudflare 機房 ${t['colo'] ?? '?'}｜${t['tls'] ?? ''}';

Future<String> _httpBody(String url) async {
  final c = HttpClient()..connectionTimeout = Duration(seconds: 5);
  try {
    final r = await (await c.getUrl(Uri.parse(url))).close();
    return await r.transform(utf8.decoder).join();
  } finally {
    c.close(force: true);
  }
}

// 五個檢查同時跑，順序固定：[網際網路, 網域解析, 連線 443, 醫院網站 HTTPS, 你的公開網路(IP／國家)]；第五個只提供資訊，不影響 verdictOf
Future<List<CheckStep>> runConnectionCheck(String host) => Future.wait([
      _step('網際網路（Google）', () => _httpStatus('https://connectivitycheck.gstatic.com/generate_204')),
      _step('網域解析', () async => (await InternetAddress.lookup(host)).map((a) => a.address).take(2).join(', ')),
      _step('連線 $host:443', () async {
        final s = await Socket.connect(host, 443, timeout: Duration(seconds: 5));
        s.destroy();
        return '成功';
      }),
      _step('醫院網站 HTTPS', () => _httpStatus('https://$host/')),
      _step('你的公開網路', () async {
        String body;
        try {
          body = await _httpBody('https://1.1.1.1/cdn-cgi/trace');
        } catch (_) {
          body = await _httpBody('https://www.cloudflare.com/cdn-cgi/trace');
        }
        return describeTrace(parseTrace(body));
      }, seconds: 10),
    ]);

// 依四個檢查的結果下結論，由前往後第一個失敗的就是卡住的地方
String verdictOf(List<CheckStep> s) {
  if (!s[0].ok) return '手機目前連不上網際網路';
  if (!s[1].ok) return '有網路，但解析不到醫院網站的網域';
  if (!s[2].ok) return '有網路、網域解析正常，但連不上醫院伺服器';
  if (!s[3].ok) return '連得上醫院伺服器，但 HTTPS 請求失敗';
  return '醫院網站現在連得上；剛才可能是暫時性或太慢，請按「重新載入」';
}
