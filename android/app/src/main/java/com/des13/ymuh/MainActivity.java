package com.des13.ymuh;

import android.os.Build;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Tapjacking 防護：被其他視窗覆蓋時忽略觸控事件
        getWindow().getDecorView().setFilterTouchesWhenObscured(true);
        // Android 12+：本畫面顯示期間，系統會隱藏其他 App 的浮層（螢幕濾鏡、懸浮球…）。
        // 不加的話，只要有全螢幕浮層，上面那行會讓整個 App 點不動、捲不動。需要 AndroidManifest.xml 的 HIDE_OVERLAY_WINDOWS 權限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getWindow().setHideOverlayWindows(true);
        }
    }
}
