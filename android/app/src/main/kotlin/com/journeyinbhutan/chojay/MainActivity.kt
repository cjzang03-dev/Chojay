package com.journeyinbhutan.chojay

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

// Flutter's default SurfaceView rendering gets its underlying Surface torn
// down and not cleanly reattached when the app resumes from background on
// some OEM Android builds (MIUI/Redmi in particular) — the window is still
// there but nothing ever gets drawn into it again, which is what shows up
// as a black screen that only a force-kill clears. TextureView is composited
// as an ordinary view instead of its own hardware layer, so it doesn't hit
// this class of resume bug. (Disabling Impeller, tried previously, didn't
// fix it — that only swaps the graphics backend, not the Surface/Texture
// that backend draws into.)
class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode = RenderMode.texture
}
