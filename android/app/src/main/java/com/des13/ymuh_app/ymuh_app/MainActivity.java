package com.des13.ymuh;

import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Tapjacking 防護：被其他視窗覆蓋時忽略觸控事件
        getWindow().getDecorView().setFilterTouchesWhenObscured(true);
    }
}
