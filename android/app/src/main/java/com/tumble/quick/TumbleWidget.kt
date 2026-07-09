package com.tumble.quick

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.tumble.ui.theme.Palette

/**
 * Home-screen widget showing shots remaining today; tapping opens the camera.
 * The Android stand-in for the iOS lock-screen / Control Center camera.
 */
class TumbleWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val label = CameraLaunch.remainingLabel(context)
        provideContent { Content(label, context) }
    }

    @Composable
    private fun Content(label: String, context: Context) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Palette.blue))
                .clickable(actionStartActivity(CameraLaunch.intent(context)))
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("Tumble", style = TextStyle(color = ColorProvider(Palette.gold), fontWeight = FontWeight.Bold))
            Text(label, style = TextStyle(color = ColorProvider(Palette.cream)))
            Text("Tap for a shot", style = TextStyle(color = ColorProvider(Palette.creamDim)))
        }
    }
}

class TumbleWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TumbleWidget()
}
