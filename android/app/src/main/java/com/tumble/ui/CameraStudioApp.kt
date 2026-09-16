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
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.tumble.BuildConfig
import com.tumble.account.AccountCoordinator
import com.tumble.account.AuthProvider
import com.tumble.account.AuthState
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
import com.tumble.studio.mergeAccess
import com.tumble.ui.studio.StudioScreen
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filterNotNull
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
    val account = remember { AccountCoordinator(context.applicationContext) }
    val effectiveAccess = mergeAccess(billing.accessState, account.accountAccess)
    var surface by remember { mutableStateOf(if (prefs.getBoolean("introduced", false)) Surface.CAMERA else Surface.ONBOARDING) }
    var activeDraft by remember { mutableStateOf<EditDraft?>(null) }
    var resumePrompt by remember { mutableStateOf(surface == Surface.CAMERA && drafts.active != null) }
    var completeSheet by remember { mutableStateOf(false) }
    var settingsSheet by remember { mutableStateOf(false) }
    var accountSheet by remember { mutableStateOf(false) }
    var analyticsOffer by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        billing.onPurchaseObserved = { account.syncPurchases() }
        billing.connect()
    }

    when (surface) {
        Surface.ONBOARDING -> TumbleOnboarding {
            prefs.edit().putBoolean("introduced", true).apply()
            surface = Surface.CAMERA
        }
        Surface.CAMERA -> CameraScreen(catalog, drafts, effectiveAccess, analytics, onOpenStudio = {
            activeDraft = it; surface = Surface.STUDIO
        }, onLockedFilm = { completeSheet = true }, onSettings = { settingsSheet = true })
        Surface.STUDIO -> activeDraft?.let { draft ->
            StudioScreen(draft, catalog, drafts, effectiveAccess, { completeSheet = true }, {
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

    if (completeSheet) CompleteDialog(billing, account, effectiveAccess, { accountSheet = true }) { completeSheet = false }
    if (settingsSheet) SettingsDialog(analytics, effectiveAccess, account, { completeSheet = true }, { accountSheet = true }) { settingsSheet = false }
    if (accountSheet) AccountDialog(account, onLinked = { billing.refresh(); account.syncPurchases() }) { accountSheet = false }
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
            Text("Account optional · Photos stay local", style = TumbleType.sans(12, FontWeight.SemiBold), color = Palette.cream.copy(alpha = .58f))
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
    var importInProgress by remember { mutableStateOf(false) }
    val camera = rememberCameraController()
    val renderer = remember { StudioRenderer() }
    val selected = catalog.stock(selectedId)
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        permission = it; denied = !it; analytics.capture("permission_responded", mapOf("permission" to "camera", "outcome" to if (it) "granted" else "denied"))
    }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) scope.launch {
            importInProgress = true
            try {
                val bytes = withContext(Dispatchers.IO) { context.contentResolver.openInputStream(uri)?.use { it.readBytes() } }
                if (bytes == null) message = "That image could not be imported."
                else runCatching { drafts.create(bytes, SourceKind.LIBRARY, selectedId) }.onSuccess(onOpenStudio).onFailure { message = "Tumble could not create a private draft." }
            } finally {
                importInProgress = false
            }
        }
    }

    val selectedIndex = catalog.stocks.indexOfFirst { it.id == selectedId }.coerceAtLeast(0)
    val filmRailState = rememberLazyListState(initialFirstVisibleItemIndex = selectedIndex)
    val centeredFilmIndex by remember {
        derivedStateOf {
            val layout = filmRailState.layoutInfo
            val center = (layout.viewportStartOffset + layout.viewportEndOffset) / 2
            layout.visibleItemsInfo.minByOrNull { item ->
                kotlin.math.abs(item.offset + item.size / 2 - center)
            }?.index ?: selectedIndex
        }
    }
    val filmRailFling = rememberSnapFlingBehavior(lazyListState = filmRailState)

    LaunchedEffect(filmRailState, access) {
        snapshotFlow {
            if (filmRailState.isScrollInProgress) null else centeredFilmIndex
        }
            .filterNotNull()
            .distinctUntilChanged()
            .collect { index ->
                val stock = catalog.stocks.getOrNull(index) ?: return@collect
                if (access.unlocks(stock)) {
                    selectedId = stock.id
                } else {
                    onLockedFilm()
                    val current = catalog.stocks.indexOfFirst { it.id == selectedId }.coerceAtLeast(0)
                    filmRailState.animateScrollToItem(current)
                }
            }
    }

    LaunchedEffect(selectedId) {
        prefs.edit().putString("film", selectedId).apply()
        camera.setPreviewRenderer { bitmap -> renderer.render(bitmap, selected, EditRecipe(stockId = selected.id), 0, 480) }
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
            BoxWithConstraints(Modifier.fillMaxWidth().height(60.dp)) {
                val itemWidth = 136.dp
                val edgePadding = ((maxWidth - itemWidth) / 2).coerceAtLeast(0.dp)
                LazyRow(
                    state = filmRailState,
                    flingBehavior = filmRailFling,
                    contentPadding = PaddingValues(horizontal = edgePadding),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    items(catalog.stocks.size, key = { catalog.stocks[it].id }) { index ->
                        val stock = catalog.stocks[index]
                        val unlocked = access.unlocks(stock)
                        val isCentered = centeredFilmIndex == index
                        val packName = catalog.packs.firstOrNull { it.id == stock.packId }?.name?.uppercase() ?: "FILM"
                    Column(
                            Modifier
                                .width(itemWidth)
                                .height(56.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (isCentered) Palette.blueDeep.copy(alpha = .52f) else androidx.compose.ui.graphics.Color.Transparent)
                                .border(
                                    1.dp,
                                    if (isCentered) Palette.gold.copy(alpha = .34f) else androidx.compose.ui.graphics.Color.Transparent,
                                    RoundedCornerShape(10.dp),
                                )
                                .clickable {
                                    if (isCentered && !unlocked) onLockedFilm()
                                    else scope.launch { filmRailState.animateScrollToItem(index) }
                                },
                        horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                            Text(
                                stock.name,
                                    style = TumbleType.sans(12, if (isCentered) FontWeight.Bold else FontWeight.SemiBold),
                                    color = if (isCentered) Palette.gold else Palette.cream.copy(alpha = .62f),
                                maxLines = 1,
                            )
                            if (!unlocked) {
                                Icon(
                                    Icons.Default.Lock,
                                    contentDescription = "Locked",
                                        tint = if (isCentered) Palette.gold else Palette.cream.copy(alpha = .62f),
                                    modifier = Modifier.size(9.dp),
                                )
                            }
                        }
                            Text(
                                packName,
                                style = TumbleType.sans(7, FontWeight.Bold),
                                color = Palette.cream.copy(alpha = if (isCentered) .52f else .30f),
                            )
                        Box(
                                Modifier
                                    .padding(top = 4.dp)
                                    .size(width = if (isCentered) 34.dp else 14.dp, height = 2.dp)
                                    .background(if (isCentered) Palette.gold else Palette.cream.copy(alpha = .16f), CircleShape)
                        )
                    }
                }
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
        if (importInProgress) {
            Box(
                Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = .56f)),
                contentAlignment = Alignment.Center,
            ) {
                Column(
                    Modifier
                        .background(Palette.blueDeep.copy(alpha = .96f), RoundedCornerShape(24.dp))
                        .border(1.dp, Palette.cream.copy(alpha = .10f), RoundedCornerShape(24.dp))
                        .padding(horizontal = 28.dp, vertical = 24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    CircularProgressIndicator(color = Palette.gold)
                    Text("Preparing your photo", style = TumbleType.display(22), color = Palette.cream)
                    Text("Copying it privately into Studio…", style = TumbleType.sans(12), color = Palette.cream.copy(alpha = .62f))
                }
            }
        }
    }
    message?.let { AlertDialog(onDismissRequest = { message = null }, confirmButton = { TextButton(onClick = { message = null }) { Text("OK") } }, text = { Text(it) }) }
}

