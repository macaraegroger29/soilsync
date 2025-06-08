package com.soilsync.app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d("MainActivity", "onCreate called")
        try {
            super.onCreate(savedInstanceState)
            Log.d("MainActivity", "onCreate completed successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in onCreate: ${e.message}", e)
            throw e
        }
    }
} 