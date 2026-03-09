package io.arcobot.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin

class AppAuthCallbackActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    val callbackUri = intent?.data
    if (callbackUri == null) {
      finish()
      return
    }

    val scheme = callbackUri.scheme

    if (scheme != null) {
      FlutterWebAuth2Plugin.callbacks.remove(scheme)?.success(callbackUri.toString())
    }

    // Ensure the app comes back to foreground immediately after auth callback.
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
    if (launchIntent != null) {
      launchIntent.addFlags(
        Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_CLEAR_TOP or
            Intent.FLAG_ACTIVITY_SINGLE_TOP,
      )
      startActivity(launchIntent)
    }

    finishAndRemoveTask()
  }
}
