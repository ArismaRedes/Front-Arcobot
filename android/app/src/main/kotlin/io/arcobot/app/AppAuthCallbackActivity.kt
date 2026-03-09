package io.arcobot.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin

class AppAuthCallbackActivity : Activity() {
  private companion object {
    const val callbackScheme = "io.arcobot.app"
    val callbackHosts = setOf("callback", "logout-callback")
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleAuthIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    handleAuthIntent(intent)
  }

  private fun handleAuthIntent(intent: Intent?) {
    val callbackUri = extractCallbackUri(intent)
    if (!isExpectedCallbackUri(callbackUri)) {
      finish()
      return
    }

    val scheme = callbackUri?.scheme

    if (scheme != null) {
      FlutterWebAuth2Plugin.callbacks.remove(scheme)?.success(callbackUri.toString())
    }

    // Bring the app foreground immediately after callback.
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

  private fun extractCallbackUri(intent: Intent?): Uri? {
    return intent?.data ?: parseSharedTextUri(intent)
  }

  private fun parseSharedTextUri(intent: Intent?): Uri? {
    if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") {
      return null
    }

    val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
    val parsed = runCatching { Uri.parse(sharedText) }.getOrNull() ?: return null
    if (!isExpectedCallbackUri(parsed)) {
      return null
    }

    if (parsed.host == "logout-callback") {
      return parsed
    }

    return if (hasAuthPayload(parsed)) parsed else null
  }

  private fun isExpectedCallbackUri(uri: Uri?): Boolean {
    if (uri == null) {
      return false
    }
    val scheme = uri.scheme ?: return false
    val host = uri.host ?: return false
    return scheme == callbackScheme && callbackHosts.contains(host)
  }

  private fun hasAuthPayload(uri: Uri): Boolean {
    if (uri.getQueryParameter("state") != null) return true
    if (uri.getQueryParameter("code") != null) return true
    if (uri.getQueryParameter("error") != null) return true

    val fragment = uri.fragment ?: return false
    return fragment.contains("state=") ||
        fragment.contains("code=") ||
        fragment.contains("error=")
  }
}
