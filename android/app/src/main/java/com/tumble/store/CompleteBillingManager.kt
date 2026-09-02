package com.tumble.store

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.tumble.studio.AccessState

class CompleteBillingManager(context: Context, private val productId: String) {
    var accessState by mutableStateOf<AccessState>(AccessState.Free); private set
    var product by mutableStateOf<ProductDetails?>(null); private set
    var message by mutableStateOf<String?>(null); private set

    private val client = BillingClient.newBuilder(context.applicationContext)
        .setListener { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                purchases.orEmpty().forEach(::handlePurchase)
            } else if (result.responseCode != BillingClient.BillingResponseCode.USER_CANCELED) {
                message = result.debugMessage.ifBlank { "The purchase could not be completed." }
            }
        }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    fun connect() {
        if (client.isReady) { refresh(); return }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    loadProduct()
                    refresh()
                } else message = result.debugMessage
            }
            override fun onBillingServiceDisconnected() = Unit
        })
    }

    fun launch(activity: Activity) {
        val details = product ?: run { message = "The store price is still loading."; return }
        val offer = details.oneTimePurchaseOfferDetailsList?.firstOrNull()
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(details).apply {
            offer?.offerToken?.let(::setOfferToken)
        }.build()
        client.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(productParams)).build())
    }

    fun refresh() {
        if (!client.isReady) { connect(); return }
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                accessState = if (purchases.any { productId in it.products && it.purchaseState == com.android.billingclient.api.Purchase.PurchaseState.PURCHASED }) AccessState.Complete else AccessState.Free
                purchases.forEach(::handlePurchase)
            }
        }
    }

    fun clearMessage() { message = null }

    private fun loadProduct() {
        val query = QueryProductDetailsParams.Product.newBuilder().setProductId(productId).setProductType(BillingClient.ProductType.INAPP).build()
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(listOf(query)).build()) { result, products ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) product = products.productDetailsList.firstOrNull()
        }
    }

    private fun handlePurchase(purchase: com.android.billingclient.api.Purchase) {
        if (productId !in purchase.products || purchase.purchaseState != com.android.billingclient.api.Purchase.PurchaseState.PURCHASED) return
        accessState = AccessState.Complete
        if (!purchase.isAcknowledged) {
            client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()) { result ->
                if (result.responseCode != BillingClient.BillingResponseCode.OK) message = "Purchase received, but acknowledgement will be retried."
            }
        }
    }
}