@Composable private fun CompleteDialog(
    billing: CompleteBillingManager,
    account: AccountCoordinator,
    access: AccessState,
    requireAccount: () -> Unit,
    close: () -> Unit,
) {
    val activity = LocalActivity.current
    AlertDialog(onDismissRequest = close, title = { Text("Tumble Complete", style = TumbleType.display(28)) }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("All fifteen premium films. One payment, yours forever.")
            Text("Ninety-Six · Darkroom · Long Summer", color = Palette.gold)
            if (access == AccessState.Complete) Text("Complete is unlocked for this device or Tumble account.", fontWeight = FontWeight.Bold)
        }
    }, confirmButton = {
        TextButton(enabled = activity != null && billing.product != null && access != AccessState.Complete, onClick = {
            if (account.state is AuthState.SignedIn) activity?.let(billing::launch) else requireAccount()
        }) {
            val price = billing.product?.oneTimePurchaseOfferDetailsList?.firstOrNull()?.formattedPrice ?: "…"
            Text(if (access == AccessState.Complete) "Unlocked" else "Own every film · $price")
        }
    }, dismissButton = { TextButton(onClick = {
        if (account.state is AuthState.SignedIn) { billing.refresh(); account.syncPurchases() } else requireAccount()
        close()
    }) { Text(if (account.state is AuthState.SignedIn) "Restore / Close" else "Sign in to restore") } })
}

