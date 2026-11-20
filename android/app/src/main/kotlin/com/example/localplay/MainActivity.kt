package com.example.localplay

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val channelName = "offline_games/hotspot"
    private val requestCode = 1001
    private lateinit var wifiManager: WifiManager
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var pending: MethodChannel.Result? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startHotspot(result)
                    "stop" -> {
                        reservation?.close()
                        reservation = null
                        result.success(null)
                    }
                    "address" -> result.success(hotspotAddress())
                    "acquireMulticastLock" -> {
                        try {
                            if (multicastLock == null) {
                                multicastLock = wifiManager.createMulticastLock("offline_games_mdns").apply {
                                    setReferenceCounted(false)
                                    acquire()
                                }
                            }
                            result.success(null)
                        } catch (e: Exception) { result.error("MULTICAST", e.message, null) }
                    }
                    "releaseMulticastLock" -> {
                        multicastLock?.let { if (it.isHeld) it.release() }
                        multicastLock = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requiredPermission(): String =
        if (Build.VERSION.SDK_INT >= 33) Manifest.permission.NEARBY_WIFI_DEVICES
        else Manifest.permission.ACCESS_FINE_LOCATION

    private fun startHotspot(result: MethodChannel.Result) {
        if (reservation != null) {
            result.error("ALREADY_RUNNING", "Hotspot is already running", null)
            return
        }
        if (pending != null) {
            result.error("BUSY", "Hotspot request in progress", null)
            return
        }
        pending = result
        val permission = requiredPermission()
        if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(permission), requestCode)
        } else {
            createHotspot()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == this.requestCode) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                createHotspot()
            } else {
                pending?.error("PERMISSION", "Wi-Fi permission denied", null)
                pending = null
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun createHotspot() {
        try {
            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(res: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = res
                    val ssid: String
                    val password: String
                    if (Build.VERSION.SDK_INT >= 30) {
                        val config = res.softApConfiguration
                        ssid = config.ssid ?: "Unknown"
                        password = config.passphrase ?: ""
                    } else {
                        val config = res.wifiConfiguration
                        ssid = config?.SSID ?: "Unknown"
                        password = config?.preSharedKey ?: ""
                    }
                    pending?.success(mapOf(
                        "ssid" to ssid,
                        "password" to password,
                        "address" to hotspotAddress()
                    ))
                    pending = null
                }

                override fun onStopped() {
                    reservation = null
                    pending?.error("STOPPED", "Hotspot stopped unexpectedly", null)
                    pending = null
                }

                override fun onFailed(reason: Int) {
                    pending?.error("HOTSPOT_FAILED", "Android hotspot failed (code $reason). Check Location/Wi-Fi settings.", null)
                    pending = null
                }
            }, null)
        } catch (e: Exception) {
            pending?.error("HOTSPOT_ERROR", e.message, null)
            pending = null
        }
    }

    private fun hotspotAddress(): String? {
        val interfaces = NetworkInterface.getNetworkInterfaces()?.toList()
            ?: return null

        // Prefer the hotspot interface (temporary fix for your device)
        val hotspotInterface = interfaces.find { it.name == "wlan2" }

        val address = hotspotInterface?.inetAddresses?.toList()
            ?.filterIsInstance<java.net.Inet4Address>()
            ?.firstOrNull { !it.isLoopbackAddress }

        return address?.hostAddress
    }
}
