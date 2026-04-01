package com.flaype.pixelneondronedash

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "pixel_neon_drone_dash/platform"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "openLeaderboard" -> {
          Toast.makeText(this, "Leaderboard: подключите Google Play Games Services", Toast.LENGTH_SHORT).show()
          result.success(true)
        }
        "purchaseRemoveAds" -> {
          Toast.makeText(this, "IAP: подключите Google Play Billing (Remove Ads)", Toast.LENGTH_SHORT).show()
          // Возвращаем false, чтобы игра понимала, что покупка не выполнена.
          result.success(false)
        }
        "shareText" -> {
          val text = call.argument<String>("text") ?: ""
          val sendIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
          }
          val chooser = Intent.createChooser(sendIntent, "Share score")
          ContextCompat.startActivity(this, chooser, Bundle())
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }
  }
}

