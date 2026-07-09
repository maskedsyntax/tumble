package com.tumble.ui.paywall

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.model.Entitlement
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType

/**
 * The anti-subscription paywall — three tiers, one-time purchases, restore, and
 * the on-device promise. Ported from `app/Tumble/Screens/PaywallView.swift`.
 */
@Composable
fun PaywallScreen(
    onClose: () -> Unit,
    viewModel: PaywallViewModel = hiltViewModel(),
) {
    val activity = LocalContext.current as? Activity
    val owned by viewModel.ownedIds.collectAsState()

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .safeContentPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("PAY ONCE. NEVER AGAIN.", style = TumbleType.kicker)
            Spacer(Modifier.height(8.dp))
            Text(
                "Free to start.\nYours to keep.",
                style = TumbleType.display(32).copy(color = Palette.cream, textAlign = TextAlign.Center),
            )
            Spacer(Modifier.height(12.dp))
            Text(
                "Twelve shots a day, free forever. More is a one-time purchase — no renewal, no account.",
                style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.72f), textAlign = TextAlign.Center),
            )
            Spacer(Modifier.height(24.dp))

            TierCard(Entitlement.PLUS, "72 shots a day", featured = true, viewModel, owned, activity)
            Spacer(Modifier.height(12.dp))
            TierCard(Entitlement.UNLIMITED, "Unlimited shots", featured = false, viewModel, owned, activity)
            Spacer(Modifier.height(12.dp))
            TierCard(Entitlement.FREE, "12 shots a day", featured = false, viewModel, owned, activity)

            Spacer(Modifier.height(20.dp))
            Text(
                "Restore purchases",
                style = TumbleType.sans(14, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.8f)),
                modifier = Modifier.clickable { viewModel.restore() }.padding(8.dp),
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "On-device · No account · No cloud",
                style = TumbleType.sans(12).copy(color = Palette.cream.copy(alpha = 0.5f)),
            )
        }

        Box(Modifier.fillMaxSize().safeContentPadding().padding(20.dp)) {
            CircleIconButton(Icons.Filled.Close, "Close", onClose, modifier = Modifier.align(Alignment.TopEnd))
        }
    }
}

@Composable
private fun TierCard(
    tier: Entitlement,
    subtitle: String,
    featured: Boolean,
    viewModel: PaywallViewModel,
    owned: Set<String>,
    activity: Activity?,
) {
    val isOwned = viewModel.owned(tier, owned)
    val shape = RoundedCornerShape(18.dp)
    val bg = if (featured) {
        Brush.linearGradient(listOf(Palette.gold.copy(alpha = 0.16f), Palette.gold.copy(alpha = 0.05f)))
    } else {
        Brush.linearGradient(listOf(Palette.cream.copy(alpha = 0.05f), Palette.cream.copy(alpha = 0.03f)))
    }
    val borderColor = if (featured) Palette.gold.copy(alpha = 0.55f) else Palette.cream.copy(alpha = 0.14f)

    Column(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bg)
            .border(if (featured) 1.5.dp else 1.dp, borderColor, shape)
            .padding(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(tier.tierName(), style = TumbleType.display(20).copy(color = Palette.cream))
                    if (featured) {
                        Spacer(Modifier.width(8.dp))
                        Text(
                            "Most popular",
                            style = TumbleType.sans(10, FontWeight.Bold).copy(color = Palette.ink),
                            modifier = Modifier.clip(CircleShape).background(Palette.gold).padding(horizontal = 8.dp, vertical = 3.dp),
                        )
                    }
                }
                Text(subtitle, style = TumbleType.sans(13).copy(color = Palette.cream.copy(alpha = 0.65f)))
            }
            Text(viewModel.price(tier), style = TumbleType.display(20).copy(color = Palette.cream))
        }

        Spacer(Modifier.height(14.dp))
        val label = when {
            tier == Entitlement.FREE -> "Included"
            isOwned -> "Owned"
            else -> "Own it"
        }
        val actionable = tier != Entitlement.FREE && !isOwned
        Text(
            label,
            style = TumbleType.sans(15, FontWeight.Bold).copy(
                color = if (actionable) Palette.ink else Palette.cream.copy(alpha = 0.5f),
                textAlign = TextAlign.Center,
            ),
            modifier = Modifier
                .fillMaxWidth()
                .clip(CircleShape)
                .background(if (actionable) Palette.amber else Palette.cream.copy(alpha = 0.08f))
                .then(
                    if (actionable && activity != null) {
                        Modifier.clickable { viewModel.purchase(activity, tier) }
                    } else Modifier,
                )
                .padding(vertical = 12.dp),
        )
    }
}

private fun Entitlement.tierName(): String = when (this) {
    Entitlement.FREE -> "Free"
    Entitlement.PLUS -> "Plus"
    Entitlement.UNLIMITED -> "Unlimited"
}
