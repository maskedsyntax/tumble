package com.tumble.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Duration
import java.time.Instant
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

enum class PhotoSource(val value: String) {
    APP("app"),
    LOCKSCREEN("lockscreen"),
}

/**
 * A single shot. Stored as Room metadata; the pixels live on disk (see
 * `PhotoStore`). A photo starts life *undeveloped* — blank and face-down in the
 * Drawer — until the shooter shakes it to life.
 *
 * Ported from `app/TumbleKit/Model/Photo.swift`.
 */
@Entity(tableName = "photos")
data class Photo(
    /** Stable identity, also used to name the image files on disk. */
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val capturedAt: Instant = Instant.now(),

    /** False until shake-to-develop finishes; controls the blank face-down state. */
    val isDeveloped: Boolean = false,
    /** 0…1 develop progress, persisted so a half-shaken print resumes where it was. */
    val developProgress: Double = 0.0,

    /** File names within the app images directory. */
    val rawImageName: String? = null,
    val developedImageName: String? = null,

    /**
     * Drawer placement, generated once at capture so the scatter is stable
     * across launches (never a grid). Percent offsets + rotation in degrees.
     */
    val scatterX: Double = 0.0,
    val scatterY: Double = 0.0,
    val rotation: Double = 0.0,

    val caption: String? = null,
    /** Where the shot came from: the app or the lock-screen surface. */
    val source: String = PhotoSource.APP.value,
) {
    companion object {
        /** How aged the print looks maps over ~30 days. */
        val agingSpan: Duration = Duration.ofDays(30)

        /**
         * A loose, hand-tossed placement in the drawer area (percent offsets,
         * gentle rotation) — echoes the site's `DrawerMockup` scatter.
         */
        fun randomScatter(random: Random = Random.Default): Triple<Double, Double, Double> =
            Triple(
                random.nextDouble(2.0, 52.0),
                random.nextDouble(2.0, 70.0),
                random.nextDouble(-12.0, 12.0),
            )

        /** Mirror of the Swift `init` — draws a stable scatter at capture time. */
        fun create(
            id: String = UUID.randomUUID().toString(),
            capturedAt: Instant = Instant.now(),
            source: PhotoSource = PhotoSource.APP,
            random: Random = Random.Default,
        ): Photo {
            val (x, y, rotation) = randomScatter(random)
            return Photo(
                id = id,
                capturedAt = capturedAt,
                scatterX = x,
                scatterY = y,
                rotation = rotation,
                source = source.value,
            )
        }
    }
}

/**
 * How aged the print looks, 0 (fresh) → 1 (fully warmed/faded), mapped over
 * `agingSpan`. Purely a function of elapsed time — no stored state, so prints
 * visibly warm as the days pass.
 */
fun Photo.ageFraction(now: Instant = Instant.now()): Double {
    val elapsedMs = Duration.between(capturedAt, now).toMillis().toDouble()
    val spanMs = Photo.agingSpan.toMillis().toDouble()
    return min(1.0, max(0.0, elapsedMs / spanMs))
}
