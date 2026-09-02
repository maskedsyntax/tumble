package com.tumble.ui.studio

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.RotateRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.SaveAlt
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.tumble.studio.AccessState
import com.tumble.studio.CropPreset
import com.tumble.studio.DraftRepository
import com.tumble.studio.EditDraft
import com.tumble.studio.EditRecipe
import com.tumble.studio.FilmCatalog
import com.tumble.studio.FrameStyle
import com.tumble.studio.StudioExporter
import com.tumble.studio.StudioRenderer
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

@Composable
fun StudioScreen(
    draft: EditDraft,
    catalog: FilmCatalog,
    drafts: DraftRepository,
    access: AccessState,
    onLockedFilm: () -> Unit,
    onClose: () -> Unit,
    onSaved: () -> Unit,
) {
    val context = LocalContext.current
    val renderer = remember { StudioRenderer() }
    val exporter = remember { StudioExporter(context.applicationContext) }
    val scope = rememberCoroutineScope()
    var recipe by remember(draft.id) { mutableStateOf(draft.recipe) }
    var preview by remember { mutableStateOf<Bitmap?>(null) }
    var original by remember { mutableStateOf<Bitmap?>(null) }
    var compareOriginal by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var discardPrompt by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(recipe) {
        drafts.update(recipe)
        val pair = withContext(Dispatchers.Default) {
            val source = renderer.decode(drafts.source(draft), 1600) ?: return@withContext null
            val film = renderer.render(source, catalog.stock(recipe.stockId), recipe, draft.id.hashCode(), 1200, draft.capturedAt)
            val sourceRecipe = recipe.copy(intensity = 0.0, frame = FrameStyle.NONE, note = "")
            val clean = renderer.render(source, catalog.stock(recipe.stockId), sourceRecipe, draft.id.hashCode(), 1200, draft.capturedAt)
            clean to renderer.composeFrame(film, recipe, draft.capturedAt, 1200)
        }
        if (pair != null) { original = pair.first; preview = pair.second }
    }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            StudioHeader(catalog.stock(recipe.stockId).name) { discardPrompt = true }

            Column(
                Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                val shown = if (compareOriginal) original else preview
                val aspect = shown?.let { it.width.toFloat() / it.height.coerceAtLeast(1) }?.coerceIn(.72f, 1.7f) ?: 4f / 3f
                PreviewCard(shown, aspect, compareOriginal, catalog.stock(recipe.stockId).name) { compareOriginal = it }

                EditorCard {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Text("Film", style = TumbleType.display(22), color = Palette.cream)
                        Spacer(Modifier.weight(1f))
                        Text("${catalog.stocks.size} looks", style = TumbleType.sans(10, FontWeight.SemiBold), color = Palette.cream.copy(alpha = .42f))
                    }
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                        catalog.stocks.forEach { stock ->
                            val unlocked = access.unlocks(stock)
                            FilterChip(
                                selected = recipe.stockId == stock.id,
                                onClick = { if (unlocked) recipe = recipe.copy(stockId = stock.id) else onLockedFilm() },
                                label = { Text(if (unlocked) stock.name else "🔒 ${stock.name}") },
                            )
                        }
                    }
                    HorizontalDivider(color = Palette.cream.copy(alpha = .08f))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.size(width = 105.dp, height = 44.dp)) {
                            Text("Intensity", style = TumbleType.sans(13, FontWeight.SemiBold), color = Palette.cream)
                            Text("Film blend", style = TumbleType.sans(9), color = Palette.cream.copy(alpha = .45f))
                        }
                        Slider(recipe.intensity.toFloat(), { recipe = recipe.copy(intensity = it.toDouble()) }, Modifier.weight(1f))
                        Text("${(recipe.intensity * 100).toInt()}", style = TumbleType.sans(11, FontWeight.Bold), color = Palette.cream, modifier = Modifier.padding(start = 6.dp))
                    }
                }

                EditorCard {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Column {
                            Text("Crop", style = TumbleType.display(22), color = Palette.cream)
                            Text("Choose the final composition", style = TumbleType.sans(9), color = Palette.cream.copy(alpha = .45f))
                        }
                        Spacer(Modifier.weight(1f))
                        TextButton(onClick = { recipe = recipe.copy(quarterTurns = (recipe.quarterTurns + 1) % 4) }) {
                            Icon(Icons.AutoMirrored.Filled.RotateRight, null, tint = Palette.cream)
                            Text(" Rotate", color = Palette.cream, style = TumbleType.sans(11, FontWeight.Bold))
                        }
                    }
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                        CropPreset.entries.forEach { preset ->
                            FilterChip(recipe.cropPreset == preset, {
                                recipe = recipe.copy(cropPreset = preset, crop = if (preset == CropPreset.FREEFORM) recipe.crop else com.tumble.studio.NormalizedCrop())
                            }, label = { Text(preset.label) })
                        }
                    }
                    if (recipe.cropPreset == CropPreset.FREEFORM) {
                        Column(Modifier.fillMaxWidth().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = .14f), RoundedCornerShape(14.dp)).padding(10.dp)) {
                            CropSlider("Width", recipe.crop.width.toFloat(), .2f..1f) {
                                recipe = recipe.copy(crop = recipe.crop.copy(width = it.toDouble(), x = recipe.crop.x.coerceAtMost(1.0 - it.toDouble())))
                            }
                            CropSlider("Height", recipe.crop.height.toFloat(), .2f..1f) {
                                recipe = recipe.copy(crop = recipe.crop.copy(height = it.toDouble(), y = recipe.crop.y.coerceAtMost(1.0 - it.toDouble())))
                            }
                            CropSlider("Horizontal", recipe.crop.x.toFloat(), 0f..(1 - recipe.crop.width).toFloat().coerceAtLeast(.001f)) {
                                recipe = recipe.copy(crop = recipe.crop.copy(x = it.toDouble()))
                            }
                            CropSlider("Vertical", recipe.crop.y.toFloat(), 0f..(1 - recipe.crop.height).toFloat().coerceAtLeast(.001f)) {
                                recipe = recipe.copy(crop = recipe.crop.copy(y = it.toDouble()))
                            }
                        }
                    }
                    HorizontalDivider(color = Palette.cream.copy(alpha = .08f))
                    Column {
                        Text("Postcard", style = TumbleType.display(22), color = Palette.cream)
                        Text("Optional frame and handwritten note", style = TumbleType.sans(9), color = Palette.cream.copy(alpha = .45f))
                    }
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                        FrameStyle.entries.forEach { frame ->
                            FilterChip(recipe.frame == frame, { recipe = recipe.copy(frame = frame) }, label = { Text(frame.label) })
                        }
                    }
                    if (recipe.frame != FrameStyle.NONE) {
                        TextField(
                            recipe.note,
                            { recipe = recipe.copy(note = it.replace('\n', ' ').take(60)) },
                            Modifier.fillMaxWidth(),
                            placeholder = { Text("Write something small…") },
                            singleLine = true,
                        )
                    }
                }
                Spacer(Modifier.height(4.dp))
            }

            Row(
                Modifier.fillMaxWidth().background(Palette.blueDeep.copy(alpha = .98f)).navigationBarsPadding().padding(horizontal = 16.dp, vertical = 11.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Button(
                    enabled = !busy && preview != null,
                    onClick = {
                        scope.launch {
                            busy = true
                            val data = renderExport(renderer, drafts, draft, catalog, recipe)
                            busy = false
                            if (data == null) { message = "The image could not be prepared. Your draft is safe."; return@launch }
                            val file = File(context.cacheDir, "tumble-share.jpg").apply { writeBytes(data) }
                            val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
                            context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                                type = "image/jpeg"; putExtra(Intent.EXTRA_STREAM, uri); addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }, "Share Tumble photo"))
                        }
                    },
                    modifier = Modifier.weight(1f).height(54.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Palette.cream.copy(alpha = .10f), contentColor = Palette.cream),
                    shape = RoundedCornerShape(17.dp),
                ) { Icon(Icons.Default.Share, null); Text("  Share", fontWeight = FontWeight.Bold) }

                Button(
                    enabled = !busy && preview != null,
                    onClick = {
                        scope.launch {
                            busy = true
                            val data = renderExport(renderer, drafts, draft, catalog, recipe)
                            val saved = data != null && exporter.save(data)
                            busy = false
                            if (saved) { drafts.discard(); onSaved(); onClose() }
                            else message = "The photo could not be saved. Your private draft is still safe."
                        }
                    },
                    modifier = Modifier.weight(1.35f).height(54.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Palette.gold, contentColor = Palette.ink),
                    shape = RoundedCornerShape(17.dp),
                ) {
                    if (busy) CircularProgressIndicator(Modifier.size(18.dp), color = Palette.ink, strokeWidth = 2.dp)
                    else Icon(Icons.Default.SaveAlt, null)
                    Text("  Save photo", fontWeight = FontWeight.Bold)
                }
            }
        }
    }

    if (discardPrompt) AlertDialog(
        onDismissRequest = { discardPrompt = false },
        title = { Text("Discard this edit?") },
        text = { Text("The original and edits have not been saved to your gallery.") },
        confirmButton = { TextButton(onClick = { drafts.discard(); discardPrompt = false; onClose() }) { Text("Discard") } },
        dismissButton = { TextButton(onClick = { discardPrompt = false }) { Text("Keep editing") } },
    )
    message?.let { text -> AlertDialog(onDismissRequest = { message = null }, confirmButton = { TextButton(onClick = { message = null }) { Text("OK") } }, text = { Text(text) }) }
}

