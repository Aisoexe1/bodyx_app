package com.bodyx.bodyx_app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by the `health`
// plugin's Health Connect permission flow on Android 14+, which needs
// registerForActivityResult via ComponentActivity.
class MainActivity : FlutterFragmentActivity()
