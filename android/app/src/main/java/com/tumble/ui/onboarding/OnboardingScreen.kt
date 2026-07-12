package com.tumble.ui.onboarding

import android.Manifest
import android.app.Activity
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.Camera
import androidx.compose.material.icons.filled.SaveAlt
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.WbTwilight
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.camera.CameraPreview
import com.tumble.camera.rememberCameraController
import com.tumble.film.FilmScene
import com.tumble.model.Entitlement
import com.tumble.ui.components.PrintView
import com.tumble.ui.onboarding.OnboardingViewModel.Step
import com.tumble.ui.paywall.PaywallViewModel
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.delay

/**
 * First-run onboarding built around *doing*, not watching — a straight port of
 * `app/Tumble/Screens/OnboardingScreen.swift`. The shooter takes a real (gifted)
 * first shot, shakes it to develop, watches it land in the Drawer, then meets a
 * soft, anti-subscription premium moment.
 */
@Composable
fun OnboardingScreen(
    onFinish: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel(),
) {
    val compact = LocalConfiguration.current.screenHeightDp < 720

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()
        Column(Modifier.fillMaxSize().systemBarsPadding()) {
            if (viewModel.step != Step.PREMIUM) {
                Box(Modifier.fillMaxWidth().padding(top = 12.dp), contentAlignment = Alignment.Center) {
                    StepDots(count = 4, index = viewModel.step.ordinal)
                }
            }
            Box(
                Modifier.fillMaxWidth().weight(1f).padding(horizontal = 28.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                when (viewModel.step) {
                    Step.WELCOME -> WelcomeStep(compact) { viewModel.goTo(Step.CAPTURE) }
                    Step.CAPTURE -> CaptureStep(viewModel, compact)
                    Step.DEVELOP -> DevelopStep(viewModel, compact)
                    Step.PAYOFF -> PayoffStep(viewModel, compact)
                    Step.PREMIUM -> PremiumStep(viewModel, compact) { viewModel.finish(onFinish) }
                }
            }
        }
    }
}

// MARK: - Shared bits

/** The four-step progress pills shown atop onboarding (the active one elongates). */
@Composable
private fun StepDots(count: Int, index: Int) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(count) { i ->
            val active = i == index
            Box(
                Modifier
                    .height(6.dp)
                    .width(if (active) 20.dp else 6.dp)
                    .clip(CircleShape)
                    .background(if (active) Palette.gold else Palette.cream.copy(alpha = 0.24f)),
            )
        }
    }
}

/** A shared title block for the do-it steps (mirrors iOS `stepText`). */
@Composable
private fun StepText(kicker: String, title: String, message: String, compact: Boolean) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 6.dp else 9.dp),
        modifier = Modifier.padding(horizontal = 8.dp),
    ) {
        Text(kicker.uppercase(), style = TumbleType.kicker)
        Text(
            title,
            style = TumbleType.display(if (compact) 27 else 32)
                .copy(color = Palette.cream, textAlign = TextAlign.Center),
        )
        Text(
            message,
            style = TumbleType.sans(if (compact) 13 else 15)
                .copy(color = Palette.cream.copy(alpha = 0.72f), textAlign = TextAlign.Center),
        )
    }
}

/** The full-width gold capsule CTA with a trailing glyph (mirrors iOS `PrimaryCTA`). */
@Composable
private fun PrimaryCTA(title: String, icon: ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .shadow(12.dp, CircleShape, spotColor = Palette.gold.copy(alpha = 0.4f))
            .clip(CircleShape)
            .background(Palette.gold)
            .clickable(onClick = onClick)
            .padding(vertical = 15.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = TumbleType.sans(16, FontWeight.Bold).copy(color = Palette.ink))
        Spacer(Modifier.width(8.dp))
        Icon(icon, contentDescription = null, tint = Palette.ink, modifier = Modifier.size(18.dp))
    }
}

// MARK: - Welcome / identity