@Composable
private fun StudioHeader(stockName: String, cancel: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = cancel, modifier = Modifier.size(42.dp).background(Palette.cream.copy(alpha = .10f), CircleShape)) {
            Icon(Icons.Default.Close, "Cancel editing", tint = Palette.cream)
        }
        Spacer(Modifier.weight(1f))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Studio", style = TumbleType.display(25), color = Palette.cream)
            Text(stockName, style = TumbleType.sans(10, FontWeight.SemiBold), color = Palette.gold)
        }
        Spacer(Modifier.weight(1f))
        Spacer(Modifier.size(42.dp))
    }
}

@Composable
private fun PreviewCard(image: Bitmap?, aspect: Float, original: Boolean, stockName: String, compare: (Boolean) -> Unit) {
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Palette.charcoalDeep.copy(alpha = .78f))) {
        Box(Modifier.fillMaxWidth().aspectRatio(aspect).background(androidx.compose.ui.graphics.Color.Black.copy(alpha = .28f)), contentAlignment = Alignment.Center) {
            image?.let { Image(it.asImageBitmap(), null, Modifier.fillMaxSize().padding(8.dp).clip(RoundedCornerShape(18.dp)), contentScale = ContentScale.Fit) }
                ?: CircularProgressIndicator(color = Palette.gold)
        }
        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text(if (original) "SOURCE" else "FILM PREVIEW", style = TumbleType.sans(9, FontWeight.Bold), color = Palette.cream.copy(alpha = .48f))
                Text(if (original) "Original" else stockName, style = TumbleType.sans(13, FontWeight.Bold), color = Palette.cream)
            }
            Spacer(Modifier.weight(1f))
            Row(Modifier.clip(CircleShape).background(Palette.blueDeep)) {
                CompareButton("Original", original) { compare(true) }
                CompareButton("Film", !original) { compare(false) }
            }
        }
    }
}

