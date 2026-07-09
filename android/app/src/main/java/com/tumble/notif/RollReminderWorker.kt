package com.tumble.notif

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.tumble.MainActivity
import com.tumble.R

/**
 * Posts the daily "your fresh roll is ready" nudge — the habit loop around the
 * morning reset. Mirrors `app/TumbleKit/Notifications/RollNotificationScheduler.swift`.
 */
class RollReminderWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val manager = applicationContext.getSystemService<NotificationManager>() ?: return Result.success()

        val open = Intent(applicationContext, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pending = PendingIntent.getActivity(
            applicationContext, 0, open,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(applicationContext, RollReminders.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Your fresh roll is ready")
            .setContentText("Twelve new shots are waiting.")
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        manager.notify(RollReminders.NOTIFICATION_ID, notification)
        return Result.success()
    }
}
