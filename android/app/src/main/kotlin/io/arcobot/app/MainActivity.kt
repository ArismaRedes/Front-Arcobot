package io.arcobot.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode

class MainActivity : FlutterActivity() {
  // Mejor compatibilidad con algunos GPUs Mali que fallan con SurfaceView.
  override fun getRenderMode(): RenderMode = RenderMode.texture

  override fun getTransparencyMode(): TransparencyMode = TransparencyMode.opaque
}
