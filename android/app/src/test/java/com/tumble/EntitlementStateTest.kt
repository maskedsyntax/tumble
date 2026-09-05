package com.tumble

import com.tumble.studio.AccessState
import com.tumble.studio.EntitlementState
import org.junit.Assert.assertEquals
import org.junit.Test

class EntitlementStateTest {
    @Test fun signedOutLocalPurchaseStillUnlocksComplete() {
        assertEquals(
            AccessState.Complete,
            EntitlementState(localStore = AccessState.Complete).effective,
        )
    }

    @Test fun accountPurchaseUnlocksWithoutLocalStoreOwnership() {
        assertEquals(
            AccessState.Complete,
            EntitlementState(account = AccessState.Complete).effective,
        )
    }

    @Test fun legacyPackOwnershipIsUnionedAcrossSources() {
        assertEquals(
            AccessState.LegacyPacks(setOf("nineties", "summer")),
            EntitlementState(
                localStore = AccessState.LegacyPacks(setOf("nineties")),
                account = AccessState.LegacyPacks(setOf("summer")),
            ).effective,
        )
    }

    @Test fun signingOutOnlyRemovesAccountAccess() {
        val signedIn = EntitlementState(AccessState.Free, AccessState.Complete)
        val signedOut = signedIn.copy(account = AccessState.Free)
        assertEquals(AccessState.Complete, signedIn.effective)
        assertEquals(AccessState.Free, signedOut.effective)
    }
}
