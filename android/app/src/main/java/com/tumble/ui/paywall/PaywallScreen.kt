package com.tumble.ui.paywall

import android.app.Activity
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.NoAccounts
import androidx.compose.material.icons.outlined.PhoneIphone
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.film.FilmScene
import com.tumble.model.Entitlement
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType

/**
 * "Pay once. Never again." — the app's single Store & About screen: the three
 * one-time tiers (Plus · Unlimited · Free), Restore, and the on-device promise.
 * Ported from `app/Tumble/Screens/PaywallView.swift`.
 */
@Composable
fun PaywallScreen(
    onClose: () -> Unit,
    viewModel: PaywallViewModel = hiltViewModel(),
) {
    val activity = LocalContext.current as? Activity
    val owned by viewModel.ownedIds.collectAsState()
    val highest = Entitlement.highest(owned)

    // On-appear: fade in and slide up 14dp over 0.5s ease-out (mirrors iOS).
    var appeared by remember { mutableStateOf(false) }
    val appear by animateFloatAsState(
        targetValue = if (appeared) 1f else 0f,
        animationSpec = tween(durationMillis = 500, easing = EaseOut),
        label = "paywallAppear",
    )
    LaunchedEffect(Unit) { appeared = true }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    alpha = appear
                    translationY = (1f - appear) * 14.dp.toPx()
                }
                .safeContentPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp)
                .padding(top = 46.dp, bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Hero()
            Header()
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                TierCard(Entitlement.PLUS, highest, viewModel.price(Entitlement.PLUS)) {
                    activity?.let { viewModel.purchase(it, Entitlement.PLUS) }
                }
                TierCard(Entitlement.UNLIMITED, highest, viewModel.price(Entitlement.UNLIMITED)) {
                    activity?.let { viewModel.purchase(it, Entitlement.UNLIMITED) }
                }
                TierCard(Entitlement.FREE, highest, viewModel.price(Entitlement.FREE)) {}
            }
            Footer(onRestore = { viewModel.restore() })
        }

        Box(Modifier.fillMaxSize().safeContentPadding().padding(horizontal = 20.dp, vertical = 6.dp)) {
            CircleIconButton(Icons.Rounded.Close, "Close", onClose, modifier = Modifier.align(Alignment.TopEnd))
        }
    }
}

/** A little fan of prints, echoing the Drawer. */
@Composable
private fun Hero() {
    val blueHour = remember { FilmScene.BLUE_HOUR_ROOFTOP.render().asImageBitmap() }
    val sunlitPark = remember { FilmScene.SUNLIT_PARK.render().asImageBitmap() }
    val goldenHour = remember { FilmScene.GOLDEN_HOUR.render().asImageBitmap() }
    Box(Modifier.height(150.dp), contentAlignment = Alignment.Center) {
        PrintView(
            image = blueHour, isDeveloped = true, age = 0.15f, width = 116.dp,
            modifier = Modifier.offset(x = (-64).dp, y = 10.dp).graphicsLayer { rotationZ = -13f },
        )
        PrintView(
            image = sunlitPark, isDeveloped = true, age = 0.15f, width = 116.dp,
            modifier = Modifier.offset(x = 60.dp, y = 6.dp).graphicsLayer { rotationZ = 9f },
        )
        PrintView(
            image = goldenHour, isDeveloped = true, age = 0.15f, width = 116.dp,
            modifier = Modifier.offset(y = (-6).dp).graphicsLayer { rotationZ = -2f },
        )
    }
}

@Composable
private fun Header() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("PAY ONCE. NEVER AGAIN.", style = TumbleType.kicker)
        Text(
            "Free to start.\nYours to keep.",
            style = TumbleType.display(32).copy(color = Palette.cream, textAlign = TextAlign.Center),
        )
        Text(
            "Want more than twelve a day? Unlock it once - no subscriptions, no renewals, ever.",
            style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.72f), textAlign = TextAlign.Center),
            modifier = Modifier.padding(horizontal = 8.dp),
        )
    }
}