@Composable
private fun WelcomeStep(compact: Boolean, onNext: () -> Unit) {
    val blueHour = remember { FilmScene.BLUE_HOUR_ROOFTOP.render().asImageBitmap() }
    val sunlitPark = remember { FilmScene.SUNLIT_PARK.render().asImageBitmap() }
    val goldenHour = remember { FilmScene.GOLDEN_HOUR.render().asImageBitmap() }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 16.dp else 22.dp),
    ) {
        Spacer(Modifier.weight(1f))

        // A staggered fan of three developed prints; the hero one is captioned.
        Box(Modifier.height(if (compact) 210.dp else 240.dp), contentAlignment = Alignment.Center) {
            PrintView(
                image = blueHour, isDeveloped = true, age = 0.28f, width = if (compact) 128.dp else 138.dp,
                modifier = Modifier.offset(x = (-58).dp, y = 12.dp).graphicsLayer { rotationZ = -12f },
            )
            PrintView(
                image = sunlitPark, isDeveloped = true, age = 0.1f, width = if (compact) 132.dp else 142.dp,
                modifier = Modifier.offset(x = 58.dp, y = 6.dp).graphicsLayer { rotationZ = 10f },
            )
            PrintView(
                image = goldenHour, isDeveloped = true, age = 0.05f, caption = "first light",
                width = if (compact) 150.dp else 162.dp,
                modifier = Modifier.offset(y = (-8).dp).graphicsLayer { rotationZ = -2f },
            )
        }

        // Aperture mark + wordmark.
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(9.dp),
        ) {
            Box(
                Modifier.size(32.dp).clip(CircleShape).background(Palette.gold),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Camera, contentDescription = null, tint = Palette.ink, modifier = Modifier.size(18.dp))
            }
            Text("Tumble", style = TumbleType.display(24).copy(color = Palette.cream))
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(if (compact) 8.dp else 11.dp),
        ) {
            Text(
                "A camera that\nmakes you wait.",
                style = TumbleType.display(if (compact) 30 else 34)
                    .copy(color = Palette.cream, textAlign = TextAlign.Center),
            )
            Text(
                "Twelve shots a day. Shake each one to develop. No feed, no filters, no rush.",
                style = TumbleType.sans(if (compact) 14 else 15)
                    .copy(color = Palette.cream.copy(alpha = 0.75f), textAlign = TextAlign.Center),
                modifier = Modifier.padding(horizontal = 20.dp),
            )
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(
                Icons.Outlined.Lock, contentDescription = null,
                tint = Palette.cream.copy(alpha = 0.6f), modifier = Modifier.size(13.dp),
            )
            Text(
                "No account · No cloud · Photos never leave your phone",
                style = TumbleType.sans(11, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.6f)),
            )
        }

        Spacer(Modifier.weight(1f))

        PrimaryCTA("Take your first shot", Icons.AutoMirrored.Filled.ArrowForward, onClick = onNext)
    }
}

// MARK: - Capture (do it)

@Composable
private fun CaptureStep(viewModel: OnboardingViewModel, compact: Boolean) {
    val controller = rememberCameraController()
    var hasPermission by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted -> hasPermission = granted }
    LaunchedEffect(Unit) { permissionLauncher.launch(Manifest.permission.CAMERA) }
    val placeholder = remember { FilmScene.random().render().asImageBitmap() }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 14.dp else 20.dp),
    ) {
        StepText(
            kicker = "Your turn",
            title = "Take your first shot.",
            message = "Point, and press. Don't overthink it - that's the whole idea.",
            compact = compact,
        )

        Spacer(Modifier.weight(1f))

        val shape = RoundedCornerShape(34.dp)
        Box(
            modifier = Modifier
                .width(if (compact) 250.dp else 288.dp)
                .height(if (compact) 300.dp else 344.dp)
                .shadow(22.dp, shape)
                .clip(shape)
                .border(1.2.dp, Palette.amber.copy(alpha = 0.3f), shape),
            contentAlignment = Alignment.Center,
        ) {
            if (hasPermission && !controller.isSimulated) {
                CameraPreview(controller, Modifier.fillMaxSize())
            } else {
                Image(placeholder, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            }
        }

        Spacer(Modifier.weight(1f))

        // Shutter: a cream ring around a cream disc.
        Box(
            Modifier
                .size(78.dp)
                .clip(CircleShape)
                .border(5.dp, Palette.cream.copy(alpha = 0.9f), CircleShape)
                .clickable { controller.capture { bitmap -> viewModel.captureGifted(bitmap) } },
            contentAlignment = Alignment.Center,
        ) {
            Box(Modifier.size(62.dp).clip(CircleShape).background(Palette.cream))
        }
    }
}

