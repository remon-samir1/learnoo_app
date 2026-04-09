package com.example.learnoo

import android.app.ActivityManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity with Screen Protection implementation for Android
 *
 * ARCHITECTURE:
 * - Uses FLAG_SECURE for hardware-level screenshot/screen recording blocking
 * - Maintains reference counting for nested protected screens
 * - Provides global and local protection modes
 *
 * SECURITY FEATURES:
 * - FLAG_SECURE: Blocks screenshots, screen recording, and recent apps preview
 * - Protection is hardware-level on Android - cannot be bypassed by apps
 * - Recent apps thumbnail is black when FLAG_SECURE is active
 *
 * PLATFORM CHANNELS:
 * - MethodChannel: com.learnoo.screen_protection (commands)
 * - EventChannel: com.learnoo.screen_protection/events (not used on Android - FLAG_SECURE is silent)
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val SCREEN_PROTECTION_CHANNEL = "com.learnoo.screen_protection"
        private const val SCREEN_PROTECTION_EVENTS_CHANNEL = "com.learnoo.screen_protection/events"
        
        // Native state tracking
        @Volatile
        private var isGlobalProtectionEnabled = false
        
        @Volatile
        private var localProtectionCount = 0
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Note: FlutterActivity handles the FlutterEngine setup
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup method channel for commands
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_PROTECTION_CHANNEL
        )
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        
        // Setup event channel (for consistency with iOS, though mostly unused on Android)
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_PROTECTION_EVENTS_CHANNEL
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    /**
     * Handle method calls from Flutter
     */
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enableGlobalProtection" -> {
                enableGlobalProtection()
                result.success(true)
            }
            "disableGlobalProtection" -> {
                disableGlobalProtection()
                result.success(true)
            }
            "enableLocalProtection" -> {
                enableLocalProtection()
                result.success(true)
            }
            "disableLocalProtection" -> {
                disableLocalProtection()
                result.success(true)
            }
            "getProtectionStatus" -> {
                result.success(getProtectionStatus())
            }
            "enableBlurOverlay" -> {
                // No-op on Android - FLAG_SECURE handles this automatically
                result.success(true)
            }
            "disableBlurOverlay" -> {
                // No-op on Android
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Enable global protection for the entire app
     * This sets FLAG_SECURE on the main window and persists until disabled
     */
    private fun enableGlobalProtection() {
        runOnUiThread {
            try {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                isGlobalProtectionEnabled = true
                android.util.Log.d("ScreenProtection", "Global protection enabled")
            } catch (e: Exception) {
                android.util.Log.e("ScreenProtection", "Failed to enable global protection", e)
            }
        }
    }

    /**
     * Disable global protection
     * Note: If local screens still have protection, FLAG_SECURE remains
     */
    private fun disableGlobalProtection() {
        runOnUiThread {
            try {
                // Only remove FLAG_SECURE if no local protection is active
                if (localProtectionCount <= 0) {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                isGlobalProtectionEnabled = false
                android.util.Log.d("ScreenProtection", "Global protection disabled")
            } catch (e: Exception) {
                android.util.Log.e("ScreenProtection", "Failed to disable global protection", e)
            }
        }
    }

    /**
     * Enable local protection for current screen
     * Uses reference counting - multiple screens can request protection
     */
    private fun enableLocalProtection() {
        runOnUiThread {
            try {
                localProtectionCount++
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                android.util.Log.d("ScreenProtection", "Local protection enabled (count: $localProtectionCount)")
            } catch (e: Exception) {
                android.util.Log.e("ScreenProtection", "Failed to enable local protection", e)
                localProtectionCount-- // Rollback on failure
            }
        }
    }

    /**
     * Disable local protection for current screen
     * Decrements reference count, removes FLAG_SECURE if count reaches 0
     */
    private fun disableLocalProtection() {
        runOnUiThread {
            try {
                if (localProtectionCount > 0) {
                    localProtectionCount--
                }
                
                // Only remove FLAG_SECURE if count is 0 and global is disabled
                if (localProtectionCount <= 0 && !isGlobalProtectionEnabled) {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                
                android.util.Log.d("ScreenProtection", "Local protection disabled (count: $localProtectionCount)")
            } catch (e: Exception) {
                android.util.Log.e("ScreenProtection", "Failed to disable local protection", e)
                localProtectionCount++ // Rollback on failure
            }
        }
    }

    /**
     * Get current protection status
     */
    private fun getProtectionStatus(): Map<String, Any> {
        val hasSecureFlag = (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
        
        return mapOf(
            "platform" to "android",
            "apiLevel" to Build.VERSION.SDK_INT,
            "isGlobalEnabled" to isGlobalProtectionEnabled,
            "localProtectionCount" to localProtectionCount,
            "hasSecureFlag" to hasSecureFlag,
            "isSecure" to hasSecureFlag
        )
    }

    override fun onResume() {
        super.onResume()
        // Re-apply FLAG_SECURE if protection is active (handles edge cases)
        if (isGlobalProtectionEnabled || localProtectionCount > 0) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onPause() {
        super.onPause()
        // FLAG_SECURE persists automatically, but we log for debugging
        android.util.Log.d("ScreenProtection", "Activity paused - protection persists via FLAG_SECURE")
    }

    override fun onDestroy() {
        // Cleanup channels
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        super.onDestroy()
    }
}
