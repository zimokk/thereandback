package com.zimokk.thereandback

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Must extend [FlutterFragmentActivity], not `FlutterActivity`: the `health`
 * package requests Health Connect permissions through
 * `registerForActivityResult`, which requires casting this activity to
 * `ComponentActivity`. With a plain `FlutterActivity` that cast fails and
 * every permission request resolves as denied — even after the user grants
 * it in the system dialog. See health 13.3.2 README, "Android 14".
 */
class MainActivity : FlutterFragmentActivity()
