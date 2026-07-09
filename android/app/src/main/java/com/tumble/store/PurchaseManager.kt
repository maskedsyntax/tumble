package com.tumble.store

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.tumble.data.TumblePrefs
import com.tumble.model.Entitlement
import com.tumble.roll.RollManager
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Google Play Billing, one-time purchases only. Loads the Plus and Unlimited
 * products, tracks owned entitlements, resolves the highest tier, and mirrors it
 * into prefs so the Roll (and widget) pick it up. No subscriptions, ever.
 * Mirrors `app/TumbleKit/Store/PurchaseManager.swift`.
 */
@Singleton
class PurchaseManager @Inject constructor(
    @ApplicationContext context: Context,
    private val prefs: TumblePrefs,
    private val roll: RollManager,
) : PurchasesUpdatedListener {

    private val productIds = listOf(
        Entitlement.PLUS.productId!!,
        Entitlement.UNLIMITED.productId!!,
    )

    private val _products = MutableStateFlow<Map<String, ProductDetails>>(emptyMap())
    val products: StateFlow<Map<String, ProductDetails>> = _products.asStateFlow()

    private val _ownedIds = MutableStateFlow(setOfNotNull(prefs.entitlement.productId))
    val ownedIds: StateFlow<Set<String>> = _ownedIds.asStateFlow()

    val entitlement: Entitlement get() = Entitlement.highest(_ownedIds.value)

    private val billingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build(),
        )
        .build()

    fun start() {
        if (billingClient.isReady) {
            queryProducts(); queryPurchases()
            return
        }
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProducts()
                    queryPurchases()
                }
            }

            override fun onBillingServiceDisconnected() { /* retried on next start() */ }
        })
    }

    /** Formatted store price, falling back to the site's static label offline. */
    fun price(tier: Entitlement): String {
        val details = tier.productId?.let { _products.value[it] }
        return details?.oneTimePurchaseOfferDetails?.formattedPrice ?: tier.priceLabel
    }

    fun purchase(activity: Activity, tier: Entitlement) {
        val details = tier.productId?.let { _products.value[it] } ?: return
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .build(),
                ),
            )
            .build()
        billingClient.launchBillingFlow(activity, params)
    }

    /** Restore prior purchases (one-time buys are recoverable on any device). */
    fun restore() = queryPurchases()

    private fun queryProducts() {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                productIds.map { id ->
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(id)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
                },
            )
            .build()
        billingClient.queryProductDetailsAsync(params) { _, details ->
            _products.value = details.associateBy { it.productId }
        }
    }

    private fun queryPurchases() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()
        billingClient.queryPurchasesAsync(params) { _, purchases ->
            purchases.forEach { handlePurchase(it) }
            applyOwned(
                purchases
                    .filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }
                    .flatMap { it.products }
                    .toSet(),
            )
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            purchases.forEach { handlePurchase(it) }
            queryPurchases()
        }
    }

    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED && !purchase.isAcknowledged) {
            billingClient.acknowledgePurchase(
                AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build(),
            ) { /* acknowledged */ }
        }
    }

    private fun applyOwned(ids: Set<String>) {
        _ownedIds.value = ids
        roll.entitlement = Entitlement.highest(ids) // setter mirrors into prefs + rolls over
    }
}
