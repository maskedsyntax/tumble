package com.tumble.develop

import kotlin.math.min

/**
 * The shake-to-develop maths, factored out of the UI so it matches iOS exactly
 * and is unit-testable. Ported from `DevelopView.swift` + `ShakeMonitor.swift`.
 *
 * A print's `developProgress` runs 0…1. Shake jolts push it up; a press-and-hold
 * fallback advances it smoothly for the emulator / reduce-motion path.
 */
object Develop {
    /** Only jolts above this (in g, gravity removed) count as a real shake. */
    const val JOLT_THRESHOLD = 0.12

    /** Shake energy is scaled by this before being added to progress. */
    const val SHAKE_ENERGY_SCALE = 0.045

    /** Progress added per ~16ms tick while the hold button is pressed. */
    const val HOLD_STEP = 0.012

    /** Minimum gap between develop haptics, milliseconds. */
    const val HAPTIC_INTERVAL_MS = 90L

    /** Standard gravity, m/s², to convert Android accelerometer readings to g. */
    const val GRAVITY = 9.80665

    /**
     * Normalized shake energy (~0…1) from a raw accelerometer magnitude in g,
     * or `null` if the motion is below the jolt threshold. Mirrors the Core
     * Motion path: `jolt = magnitude - 1g`, `energy = min(1, jolt / 2)`.
     */
    fun shakeEnergy(magnitudeG: Double): Double? {
        val jolt = magnitudeG - 1.0
        return if (jolt > JOLT_THRESHOLD) min(1.0, jolt / 2.0) else null
    }

    /** How much a single shake jolt advances progress. */
    fun shakeAdvance(energy: Double): Double = energy * SHAKE_ENERGY_SCALE

    /** Clamp a progress value into the developed range and cap at fully done. */
    fun advanced(progress: Double, amount: Double): Double =
        min(1.0, (progress + amount).coerceAtLeast(0.0))

    /** A print is fully developed once progress reaches 1. */
    fun isDeveloped(progress: Double): Boolean = progress >= 1.0
}