// MARK: - Develop (the hero moment)

@Composable
private fun DevelopStep(viewModel: OnboardingViewModel, compact: Boolean) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 14.dp else 20.dp),
    ) {
        StepText(
            kicker = "The best part",
            title = if (viewModel.isDeveloped) "There it is." else "Now shake it to life.",
            message = if (viewModel.isDeveloped) {
                "That wait? That's the whole point."
            } else {
                "Give your phone a shake and watch it come up, like real instant film."
            },
            compact = compact,
        )

        Spacer(Modifier.weight(1f))

        PrintView(
            image = viewModel.image,
            isDeveloped = viewModel.isDeveloped,
            developProgress = viewModel.progress,
            width = if (compact) 220.dp else 262.dp,
        )

        Spacer(Modifier.weight(1f))

        when {
            viewModel.isDeveloped ->
                PrimaryCTA("See it in the Drawer", Icons.AutoMirrored.Filled.ArrowForward) { viewModel.goTo(Step.PAYOFF) }
            viewModel.usesShake ->
                Text(
                    "Shake to develop",
                    style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.8f)),
                    modifier = Modifier.padding(bottom = 6.dp),
                )
            else -> HoldToDevelop(viewModel)
        }
    }
}

@Composable
private fun HoldToDevelop(viewModel: OnboardingViewModel) {
    var holding by remember { mutableStateOf(false) }
    LaunchedEffect(holding) {
        while (holding && !viewModel.isDeveloped) { viewModel.hold(); delay(16) }
    }
    Text(
        text = if (holding) "Developing…" else "Hold to develop",
        style = TumbleType.sans(15, FontWeight.Bold).copy(color = Palette.ink),
        modifier = Modifier
            .fillMaxWidth()
            .clip(CircleShape)
            .background(Palette.amber)
            .padding(vertical = 14.dp)
            .pointerInput(Unit) {
                detectTapGestures(onPress = {
                    holding = true
                    tryAwaitRelease()
                    holding = false
                })
            },
        textAlign = TextAlign.Center,
    )
}

// MARK: - Payoff / endowment

@Composable
private fun PayoffStep(viewModel: OnboardingViewModel, compact: Boolean) {
    var askedNotif by remember { mutableStateOf(false) }
    val notifLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted -> if (granted) viewModel.enableNotifications() }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 12.dp else 18.dp),
    ) {
        StepText(
            kicker = "Yours",
            title = "Here's your first one.",
            message = "Twelve fresh every morning. Twelve is on purpose - enough to make each one count.",
            compact = compact,
        )

        Spacer(Modifier.weight(1f))

        // Left: "SAVED TO DRAWER" note. Right: the print that just landed.
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = if (compact) 8.dp else 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f).padding(start = if (compact) 10.dp else 14.dp),
                verticalArrangement = Arrangement.spacedBy(if (compact) 7.dp else 9.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    Icon(Icons.Outlined.Inbox, null, tint = Palette.gold, modifier = Modifier.size(13.dp))
                    Text(
                        "SAVED TO DRAWER",
                        style = TumbleType.sans(11, FontWeight.Bold).copy(color = Palette.gold, letterSpacing = 1.1.sp),
                    )
                }
                Text("It's in.", style = TumbleType.display(if (compact) 20 else 24).copy(color = Palette.cream))
            }
            PrintView(
                image = viewModel.image, isDeveloped = true, width = if (compact) 146.dp else 172.dp,
                modifier = Modifier.graphicsLayer { rotationZ = -4f },
            )
        }

        Spacer(Modifier.weight(1f))

        // Value-first: offer the morning nudge now that they've felt the loop.
        if (!askedNotif) {
            NotifAsk(
                onYes = {
                    askedNotif = true
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    } else {
                        viewModel.enableNotifications()
                    }
                },
                onNotNow = { askedNotif = true; viewModel.skipNotifications() },
            )
        }

        PrimaryCTA("Into the Drawer", Icons.Outlined.Inbox) { viewModel.goTo(Step.PREMIUM) }
    }
}

