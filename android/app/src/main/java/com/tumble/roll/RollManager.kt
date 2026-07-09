package com.tumble.roll

import com.tumble.model.Entitlement
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.max

/**
 * The daily Roll — the product's whole thesis. Grants a fresh quota of shots
 * each morning (local midnight), enforces it, and never nags. Backed by a
 * [RollStore] so a shared implementation lets the widget/tile read the same
 * counter.
 *
 * Dependencies (store, zone, clock) are injectable so the rollover and quota
 * rules are unit-testable without a device. Ported from
 * `app/TumbleKit/Roll/RollManager.swift`.
 */
class RollManager(
    private val store: RollStore,
    private val zone: ZoneId = ZoneId.systemDefault(),
    private val now: () -> Instant = { Instant.now() },
) {
    /** The owned tier; drives the quota. */
    var entitlement: Entitlement
        get() = store.entitlement
        set(value) {
            store.entitlement = value
            rolloverIfNeeded()
        }

    /** Shots taken so far today. */
    var consumedToday: Int = store.consumedToday
        private set

    private var lastResetDay: LocalDate =
        if (store.lastResetEpochDay >= 0) LocalDate.ofEpochDay(store.lastResetEpochDay)
        else LocalDate.MIN

    init {
        rolloverIfNeeded()
    }

    // MARK: Derived state

    /** Daily allowance; `null` for Unlimited. */
    val quota: Int? get() = entitlement.dailyQuota
    val isUnlimited: Boolean get() = quota == null

    /** Shots left today; `null` for Unlimited. */
    val remaining: Int? get() = quota?.let { max(0, it - consumedToday) }

    val canShoot: Boolean get() = isUnlimited || (remaining ?: 0) > 0

    /** Quiet counter copy for the viewfinder, e.g. "7 left today". */
    val remainingLabel: String
        get() = if (isUnlimited) "Unlimited" else "${remaining ?: 0} left today"

    val remainingShotsSentence: String
        get() = if (isUnlimited) "Unlimited shots." else shotsLeftSentence(remaining ?: 0)

    // MARK: Actions

    /** Call when the app becomes active to pick up a midnight rollover. */
    fun refresh() = rolloverIfNeeded()

    /**
     * Spend one shot. Returns false when the roll is empty (caller shows the
     * calm "fresh at sunrise" state — never a hard modal).
     */
    fun consumeShot(): Boolean {
        rolloverIfNeeded()
        if (!canShoot) return false
        if (!isUnlimited) {
            consumedToday += 1
            store.consumedToday = consumedToday
        }
        return true
    }

    private fun rolloverIfNeeded() {
        val today = now().atZone(zone).toLocalDate()
        if (today == lastResetDay) return
        consumedToday = 0
        lastResetDay = today
        store.consumedToday = 0
        store.lastResetEpochDay = today.toEpochDay()
    }

    companion object {
        fun shotsLeftSentence(count: Int): String =
            "$count ${if (count == 1) "shot" else "shots"} left today."
    }
}