@Composable private fun SettingsDialog(
    analytics: AnalyticsController,
    access: AccessState,
    account: AccountCoordinator,
    openComplete: () -> Unit,
    openAccount: () -> Unit,
    close: () -> Unit,
) {
    var enabled by remember { mutableStateOf(analytics.enabled) }
    AlertDialog(onDismissRequest = close, title = { Text("Settings", style = TumbleType.display(28)) }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { Column(Modifier.weight(1f)) { Text("Help improve Tumble"); Text("Anonymous events, crashes and masked replay", style = TumbleType.sans(11)) }; Switch(enabled, { enabled = it; analytics.setEnabled(it) }) }
            TextButton(onClick = openComplete) { Text(if (access == AccessState.Complete) "Tumble Complete · Unlocked" else "Unlock Tumble Complete") }
            TextButton(onClick = openAccount) { Text(if (account.state is AuthState.SignedIn) "Account & linked purchases" else "Sign in or link purchases") }
            Text("Privacy: photos and drafts stay on device. Firebase processes account identifiers; RevenueCat processes an opaque account ID and purchase history. Optional analytics uses the network only after consent.", style = TumbleType.sans(11))
            Text("Tumble ${BuildConfig.VERSION_NAME}", style = TumbleType.sans(11), color = Palette.cream.copy(alpha = .55f))
        }
    }, confirmButton = { TextButton(onClick = close) { Text("Done") } })
}