@Composable
private fun NotifAsk(onYes: () -> Unit, onNotNow: () -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Color.Black.copy(alpha = 0.25f))
            .border(1.dp, Palette.cream.copy(alpha = 0.12f), shape)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Outlined.WbTwilight, null, tint = Palette.amber, modifier = Modifier.size(15.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(
                "A nudge each morning?",
                style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream),
            )
            Text(
                "We'll ping you when your fresh roll lands.",
                style = TumbleType.sans(11).copy(color = Palette.cream.copy(alpha = 0.6f)),
            )
        }
        Text(
            "Yes",
            style = TumbleType.sans(13, FontWeight.Bold).copy(color = Palette.ink),
            modifier = Modifier
                .clip(CircleShape)
                .background(Palette.gold)
                .clickable(onClick = onYes)
                .padding(horizontal = 16.dp, vertical = 8.dp),
        )
        Text(
            "Not now",
            style = TumbleType.sans(12, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.6f)),
            modifier = Modifier.clickable(onClick = onNotNow).padding(4.dp),
        )
    }
}

// MARK: - Premium (soft, anti-subscription)

@Composable
private fun PremiumStep(
    viewModel: OnboardingViewModel,
    compact: Boolean,
    paywall: PaywallViewModel = hiltViewModel(),
    onFinish: () -> Unit,
) {
    val activity = LocalContext.current as? Activity
    val owned by paywall.ownedIds.collectAsState()

    // Buying a tier finishes onboarding, mirroring iOS `onBuy -> onDone`.
    LaunchedEffect(owned) { if (Entitlement.highest(owned) > Entitlement.FREE) onFinish() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 8.dp else 12.dp),
    ) {
        Spacer(Modifier.height(if (compact) 4.dp else 10.dp))

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(if (compact) 5.dp else 7.dp),
        ) {
            Text("PAY ONCE. NEVER AGAIN.", style = TumbleType.kicker)
            Text(
                "Start with the full camera.",
                style = TumbleType.display(if (compact) 25 else 31)
                    .copy(color = Palette.cream, textAlign = TextAlign.Center),
            )
        }

        PremiumFinaleHero(compact = compact, image = viewModel.image)

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            MiniPromise(Icons.Outlined.Folder, "Collections", Modifier.weight(1f))
            MiniPromise(Icons.Filled.SaveAlt, "Save", Modifier.weight(1f))
            MiniPromise(Icons.Filled.AllInclusive, "More shots", Modifier.weight(1f))
        }

        PremiumChoiceCard(
            tier = Entitlement.PLUS, shotLine = "72 shots a day", featured = true,
            price = paywall.price(Entitlement.PLUS),
            onOwn = { activity?.let { paywall.purchase(it, Entitlement.PLUS) } },
        )
        PremiumChoiceCard(
            tier = Entitlement.UNLIMITED, shotLine = "No daily limit", featured = false,
            price = paywall.price(Entitlement.UNLIMITED),
            onOwn = { activity?.let { paywall.purchase(it, Entitlement.UNLIMITED) } },
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                modifier = Modifier
                    .weight(1f)
                    .clip(CircleShape)
                    .background(Palette.cream.copy(alpha = 0.075f))
                    .border(1.dp, Palette.gold.copy(alpha = 0.36f), CircleShape)
                    .clickable(onClick = onFinish)
                    .padding(vertical = if (compact) 11.dp else 13.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Start with 12 free shots", style = TumbleType.sans(14, FontWeight.Bold).copy(color = Palette.cream))
                Spacer(Modifier.width(7.dp))
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward, null,
                    tint = Palette.cream, modifier = Modifier.size(14.dp),
                )
            }
            Text(
                "Restore",
                style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.56f)),
                modifier = Modifier.clickable { paywall.restore() }.padding(vertical = 10.dp, horizontal = 8.dp),
            )
        }

        Text(
            "One-time purchase · no renewal · no account",
            style = TumbleType.sans(10, FontWeight.Medium).copy(color = Palette.cream.copy(alpha = 0.46f)),
        )

        Spacer(Modifier.height(if (compact) 2.dp else 6.dp))
    }
}

