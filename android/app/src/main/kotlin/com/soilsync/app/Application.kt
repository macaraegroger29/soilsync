package com.soilsync.app

import android.util.Log
import io.flutter.app.FlutterApplication

class Application : FlutterApplication() {
    override fun onCreate() {
        Log.d("Application", "onCreate called")
        try {
            super.onCreate()
            Log.d("Application", "onCreate completed successfully")
        } catch (e: Exception) {
            Log.e("Application", "Error in onCreate: ${e.message}", e)
            throw e
        }
    }
} 