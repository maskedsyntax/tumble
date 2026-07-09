package com.tumble.notif

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.content.getSystemService
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Duration
import java.time.LocalTime
import java.time.ZoneId

/**
 * Schedules the daily 08:00 local reminder via WorkManager (the Android stand-in
 * for iOS's repeating `UNCalendarNotificationTrigger`). Permission is requested
 * value-first, after the first develop — never on cold launch.
 */
object RollReminders {
    const val CHANNEL_ID = "roll.reminders"
    const val NOTIFICATION_ID = 1001
    private const val WORK_NAME = "tumble.freshRoll.daily"
    private const val MORNING_HOUR = 8

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService<NotificationManager>() ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Fresh roll",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply { description = "A gentle nudge when your daily roll refills." },
            )
        }
    }

    fun schedule(context: Context) {
        ensureChannel(context)
        val request = PeriodicWorkRequestBuilder<RollReminderWorker>(Duration.ofDays(1))
            .setInitialDelay(initialDelayToMorning())
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }

    private fun initialDelayToMorning(): Duration {
        val zone = ZoneId.systemDefault()
        val now = java.time.ZonedDateTime.now(zone)
        var next = now.with(LocalTime.of(MORNING_HOUR, 0))
        if (!next.isAfter(now)) next = next.plusDays(1)
        return Duration.between(now, next)
    }
}
