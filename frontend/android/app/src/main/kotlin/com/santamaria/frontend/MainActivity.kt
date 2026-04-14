package com.santamaria.frontend

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }

    private fun createNotificationChannels() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        // ALARM — importance MAX, custom sound, bypasses DND
        val alarmSoundUri = Uri.parse(
            "android.resource://${packageName}/raw/alarm_sound"
        )
        val alarmAudioAttr = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val alarmChannel = NotificationChannel(
            "santa_maria_alarm",
            "Alarm Santa Maria",
            NotificationManager.IMPORTANCE_MAX
        ).apply {
            description = "Notifikasi darurat: order baru, permintaan barang supplier"
            setSound(alarmSoundUri, alarmAudioAttr)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
            setBypassDnd(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(alarmChannel)

        // HIGH — importance HIGH, default sound
        val highChannel = NotificationChannel(
            "santa_maria_high",
            "Prioritas Tinggi Santa Maria",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifikasi penting: persetujuan, penolakan, update status"
            enableVibration(true)
        }
        manager.createNotificationChannel(highChannel)

        // NORMAL — importance DEFAULT, silent badge
        val normalChannel = NotificationChannel(
            "santa_maria_normal",
            "Normal Santa Maria",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Notifikasi umum: laporan, update minor"
        }
        manager.createNotificationChannel(normalChannel)
    }
}
