package com.tumble

import android.app.Application
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesAreCompletedBy
import com.revenuecat.purchases.PurchasesConfiguration

class TumbleApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.REVENUECAT_API_KEY.isNotBlank()) {
            Purchases.configure(
                PurchasesConfiguration.Builder(this, BuildConfig.REVENUECAT_API_KEY)
                    .purchasesAreCompletedBy(PurchasesAreCompletedBy.MY_APP)
                    .build(),
            )
        }
    }
}
