package com.dramastream.android

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.util.Log
import android.util.Rational
import android.widget.VideoView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
// import com.google.android.gms.cast.framework.CastContext

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.dramastream.android/pip"
    private var videoUrl: String? = null
    private var isPlaying = false
    private var playbackPosition: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
       // CastContext.getSharedInstance(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateVideoState" -> {
                    val args = call.arguments as? Map<*, *>
                    isPlaying = args?.get("isPlaying") as? Boolean ?: false
                    videoUrl = args?.get("videoUrl") as? String
                    playbackPosition = args?.get("position") as? Int ?: 0

                    result.success(null)
                }
                "videoProgress" -> {
                    val args = call.arguments as? Map<*, *>
                    playbackPosition = args?.get("position") as? Int ?: 0

                    result.success(null)
                }
                "enterPipMode" -> {
                    val args = call.arguments as? Map<*, *>
                    videoUrl = args?.get("videoUrl") as? String
                    playbackPosition = (args?.get("position") as? Int) ?: 0

                    enterPipMode()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()

        // Now, it will only enter PIP if video is playing
        if (isPlaying) {
            enterPipMode()
        } else {
            println("Skipping PIP mode - No video playing.")
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspectRatio = Rational(16, 9)
            val pipParams = PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)
                .build()
            enterPictureInPictureMode(pipParams)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        
        // Send PIP closed event back to Flutter
        if (!isInPictureInPictureMode) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("pipClosed", playbackPosition)
        }
    }
}