@Composable private fun CompareButton(label: String, selected: Boolean, action: () -> Unit) {
    TextButton(onClick = action, colors = ButtonDefaults.textButtonColors(containerColor = if (selected) Palette.gold else androidx.compose.ui.graphics.Color.Transparent)) {
        Text(label, style = TumbleType.sans(10, FontWeight.SemiBold), color = if (selected) Palette.ink else Palette.cream)
    }
}

@Composable private fun EditorCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().background(Palette.blueDeep.copy(alpha = .82f), RoundedCornerShape(22.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
        content = content,
    )
}

@Composable private fun CropSlider(label: String, value: Float, range: ClosedFloatingPointRange<Float>, update: (Float) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = TumbleType.sans(10, FontWeight.SemiBold), color = Palette.cream, modifier = Modifier.size(width = 72.dp, height = 28.dp))
        Slider(value, update, Modifier.weight(1f), valueRange = range)
    }
}

private suspend fun renderExport(renderer: StudioRenderer, drafts: DraftRepository, draft: EditDraft, catalog: FilmCatalog, recipe: EditRecipe): ByteArray? = withContext(Dispatchers.Default) {
    val source = renderer.decode(drafts.source(draft), 8192) ?: return@withContext null
    val film = renderer.render(source, catalog.stock(recipe.stockId), recipe, draft.id.hashCode(), 4096, draft.capturedAt)
    renderer.jpeg(renderer.composeFrame(film, recipe, draft.capturedAt, 4096))
}