@Composable private fun AccountDialog(account: AccountCoordinator, onLinked: () -> Unit, close: () -> Unit) {
    val activity = LocalActivity.current
    val scope = rememberCoroutineScope()
    val signedIn = account.state as? AuthState.SignedIn
    var confirmDelete by remember { mutableStateOf(false) }
    var showReviewAccess by remember { mutableStateOf(false) }
    AlertDialog(onDismissRequest = close, title = { Text("Tumble Account", style = TumbleType.display(28)) }, text = {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Camera, import, editing and saving never require an account. Sign in only to buy once and use your films across iOS and Android.")
            if (signedIn == null) {
                Button(enabled = activity != null && account.state !is AuthState.Authenticating, onClick = {
                    activity?.let { scope.launch { account.continueWithGoogle(it); if (account.state is AuthState.SignedIn) onLinked() } }
                }, modifier = Modifier.fillMaxWidth()) { Text("Continue with Google") }
                Button(enabled = activity != null && account.state !is AuthState.Authenticating, onClick = {
                    activity?.let { scope.launch { account.continueWithApple(it); if (account.state is AuthState.SignedIn) onLinked() } }
                }, modifier = Modifier.fillMaxWidth()) { Text("Continue with Apple") }
                if (BuildConfig.PLAY_REVIEW_ACCESS) {
                    TextButton(
                        enabled = account.state !is AuthState.Authenticating,
                        onClick = { showReviewAccess = true },
                        modifier = Modifier.align(Alignment.CenterHorizontally),
                    ) { Text("Google Play review access") }
                }
                if (account.state is AuthState.Authenticating) CircularProgressIndicator(color = Palette.gold, modifier = Modifier.align(Alignment.CenterHorizontally))
            } else {
                Text("Signed in", fontWeight = FontWeight.Bold, color = Palette.gold)
                Text("Providers: ${signedIn.providers.joinToString {
                    when (it) {
                        AuthProvider.APPLE -> "Apple"
                        AuthProvider.GOOGLE -> "Google"
                        AuthProvider.PLAY_REVIEW -> "Play review"
                    }
                }}")
                if (AuthProvider.GOOGLE !in signedIn.providers) TextButton(onClick = { activity?.let { scope.launch { account.continueWithGoogle(it, link = true) } } }) { Text("Link Google") }
                if (AuthProvider.APPLE !in signedIn.providers) TextButton(onClick = { activity?.let { scope.launch { account.continueWithApple(it, link = true) } } }) { Text("Link Apple") }
                TextButton(onClick = { account.syncPurchases { if (it) onLinked() } }) { Text("Link existing purchases") }
                TextButton(onClick = { account.signOut(); close() }) { Text("Sign out") }
                TextButton(enabled = activity != null, onClick = { confirmDelete = true }) { Text("Delete account") }
            }
            account.message?.let { Text(it, color = Palette.gold, style = TumbleType.sans(12)) }
        }
    }, confirmButton = { TextButton(onClick = { account.clearMessage(); close() }) { Text("Done") } })

    if (confirmDelete) AlertDialog(
        onDismissRequest = { confirmDelete = false },
        title = { Text("Delete your Tumble account?") },
        text = { Text("This removes your sign-in identity. Photos stay on this device and store purchases remain restorable.") },
        confirmButton = {
            TextButton(onClick = {
                confirmDelete = false
                activity?.let { scope.launch { if (account.deleteAccount(it)) close() } }
            }) { Text("Delete account") }
        },
        dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Cancel") } },
    )

    if (showReviewAccess) PlayReviewAccessDialog(
        busy = account.state is AuthState.Authenticating,
        message = account.message,
        dismiss = {
            account.clearMessage()
            showReviewAccess = false
        },
        signIn = { email, password ->
            scope.launch {
                account.continueForPlayReview(email, password)
                if (account.state is AuthState.SignedIn) {
                    onLinked()
                    showReviewAccess = false
                }
            }
        },
    )
}

@Composable
private fun PlayReviewAccessDialog(
    busy: Boolean,
    message: String?,
    dismiss: () -> Unit,
    signIn: (String, String) -> Unit,
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = dismiss,
        title = { Text("Google Play review", style = TumbleType.display(26)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("For Google Play reviewers only. Use the reusable credentials supplied in Play Console.")
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Reviewer email") },
                    singleLine = true,
                    enabled = !busy,
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    singleLine = true,
                    enabled = !busy,
                    visualTransformation = PasswordVisualTransformation(),
                )
                if (busy) CircularProgressIndicator(color = Palette.gold, modifier = Modifier.align(Alignment.CenterHorizontally))
                message?.let { Text(it, color = Palette.gold, style = TumbleType.sans(12)) }
            }
        },
        confirmButton = {
            TextButton(
                enabled = !busy && email.isNotBlank() && password.isNotBlank(),
                onClick = { signIn(email, password) },
            ) { Text("Sign in") }
        },
        dismissButton = { TextButton(enabled = !busy, onClick = dismiss) { Text("Cancel") } },
    )
}
