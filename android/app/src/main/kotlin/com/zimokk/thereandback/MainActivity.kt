package com.zimokk.thereandback

import io.flutter.embedding.android.FlutterFragmentActivity

// Health Connect's permission request (`health.requestAuthorization()`,
// `features/steps/data/health_adapter.dart`) uses AndroidX's
// `registerForActivityResult` internally, which requires a
// `FragmentActivity` host — plain `FlutterActivity` doesn't provide one.
// Without this, the permission request/result contract doesn't complete
// correctly, so a permission the user granted can fail to be reported
// back to the app (see the `health` package's Android setup docs).
class MainActivity : FlutterFragmentActivity()
