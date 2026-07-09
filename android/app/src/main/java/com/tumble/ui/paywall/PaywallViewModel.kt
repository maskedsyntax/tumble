package com.tumble.ui.paywall

import android.app.Activity
import androidx.lifecycle.ViewModel
import com.tumble.model.Entitlement
import com.tumble.store.PurchaseManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

@HiltViewModel
class PaywallViewModel @Inject constructor(
    private val purchases: PurchaseManager,
) : ViewModel() {

    val ownedIds: StateFlow<Set<String>> = purchases.ownedIds

    init {
        purchases.start()
    }

    fun price(tier: Entitlement): String = purchases.price(tier)

    /** A tier is "owned" if the shooter's highest tier is at least this one. */
    fun owned(tier: Entitlement, owned: Set<String>): Boolean =
        Entitlement.highest(owned).ordinal >= tier.ordinal

    fun purchase(activity: Activity, tier: Entitlement) = purchases.purchase(activity, tier)

    fun restore() = purchases.restore()
}
