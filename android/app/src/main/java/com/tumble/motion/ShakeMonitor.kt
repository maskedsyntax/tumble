package com.tumble.motion

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import com.tumble.develop.Develop
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlin.math.sqrt

/**
 * Reads the accelerometer and reports shake "jolts" — the energy that drives
 * shake-to-develop. Gravity is subtracted so only real motion counts. When the
 * sensor is unavailable the UI falls back to a press-and-hold develop (also the
 * reduce-motion path). Ported from `app/TumbleKit/Motion/ShakeMonitor.swift`.
 */
class ShakeMonitor @Inject constructor(
    @ApplicationContext context: Context,
) : SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    val isAvailable: Boolean get() = accelerometer != null

    /** Called on each jolt with a normalized energy (~0…1). */
    var onShake: ((Double) -> Unit)? = null

    fun start() {
        val sensor = accelerometer ?: return
        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    fun stop() {
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        // Android reports m/s²; convert to g so the maths match Core Motion.
        val magnitudeG = sqrt((x * x + y * y + z * z).toDouble()) / Develop.GRAVITY
        Develop.shakeEnergy(magnitudeG)?.let { energy -> onShake?.invoke(energy) }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
