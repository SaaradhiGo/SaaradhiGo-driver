package com.saaradhigo.driver

import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app draws its branded placeholder map unless a real key was built in.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "saaradhigo/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "hasKey") result.success(hasMapsKey())
                else result.notImplemented()
            }
        // The offer chime: sound and vibration as the ringer mode allows.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "saaradhigo/alert")
            .setMethodCallHandler { call, result ->
                if (call.method == "offer") {
                    offerAlert()
                    result.success(null)
                } else result.notImplemented()
            }
    }

    private fun offerAlert() {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notifications = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val dnd = notifications.currentInterruptionFilter > NotificationManager.INTERRUPTION_FILTER_ALL
        val mode = if (dnd) AudioManager.RINGER_MODE_SILENT else audio.ringerMode
        if (mode == AudioManager.RINGER_MODE_SILENT) return
        if (mode == AudioManager.RINGER_MODE_NORMAL) {
            try {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                RingtoneManager.getRingtone(applicationContext, uri)?.apply {
                    audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    play()
                }
            } catch (e: Exception) {
                // No sound is better than a crash on an offer.
            }
        }
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return
        val pattern = longArrayOf(0, 300, 150, 300)
        if (Build.VERSION.SDK_INT >= 26) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    @Suppress("DEPRECATION")
    private fun hasMapsKey(): Boolean {
        val key = try {
            packageManager
                .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                .metaData?.getString("com.google.android.geo.API_KEY")
        } catch (e: Exception) {
            null
        }?.trim().orEmpty()
        return key.isNotEmpty() &&
            !key.startsWith("\${") &&
            !key.contains("YOUR_", ignoreCase = true) &&
            !key.contains("PLACEHOLDER", ignoreCase = true)
    }
}
