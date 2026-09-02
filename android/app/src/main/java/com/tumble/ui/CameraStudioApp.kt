package com.tumble.ui

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.LocalActivity
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.tumble.BuildConfig
import com.tumble.analytics.AnalyticsController
import com.tumble.camera.CameraCaptureResult
import com.tumble.camera.CameraPreview
import com.tumble.camera.CameraSide
import com.tumble.camera.rememberCameraController
import com.tumble.store.CompleteBillingManager
import com.tumble.studio.AccessState
import com.tumble.studio.DraftRepository
import com.tumble.studio.EditDraft
import com.tumble.studio.EditRecipe
import com.tumble.studio.FilmCatalog
import com.tumble.studio.SourceKind
import com.tumble.studio.StudioRenderer
import com.tumble.ui.studio.StudioScreen
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

private enum class Surface { ONBOARDING, CAMERA, STUDIO }

@Composable
fun CameraStudioApp() {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("tumble-v3", Context.MODE_PRIVATE) }
    val catalog = remember { FilmCatalog.load(context) }
    val drafts = remember { DraftRepository(context.applicationContext) }
    val analytics = remember { AnalyticsController(context.applicationContext) }
    val billing = remember { CompleteBillingManager(context.applicationContext, catalog.completeProductId) }
    var surface by remember { mutableStateOf(if (prefs.getBoolean("introduced", false)) Surface.CAMERA else Surface.ONBOARDING) }
    var activeDraft by remember { mutableStateOf<EditDraft?>(null) }
    var resumePrompt by remember { mutableStateOf(surface == Surface.CAMERA && drafts.active != null) }
    var completeSheet by remember { mutableStateOf(false) }
    var settingsSheet by remember { mutableStateOf(false) }
    var analyticsOffer by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { billing.connect() }

    when (surface) {
        Surface.ONBOARDING -> TumbleOnboarding {
            prefs.edit().putBoolean("introduced", true).apply()
            surface = Surface.CAMERA
        }
        Surface.CAMERA -> CameraScreen(catalog, drafts, billing.accessState, analytics, onOpenStudio = {
            activeDraft = it; surface = Surface.STUDIO
        }, onLockedFilm = { completeSheet = true }, onSettings = { settingsSheet = true })
        Surface.STUDIO -> activeDraft?.let { draft ->
            StudioScreen(draft, catalog, drafts, billing.accessState, { completeSheet = true }, {
                activeDraft = null; surface = Surface.CAMERA
            }, {
                analytics.capture("photo_saved", mapOf("format" to "jpeg"))
                if (!prefs.getBoolean("analytics-prompt-shown", false)) analyticsOffer = true
            })
        } ?: run { surface = Surface.CAMERA }
    }

    if (resumePrompt) AlertDialog(onDismissRequest = {}, title = { Text("Continue your last edit?") }, text = { Text("Tumble kept one private draft because it was not saved yet.") }, confirmButton = {
        TextButton(onClick = { activeDraft = drafts.active; resumePrompt = false; surface = Surface.STUDIO }) { Text("Continue editing") }
    }, dismissButton = { TextButton(onClick = { drafts.discard(); resumePrompt = false }) { Text("Discard") } })

    if (completeSheet) CompleteDialog(billing) { completeSheet = false }
    if (settingsSheet) SettingsDialog(analytics, billing.accessState, { completeSheet = true }) { settingsSheet = false }
    if (analyticsOffer) AlertDialog(onDismissRequest = {}, title = { Text("Help improve Tumble?") }, text = { Text("Share anonymous product events, crash diagnostics, and masked session replay. Photo pixels, filenames, edits, and notes are never sent.") }, confirmButton = {
        TextButton(onClick = { prefs.edit().putBoolean("analytics-prompt-shown", true).apply(); analytics.setEnabled(true); analyticsOffer = false }) { Text("Allow") }
    }, dismissButton = { TextButton(onClick = { prefs.edit().putBoolean("analytics-prompt-shown", true).apply(); analyticsOffer = false }) { Text("Not now") } })
}

