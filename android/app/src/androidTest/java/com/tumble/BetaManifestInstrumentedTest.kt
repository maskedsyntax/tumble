package com.tumble

import android.Manifest
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class BetaManifestInstrumentedTest {
    @Test
    fun tumbleThreePackageAndPrivacyContract() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val packageInfo = context.packageManager.getPackageInfo(
            context.packageName,
            PackageManager.PackageInfoFlags.of(
                (PackageManager.GET_PERMISSIONS or PackageManager.GET_CONFIGURATIONS).toLong(),
            ),
        )
        val permissions = packageInfo.requestedPermissions?.toSet().orEmpty()

        assertEquals("com.tumble.app", context.packageName)
        assertTrue(Manifest.permission.CAMERA in permissions)
        assertTrue(Manifest.permission.INTERNET in permissions)
        assertFalse(Manifest.permission.POST_NOTIFICATIONS in permissions)
        assertTrue("com.android.vending.BILLING" in permissions)
        assertEquals(0, packageInfo.applicationInfo!!.flags and ApplicationInfo.FLAG_ALLOW_BACKUP)

        val cameraFeature = packageInfo.reqFeatures?.firstOrNull {
            it.name == PackageManager.FEATURE_CAMERA_ANY
        }
        assertNotNull(cameraFeature)
        assertTrue(cameraFeature!!.flags and android.content.pm.FeatureInfo.FLAG_REQUIRED != 0)
    }
}
