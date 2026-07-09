package com.tumble.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.camera.CameraPreview
import com.tumble.camera.rememberCameraController
import com.tumble.film.FilmScene
import com.tumble.ui.components.PrintView
import com.tumble.ui.onboarding.OnboardingViewModel.Step
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.delay

@Composable
fun OnboardingScreen(
    onFinish: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel(),
) {
    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()
        Box(Modifier.fillMaxSize().padding(28.dp), contentAlignment = Alignment.Center) {
            when (viewModel.step) {
                Step.WELCOME -> WelcomeStep { viewModel.goTo(Step.CAPTURE) }
                Step.CAPTURE -> CaptureStep(viewModel)
                Step.DEVELOP -> DevelopStep(viewModel)
                Step.PAYOFF -> PayoffStep(viewModel)
                Step.PREMIUM -> PremiumStep { viewModel.finish(onFinish) }
            }
        }
    }
}

@Composable
private fun AmberButton(label: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Text(
        text = label,
        style = TumbleType.sans(16, FontWeight.Bold).copy(color = Palette.ink),
        modifier = modifier
            .clip(CircleShape)
            .background(Palette.amber)
            .clickable(onClick = onClick)
            .padding(horizontal = 28.dp, vertical = 14.dp),
    )
}

@Composable
private fun OutlineButton(label: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Text(
        text = label,
        style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.cream),
        modifier = modifier
            .clip(CircleShape)
            .border(1.dp, Palette.cream.copy(alpha = 0.3f), CircleShape)
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 12.dp),
    )
}

@Composable
private fun WelcomeStep(onNext: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        // A staggered fan of three prints.
        Box(Modifier.height(150.dp), contentAlignment = Alignment.Center) {
            listOf(-12f to (-40).dp, 10f to 40.dp, -2f to 0.dp).forEach { (angle, offset) ->
                PrintView(
                    image = null,
                    isDeveloped = true,
                    width = 120.dp,
                    modifier = Modifier
                        .graphicsLayer { rotationZ = angle }
                        .padding(start = if (offset > 0.dp) offset else 0.dp, end = if (offset < 0.dp) -offset else 0.dp),
                )
            }
        }
        Spacer(Modifier.height(28.dp))
        Text(
            "A camera that makes you wait.",
            style = TumbleType.display(32).copy(color = Palette.cream, textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Twelve shots a day. Shake each one to develop, like a Polaroid.",
            style = TumbleType.sans(15).copy(color = Palette.cream.copy(alpha = 0.75f), textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "No account · No cloud · Photos never leave your phone",
            style = TumbleType.sans(12).copy(color = Palette.gold, textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(28.dp))
        AmberButton("Take your first shot", onClick = onNext)
    }
}

@Composable
private fun CaptureStep(viewModel: OnboardingViewModel) {
    val controller = rememberCameraController()
    var hasPermission by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted -> hasPermission = granted }
    LaunchedEffect(Unit) { permissionLauncher.launch(Manifest.permission.CAMERA) }
    val placeholder = remember { FilmScene.random().render().asImageBitmap() }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text("First shot's on us.", style = TumbleType.display(26).copy(color = Palette.cream))
        Spacer(Modifier.height(6.dp))
        Text(
            "It won't cost you one of today's twelve.",
            style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.7f)),
        )
        Spacer(Modifier.height(20.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(0.9f)
                .clip(RoundedCornerShape(30.dp))
                .border(1.dp, Palette.amber.copy(alpha = 0.3f), RoundedCornerShape(30.dp)),
            contentAlignment = Alignment.Center,
        ) {
            if (hasPermission && !controller.isSimulated) {
                CameraPreview(controller, Modifier.fillMaxSize())
            } else {
                Image(placeholder, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            }
        }
        Spacer(Modifier.height(24.dp))
        Box(
            Modifier
                .size(74.dp)
                .clip(CircleShape)
                .background(Palette.cream)
                .clickable { controller.capture { bitmap -> viewModel.captureGifted(bitmap) } },
        )
    }
}

@Composable
private fun DevelopStep(viewModel: OnboardingViewModel) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        PrintView(
            image = viewModel.image,
            isDeveloped = viewModel.isDeveloped,
            developProgress = viewModel.progress,
            width = 260.dp,
        )
        Spacer(Modifier.height(24.dp))
        if (viewModel.isDeveloped) {
            Text("There it is.", style = TumbleType.display(22).copy(color = Palette.cream))
            Spacer(Modifier.height(20.dp))
            AmberButton("See it in your Drawer") { viewModel.goTo(Step.PAYOFF) }
        } else {
            Text(
                if (viewModel.usesShake) "Shake to develop" else "Hold to develop",
                style = TumbleType.display(22).copy(color = Palette.cream),
            )
            if (!viewModel.usesShake) {
                Spacer(Modifier.height(12.dp))
                HoldToDevelop(viewModel)
            }
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
        style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.ink),
        modifier = Modifier
            .clip(CircleShape)
            .background(Palette.amber)
            .padding(horizontal = 22.dp, vertical = 10.dp)
            .pointerInput(Unit) {
                detectTapGestures(onPress = {
                    holding = true
                    tryAwaitRelease()
                    holding = false
                })
            },
    )
}

@Composable
private fun PayoffStep(viewModel: OnboardingViewModel) {
    val notifLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { _ -> viewModel.enableNotifications(); viewModel.goTo(Step.PREMIUM) }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        PrintView(
            image = viewModel.image,
            isDeveloped = true,
            width = 200.dp,
            modifier = Modifier.graphicsLayer { rotationZ = -4f },
        )
        Spacer(Modifier.height(24.dp))
        Text("It's in.", style = TumbleType.display(28).copy(color = Palette.cream))
        Spacer(Modifier.height(8.dp))
        Text(
            "A nudge each morning when your fresh roll lands?",
            style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.75f), textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(24.dp))
        AmberButton("Yes, remind me") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            } else {
                viewModel.enableNotifications(); viewModel.goTo(Step.PREMIUM)
            }
        }
        Spacer(Modifier.height(10.dp))
        OutlineButton("Not now") { viewModel.skipNotifications(); viewModel.goTo(Step.PREMIUM) }
    }
}

@Composable
private fun PremiumStep(onStart: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text("PAY ONCE. NEVER AGAIN.", style = TumbleType.kicker)
        Spacer(Modifier.height(8.dp))
        Text(
            "Free to start.\nYours to keep.",
            style = TumbleType.display(30).copy(color = Palette.cream, textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(14.dp))
        Text(
            "12 shots a day, free forever. Want more? Plus is 72/day, Unlimited is endless — a one-time purchase, no renewal.",
            style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.72f), textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(28.dp))
        AmberButton("Start with 12 free shots", onClick = onStart)
    }
}
