import 'package:flutter_test/flutter_test.dart';
import 'package:ymuh_app/widgets/connection_check.dart';

CheckStep ok() => CheckStep(true, 'ok');
CheckStep ng() => CheckStep(false, 'ng');

void main() {
  // 順序固定：[網際網路, 網域解析, 連線 443, 醫院網站 HTTPS, (公開 IP／國家，不影響判斷)]，由前往後第一個失敗的就是卡住的地方
  test('verdictOf 依第一個失敗的步驟下結論', () {
    expect(verdictOf([ng(), ng(), ng(), ng()]), contains('連不上網際網路'));
    expect(verdictOf([ok(), ng(), ng(), ng()]), contains('解析不到'));
    expect(verdictOf([ok(), ok(), ng(), ng()]), contains('連不上醫院伺服器'));
    expect(verdictOf([ok(), ok(), ok(), ng()]), contains('HTTPS 請求失敗'));
    expect(verdictOf([ok(), ok(), ok(), ok()]), contains('現在連得上'));
  });

  test('第五個（公開 IP／國家）失敗不影響判斷', () {
    expect(verdictOf([ok(), ok(), ok(), ok(), ng()]), contains('現在連得上'));
  });

  test('Cloudflare trace 的解析與國家中文對照', () {
    const body = 'fl=80f451\nh=1.1.1.1\nip=203.0.113.9\nts=1\ncolo=TPE\nhttp=http/1.1\nloc=US\ntls=TLSv1.3\n';
    final t = parseTrace(body);
    expect(t['ip'], '203.0.113.9');
    expect(describeTrace(t), 'IP 203.0.113.9｜美國（US）｜Cloudflare 機房 TPE｜TLSv1.3');
    expect(countryName('TW'), '台灣（TW）');
    expect(countryName('ZZ'), 'ZZ'); // 沒列到的直接顯示代碼
    expect(countryName(null), '未知');
    expect(describeTrace(parseTrace('')), 'IP 未知｜未知｜Cloudflare 機房 ?｜');
  });
}
