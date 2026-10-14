package com.example.productivity_hub

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "productivity_hub/usage"

    override fun configureFlutterEngine(
        flutterEngine: io.flutter.embedding.engine.FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // Check if Usage Access permission is enabled
                "hasUsagePermission" -> {
                    result.success(hasUsagePermission())
                }

                // Open Android Usage Access settings
                "openUsageSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // Get app usage statistics
                "getUsageStats" -> {
                    try {
                        result.success(getUsageStats())
                    } catch (e: Exception) {
                        result.error(
                            "USAGE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps =
            getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )

        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStats(): List<Map<String, Any>> {

        if (!hasUsagePermission()) {
            return emptyList()
        }

        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE)
                    as UsageStatsManager

        val endTime = System.currentTimeMillis()

        // Get today's usage
        val startTime = endTime - (24 * 60 * 60 * 1000)

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val packageManager = packageManager

        val usageList = mutableListOf<Map<String, Any>>()

        for (usage in stats) {

            val totalTime = usage.totalTimeInForeground

            // Ignore apps with zero usage
            if (totalTime <= 0) continue

            try {
                val appInfo = packageManager.getApplicationInfo(
                    usage.packageName,
                    0
                )

                val appName =
                    packageManager.getApplicationLabel(appInfo).toString()

                usageList.add(
                    mapOf(
                        "packageName" to usage.packageName,
                        "appName" to appName,
                        "usageTime" to totalTime
                    )
                )

            } catch (e: Exception) {
                // Ignore apps that cannot be found
            }
        }

        // Sort by most used app
        return usageList.sortedByDescending {
            it["usageTime"] as Long
        }
    }
}