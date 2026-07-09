package com.tumble

import com.tumble.model.Photo
import com.tumble.model.PhotoDay
import com.tumble.model.PhotoSource
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset

/** Mirrors `PhotoDayTests` in `TumbleKitTests/PhotoDayTests.swift`. */
class PhotoDayTest {
    private val zone = ZoneOffset.UTC

    private fun instant(day: Int, hour: Int = 12): Instant =
        LocalDateTime.of(2026, 7, day, hour, 0).toInstant(ZoneOffset.UTC)

    private fun photos(count: Int, base: Instant, developed: Int = 0): List<Photo> =
        (0 until count).map { index ->
            Photo.create(capturedAt = base.plusSeconds(index * 60L)).copy(
                isDeveloped = index < developed,
                developProgress = if (index < developed) 1.0 else 0.0,
            )
        }

    @Test fun groupsMixedDailyCountsNewestDayFirst() {
        val now = instant(5, 18)
        val all = photos(7, instant(1)) +
            photos(9, instant(2)) +
            photos(12, instant(3)) +
            photos(60, instant(4)) +
            photos(72, instant(5))

        val days = PhotoDay.group(all, zone, now)

        assertEquals(listOf(72, 60, 12, 9, 7), days.map { it.totalCount })
        assertEquals("Today", days.first().displayTitle)
        assertEquals("Yesterday", days.drop(1).first().displayTitle)
    }

    @Test fun sortsPhotosNewestFirstInsideEachDay() {
        val morning = Photo.create(capturedAt = instant(1, 8))
        val afternoon = Photo.create(capturedAt = instant(1, 15))
        val night = Photo.create(capturedAt = instant(1, 22))

        val day = PhotoDay.group(listOf(afternoon, morning, night), zone, instant(2)).first()

        assertEquals(listOf(night.id, afternoon.id, morning.id), day.photos.map { it.id })
    }

    @Test fun countsDevelopedPhotos() {
        val dayPhotos = photos(12, instant(1), developed = 5)
        val day = PhotoDay.group(dayPhotos, zone, instant(1)).first()

        assertEquals(12, day.totalCount)
        assertEquals(5, day.developedCount)
    }

    @Test fun sourceRoundTrips() {
        val locked = Photo.create(source = PhotoSource.LOCKSCREEN)
        assertEquals(PhotoSource.LOCKSCREEN.value, locked.source)
    }
}
