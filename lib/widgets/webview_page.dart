import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ymuh_app/theme/app_color.dart';

class WebViewPage extends StatefulWidget {
  WebViewPage({Key key, @required this.url, this.title}) : super(key: key);

  final String url;
  final String title;

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool hasError = false;
  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.title ?? '國立陽明交通大學附設醫院')),
      body: !hasError
          ? WebView(
              initialUrl: widget.url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebResourceError: (e) {
                // print(e);
                setState(() {
                  hasError = true;
                });
              },
            )
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
                        style: ElevatedButton.styleFrom(primary: AppColors.PRIMARY_COLOR))
                  ],
                ),
              ),
            ),
    );
  }
}