@Composable
private fun TumbleOnboarding(onDone: () -> Unit) {
    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()
        Column(Modifier.fillMaxSize().padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text("◉", style = TumbleType.display(72), color = Palette.gold)
            Text("Tumble", style = TumbleType.display(40), color = Palette.cream)
            Text("Your private film camera.", style = TumbleType.display(26), color = Palette.cream, textAlign = TextAlign.Center)
            Text("Shoot something new or bring a photo with you. Choose a film, make it yours, and save it—without sending your pictures anywhere.", style = TumbleType.sans(15), color = Palette.cream.copy(alpha = .72f), textAlign = TextAlign.Center, modifier = Modifier.padding(vertical = 22.dp))
            Text("No account · Local photo processing", style = TumbleType.sans(12, FontWeight.SemiBold), color = Palette.cream.copy(alpha = .58f))
            Button(onClick = onDone, Modifier.fillMaxWidth().padding(top = 40.dp), colors = ButtonDefaults.buttonColors(containerColor = Palette.gold, contentColor = Palette.ink)) { Text("Open the camera", fontWeight = FontWeight.Bold) }
        }
    }
}

@Composable
private fun CameraScreen(
    catalog: FilmCatalog,
    drafts: DraftRepository,
    access: AccessState,
    analytics: AnalyticsController,
    onOpenStudio: (EditDraft) -> Unit,
    onLockedFilm: () -> Unit,
    onSettings: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val prefs = remember { context.getSharedPreferences("tumble-v3", Context.MODE_PRIVATE) }
    var selectedId by remember { mutableStateOf(prefs.getString("film", FilmCatalog.DEFAULT_STOCK_ID) ?: FilmCatalog.DEFAULT_STOCK_ID) }
    var permission by remember { mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) }
    var denied by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    val camera = rememberCameraController()
    val renderer = remember { StudioRenderer() }
    val selected = catalog.stock(selectedId)
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        permission = it; denied = !it; analytics.capture("permission_responded", mapOf("permission" to "camera", "outcome" to if (it) "granted" else "denied"))
    }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) scope.launch {
            val bytes = withContext(Dispatchers.IO) { context.contentResolver.openInputStream(uri)?.use { it.readBytes() } }
            if (bytes == null) message = "That image could not be imported."
            else runCatching { drafts.create(bytes, SourceKind.LIBRARY, selectedId) }.onSuccess(onOpenStudio).onFailure { message = "Tumble could not create a private draft." }
        }
    }

    LaunchedEffect(selectedId) {
        prefs.edit().putString("film", selectedId).apply()
        camera.setPreviewRenderer { bitmap -> renderer.render(bitmap, selected, EditRecipe(stockId = selected.id), 0, 720) }
    }
    DisposableEffect(Unit) { onDispose { camera.setPreviewRenderer(null) } }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()
        Column(Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(11.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column { Text("Tumble", style = TumbleType.display(28), color = Palette.cream); Text(selected.name, style = TumbleType.sans(12, FontWeight.SemiBold), color = Palette.gold) }
                Spacer(Modifier.weight(1f)); IconButton(onClick = onSettings) { Icon(Icons.Default.Settings, "Settings", tint = Palette.cream) }
            }
            Box(Modifier.weight(1f).fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(androidx.compose.ui.graphics.Color.Black), contentAlignment = Alignment.Center) {
                if (permission) {
                    CameraPreview(camera, Modifier.fillMaxSize())
                    camera.filteredPreview?.let { Image(it.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                    Row(Modifier.align(Alignment.TopStart).padding(10.dp)) {
                        IconButton(onClick = camera::toggleFlash, enabled = camera.supportsFlash) { Icon(if (camera.flashOn) Icons.Default.Bolt else Icons.Default.FlashOff, "Flash", tint = Palette.cream) }
                    }
                } else Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(if (denied) "Camera access is off" else "Tap to use the camera", style = TumbleType.display(22), color = Palette.cream)
                    Text("Import always works without camera access.", style = TumbleType.sans(12), color = Palette.cream.copy(alpha = .62f))
                    Button(onClick = {
                        if (denied) context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")))
                        else permissionLauncher.launch(Manifest.permission.CAMERA)
                    }, Modifier.padding(top = 12.dp)) { Text(if (denied) "Open Settings" else "Enable camera") }
                }
            }
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                catalog.stocks.forEach { stock ->
                    val unlocked = access.unlocks(stock)
                    FilterChip(selectedId == stock.id, { if (unlocked) selectedId = stock.id else onLockedFilm() }, label = { Text(if (unlocked) stock.name else "🔒 ${stock.name}") })
                }
            }
            Row(Modifier.fillMaxWidth().height(82.dp), verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }) { Icon(Icons.Default.PhotoLibrary, "Import", tint = Palette.cream, modifier = Modifier.size(26.dp)) }
                Spacer(Modifier.weight(1f))
                Button(enabled = permission && camera.isReady && !camera.isCapturing, onClick = {
                    camera.capture { result ->
                        when (result) {
                            is CameraCaptureResult.Success -> runCatching {
                                val bytes = ByteArrayOutputStream().use { result.bitmap.compress(Bitmap.CompressFormat.JPEG, 98, it); it.toByteArray() }
                                drafts.create(bytes, SourceKind.CAMERA, selectedId)
                            }.onSuccess(onOpenStudio).onFailure { message = "Tumble could not create a private draft." }
                            is CameraCaptureResult.Failure -> message = result.reason
                            is CameraCaptureResult.Unavailable -> message = result.reason
                        }
                    }
                }, modifier = Modifier.size(76.dp), shape = CircleShape, colors = ButtonDefaults.buttonColors(containerColor = Palette.cream, contentColor = Palette.ink), contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp)) { Box(Modifier.size(60.dp).background(Palette.cream, CircleShape)) }
                Spacer(Modifier.weight(1f))
                IconButton(enabled = permission && camera.canSwitch, onClick = camera::switchCamera) { Icon(Icons.Default.Cameraswitch, "Switch camera", tint = Palette.cream, modifier = Modifier.size(28.dp)) }
            }
        }
    }
    message?.let { AlertDialog(onDismissRequest = { message = null }, confirmButton = { TextButton(onClick = { message = null }) { Text("OK") } }, text = { Text(it) }) }
}

