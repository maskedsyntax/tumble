package com.tumble.model

/**
 * What the shooter owns. One-time purchases only — no subscriptions, per the
 * product's whole stance. Ordered so the highest owned tier wins.
 *
 * Ported from `app/TumbleKit/Model/Entitlement.swift`.
 */
enum class Entitlement(val id: String) {
    FREE("free"),
    PLUS("plus"),
    UNLIMITED("unlimited");

    /** Shots granted each morning. `null` means no daily limit (Unlimited). */
    val dailyQuota: Int?
        get() = when (this) {
            FREE -> 12
            PLUS -> 72
            UNLIMITED -> null
        }

    /** Display price mirroring the site's Pricing cards. */
    val priceLabel: String
        get() = when (this) {
            FREE -> "Free"
            PLUS -> "$5.99"
            UNLIMITED -> "$11.99"
        }

    /** The Play Billing product id for the paid tiers. */
    val productId: String?
        get() = when (this) {
            FREE -> null
            PLUS -> "com.tumble.plus"
            UNLIMITED -> "com.tumble.unlimited"
        }

    companion object {
        fun fromId(raw: String?): Entitlement =
            entries.firstOrNull { it.id == raw } ?: FREE

        /** Resolve the highest tier from a set of owned product ids. */
        fun highest(fromProductIDs: Set<String>): Entitlement {
            var best = FREE
            for (tier in entries) {
                val pid = tier.productId
                if (pid != null && pid in fromProductIDs && tier.ordinal > best.ordinal) {
                    best = tier
                }
            }
            return best
        }
    }
}
