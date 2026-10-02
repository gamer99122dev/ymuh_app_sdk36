import 'package:flutter_test/flutter_test.dart';
import 'package:ymuh_app/widgets/connection_check.dart';

CheckStep ok() => CheckStep(true, 'ok');
CheckStep ng() => CheckStep(false, 'ng');

void main() {
  // 順序固定：[網際網路, 網域解析, 連線 443, 醫院網站 HTTPS]，由前往後第一個失敗的就是卡住的地方
  test('verdictOf 依第一個失敗的步驟下結論', () {
    expect(verdictOf([ng(), ng(), ng(), ng()]), contains('連不上網際網路'));
    expect(verdictOf([ok(), ng(), ng(), ng()]), contains('解析不到'));
    expect(verdictOf([ok(), ok(), ng(), ng()]), contains('連不上醫院伺服器'));
    expect(verdictOf([ok(), ok(), ok(), ng()]), contains('HTTPS 請求失敗'));
    expect(verdictOf([ok(), ok(), ok(), ok()]), contains('現在連得上'));
  });
}