@Composable
private fun PremiumFinaleHero(compact: Boolean, image: ImageBitmap?) {
    val print = image ?: remember { FilmScene.GOLDEN_HOUR.render().asImageBitmap() }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = if (compact) 8.dp else 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier.weight(1f).padding(start = if (compact) 4.dp else 6.dp),
            verticalArrangement = Arrangement.spacedBy(if (compact) 7.dp else 9.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                Icon(Icons.Outlined.Inbox, null, tint = Palette.gold, modifier = Modifier.size(12.dp))
                Text(
                    "FIRST PRINT SAVED",
                    style = TumbleType.sans(10, FontWeight.Bold).copy(color = Palette.gold, letterSpacing = 0.9.sp),
                )
            }
            Text("Keep the Drawer.", style = TumbleType.display(if (compact) 20 else 24).copy(color = Palette.cream))
            Column(verticalArrangement = Arrangement.spacedBy(if (compact) 4.dp else 5.dp)) {
                PremiumStamp(Icons.Filled.Verified, "No subscription")
                PremiumStamp(Icons.Outlined.Lock, "No account")
            }
        }
        PrintView(
            image = print, isDeveloped = true, age = 0.04f, caption = if (compact) null else "first roll",
            width = if (compact) 98.dp else 122.dp,
            modifier = Modifier
                .shadow(18.dp, RoundedCornerShape(6.dp), spotColor = Palette.gold.copy(alpha = 0.4f))
                .graphicsLayer { rotationZ = -4f },
        )
    }
}

@Composable
private fun PremiumStamp(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(icon, null, tint = Palette.gold, modifier = Modifier.size(11.dp))
        Text(text, style = TumbleType.sans(10, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.7f)))
    }
}

@Composable
private fun MiniPromise(icon: ImageVector, text: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.18f))
            .padding(vertical = 7.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Palette.gold, modifier = Modifier.size(10.dp))
        Spacer(Modifier.width(5.dp))
        Text(text, style = TumbleType.sans(10, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.72f)))
    }
}

@Composable
private fun PremiumChoiceCard(
    tier: Entitlement,
    shotLine: String,
    featured: Boolean,
    price: String,
    onOwn: () -> Unit,
) {
    val shape = RoundedCornerShape(18.dp)
    val bg = if (featured) {
        Brush.linearGradient(listOf(Palette.gold.copy(alpha = 0.2f), Color(0xFF2D3741).copy(alpha = 0.9f)))
    } else {
        Brush.linearGradient(listOf(Palette.charcoalDeep.copy(alpha = 0.92f), Palette.blueDeep.copy(alpha = 0.74f)))
    }
    val borderColor = if (featured) Palette.gold.copy(alpha = 0.5f) else Palette.cream.copy(alpha = 0.12f)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bg)
            .border(1.dp, borderColor, shape)
            .padding(horizontal = 14.dp, vertical = if (featured) 13.dp else 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                Text(
                    tier.tierName().uppercase(),
                    style = TumbleType.sans(12, FontWeight.Bold).copy(
                        color = if (featured) Palette.gold else Palette.cream.copy(alpha = 0.62f),
                        letterSpacing = 1.2.sp,
                    ),
                )
                if (featured) {
                    Text(
                        "BEST START",
                        style = TumbleType.sans(9, FontWeight.Bold).copy(color = Palette.ink, letterSpacing = 0.7.sp),
                        modifier = Modifier.clip(CircleShape).background(Palette.gold).padding(horizontal = 7.dp, vertical = 3.dp),
                    )
                }
            }
            Text(shotLine, style = TumbleType.display(if (featured) 23 else 20).copy(color = Palette.cream))
            Text(
                "$price · pay once",
                style = TumbleType.sans(12, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.62f)),
            )
        }
        Text(
            "Own",
            style = TumbleType.sans(13, FontWeight.Bold).copy(color = Palette.ink),
            modifier = Modifier
                .clip(CircleShape)
                .background(Palette.gold)
                .clickable(onClick = onOwn)
                .padding(horizontal = 20.dp, vertical = 10.dp),
        )
    }
}

private fun Entitlement.tierName(): String = when (this) {
    Entitlement.FREE -> "Free"
    Entitlement.PLUS -> "Plus"
    Entitlement.UNLIMITED -> "Unlimited"
}