@Composable private fun CompleteDialog(billing: CompleteBillingManager, close: () -> Unit) {
    val activity = LocalActivity.current
    AlertDialog(onDismissRequest = close, title = { Text("Tumble Complete", style = TumbleType.display(28)) }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("All fifteen premium films. One payment, yours forever.")
            Text("Ninety-Six · Darkroom · Long Summer", color = Palette.gold)
            if (billing.accessState == AccessState.Complete) Text("Complete is unlocked on this Play account.", fontWeight = FontWeight.Bold)
        }
    }, confirmButton = {
        TextButton(enabled = activity != null && billing.product != null && billing.accessState != AccessState.Complete, onClick = { activity?.let(billing::launch) }) {
            val price = billing.product?.oneTimePurchaseOfferDetailsList?.firstOrNull()?.formattedPrice ?: "…"
            Text(if (billing.accessState == AccessState.Complete) "Unlocked" else "Own every film · $price")
        }
    }, dismissButton = { TextButton(onClick = { billing.refresh(); close() }) { Text("Restore / Close") } })
}

@Composable private fun SettingsDialog(analytics: AnalyticsController, access: AccessState, openComplete: () -> Unit, close: () -> Unit) {
    var enabled by remember { mutableStateOf(analytics.enabled) }
    AlertDialog(onDismissRequest = close, title = { Text("Settings", style = TumbleType.display(28)) }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { Column(Modifier.weight(1f)) { Text("Help improve Tumble"); Text("Anonymous events, crashes and masked replay", style = TumbleType.sans(11)) }; Switch(enabled, { enabled = it; analytics.setEnabled(it) }) }
            TextButton(onClick = openComplete) { Text(if (access == AccessState.Complete) "Tumble Complete · Unlocked" else "Unlock Tumble Complete") }
            Text("Privacy: local photo processing; optional analytics uses the network. Purchases use Google Play. Saved photos may sync through your device settings.", style = TumbleType.sans(11))
            Text("Tumble ${BuildConfig.VERSION_NAME}", style = TumbleType.sans(11), color = Palette.cream.copy(alpha = .55f))
        }
    }, confirmButton = { TextButton(onClick = close) { Text("Done") } })
}