@Composable
private fun TierCard(
    tier: Entitlement,
    highest: Entitlement,
    price: String,
    onBuy: () -> Unit,
) {
    val featured = tier == Entitlement.PLUS
    val isOwned = tier != Entitlement.FREE && highest.ordinal >= tier.ordinal
    val isCurrentFree = tier == Entitlement.FREE && highest == Entitlement.FREE
    val shape = RoundedCornerShape(20.dp)
    val bg = if (featured) {
        Brush.verticalGradient(listOf(Palette.gold.copy(alpha = 0.16f), Palette.gold.copy(alpha = 0.05f)))
    } else {
        Brush.verticalGradient(listOf(Palette.cream.copy(alpha = 0.05f), Palette.cream.copy(alpha = 0.03f)))
    }
    val border = if (featured) Palette.gold.copy(alpha = 0.55f) else Palette.cream.copy(alpha = 0.14f)

    // No elevation shadow here: the card fills are translucent, so a Compose
    // shadow would bleed through the body as a hard inner rectangle. The gold
    // gradient + border carry the featured emphasis instead.
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bg)
            .border(if (featured) 1.5.dp else 1.dp, border, shape)
            .padding(if (featured) 22.dp else 18.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                tier.tierName().uppercase(),
                style = TumbleType.sans(12, FontWeight.SemiBold).copy(
                    color = if (featured) Palette.gold else Palette.cream.copy(alpha = 0.6f),
                    letterSpacing = 1.6.sp,
                ),
            )
            Spacer(Modifier.weight(1f))
            if (featured) {
                Text(
                    "MOST POPULAR",
                    style = TumbleType.sans(10, FontWeight.Bold).copy(color = Palette.ink, letterSpacing = 0.8.sp),
                    modifier = Modifier.clip(CircleShape).background(Palette.gold).padding(horizontal = 9.dp, vertical = 4.dp),
                )
            }
        }

        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(price, style = TumbleType.display(if (featured) 40 else 32).copy(color = Palette.cream))
            if (tier != Entitlement.FREE) {
                Text(
                    "one-time",
                    style = TumbleType.sans(13).copy(color = Palette.cream.copy(alpha = 0.5f)),
                    modifier = Modifier.padding(bottom = 6.dp),
                )
            }
        }

        Text(tier.shotsLabel(), style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.gold))
        Text(tier.blurb(), style = TumbleType.sans(13).copy(color = Palette.cream.copy(alpha = 0.72f)))

        Box(Modifier.padding(top = 6.dp)) {
            when {
                tier == Entitlement.FREE -> Text(
                    if (isCurrentFree) "Your current roll" else "Included",
                    style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.5f)),
                )
                isOwned -> Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(Icons.Filled.Verified, null, tint = Palette.gold, modifier = Modifier.size(16.dp))
                    Text("Owned", style = TumbleType.sans(14, FontWeight.SemiBold).copy(color = Palette.gold))
                }
                else -> Text(
                    "Own it",
                    style = TumbleType.sans(15, FontWeight.Bold).copy(color = Palette.ink, textAlign = TextAlign.Center),
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(
                            if (featured) {
                                Modifier.shadow(12.dp, CircleShape, spotColor = Palette.gold.copy(alpha = 0.5f))
                            } else Modifier,
                        )
                        .clip(CircleShape)
                        .background(Palette.gold)
                        .clickable(onClick = onBuy)
                        .padding(vertical = 12.dp),
                )
            }
        }
    }
}

@Composable
private fun Footer(onRestore: () -> Unit) {
    val context = LocalContext.current
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull() ?: "1.0"
    }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.padding(top = 6.dp),
    ) {
        Text(
            "Restore purchases",
            style = TumbleType.sans(14, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.85f)),
            modifier = Modifier
                .clip(CircleShape)
                .border(1.dp, Palette.cream.copy(alpha = 0.22f), CircleShape)
                .clickable(onClick = onRestore)
                .padding(horizontal = 18.dp, vertical = 9.dp),
        )

        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            PromiseItem(Icons.Outlined.PhoneIphone, "On-device", Modifier.weight(1f))
            PromiseItem(Icons.Outlined.NoAccounts, "No account", Modifier.weight(1f))
            PromiseItem(Icons.Outlined.CloudOff, "No cloud", Modifier.weight(1f))
        }

        Text(
            "One-time purchases · no subscriptions · restore anytime",
            style = TumbleType.sans(11).copy(color = Palette.cream.copy(alpha = 0.45f), textAlign = TextAlign.Center),
        )
        Text(
            "Version $version · Made for shooting, not scrolling.",
            style = TumbleType.sans(11).copy(color = Palette.cream.copy(alpha = 0.35f)),
        )
    }
}

@Composable
private fun PromiseItem(icon: ImageVector, label: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, null, tint = Palette.amber.copy(alpha = 0.9f), modifier = Modifier.size(18.dp))
        Text(label, style = TumbleType.sans(11, FontWeight.Medium).copy(color = Palette.cream.copy(alpha = 0.7f)))
    }
}

private fun Entitlement.tierName(): String = when (this) {
    Entitlement.FREE -> "Free"
    Entitlement.PLUS -> "Plus"
    Entitlement.UNLIMITED -> "Unlimited"
}

private fun Entitlement.shotsLabel(): String = when (this) {
    Entitlement.FREE -> "12 shots a day"
    Entitlement.PLUS -> "72 shots a day"
    Entitlement.UNLIMITED -> "Unlimited shots"
}

private fun Entitlement.blurb(): String = when (this) {
    Entitlement.FREE -> "The daily roll, shake-to-develop, and the whole Drawer."
    Entitlement.PLUS -> "Six rolls a day for heavier shooters, still fresh every morning."
    Entitlement.UNLIMITED -> "No daily limit at all. Shoot as much as you like."
}
