package com.example.talent_find

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the ML Native Plugin
        flutterEngine
            .plugins
            .add(MLNativePlugin())
    }
}