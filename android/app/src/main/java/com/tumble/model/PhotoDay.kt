package com.tumble.model

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * A computed daily collection of prints. The photos remain stored as individual
 * Room rows; this helper only shapes them for Drawer and archive screens.
 *
 * Ported from `app/TumbleKit/Model/PhotoDay.swift`.
 */
data class PhotoDay(
    val dayStart: LocalDate,
    val displayTitle: String,
    val photos: List<Photo>,
) {
    val totalCount: Int get() = photos.size
    val developedCount: Int get() = photos.count { it.isDeveloped }

    companion object {
        private val fallbackFormat: DateTimeFormatter =
            DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.US)

        fun group(
            photos: List<Photo>,
            zone: ZoneId = ZoneId.systemDefault(),
            now: Instant = Instant.now(),
        ): List<PhotoDay> =
            photos
                .groupBy { it.capturedAt.atZone(zone).toLocalDate() }
                .map { (dayStart, dayPhotos) ->
                    PhotoDay(
                        dayStart = dayStart,
                        displayTitle = title(dayStart, zone, now),
                        photos = dayPhotos.sortedByDescending { it.capturedAt },
                    )
                }
                .sortedByDescending { it.dayStart }

        private fun title(dayStart: LocalDate, zone: ZoneId, now: Instant): String {
            val today = now.atZone(zone).toLocalDate()
            return when (dayStart) {
                today -> "Today"
                today.minusDays(1) -> "Yesterday"
                else -> dayStart.format(fallbackFormat)
            }
        }
    }
}
