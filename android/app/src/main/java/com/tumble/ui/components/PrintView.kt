package com.tumble.ui.components

import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.RenderEffect
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import com.tumble.ui.theme.grain

/**
 * A single instant print, mounted on cream stock — the exact treatment from the
 * site's `DrawerMockup`: the photograph, a warm aged grade that grows with age,
 * film grain, a vignette, and a soft sheen. Also renders the blank, face-down
 * state for an undeveloped shot.
 *
 * [developProgress] (0…1) drives the shake-to-develop look: it starts washed out
 * and desaturated and settles into full color. Ported from
 * `app/TumbleKit/Views/PrintView.swift`.
 */
@Composable
fun PrintView(
    image: ImageBitmap?,
    isDeveloped: Boolean,
    modifier: Modifier = Modifier,
    developProgress: Float = 1f,
    age: Float = 0f,
    caption: String? = null,
    width: Dp = 200.dp,
) {
    val pad = width * 0.06f
    Column(
        modifier = modifier
            .width(width)
            .shadow(width * 0.06f, RoundedCornerShape(width * 0.025f))
            .clip(RoundedCornerShape(width * 0.025f))
            .background(Palette.printStock)
            .padding(PaddingValues(start = pad, top = pad, end = pad, bottom = width * 0.09f)),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        val photoCorner = RoundedCornerShape(width * 0.01f)
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(photoCorner)
                .border(0.5.dp, Color.Black.copy(alpha = 0.15f), photoCorner),
        ) {
            if (isDeveloped || developProgress > 0f) {
                DevelopedPhoto(image = image, developProgress = developProgress, age = age)
            } else {
                UndevelopedFace(width = width)
            }
        }

        if (caption != null && isDeveloped) {
            Text(
                text = caption,
                style = TumbleType.display((width.value * 0.052f).toInt().coerceAtLeast(8), FontWeight.Normal)
                    .copy(fontStyle = FontStyle.Italic, color = Palette.ink.copy(alpha = 0.7f)),
                modifier = Modifier.padding(top = width * 0.06f),
            )
        }
    }
}

@Composable
private fun DevelopedPhoto(image: ImageBitmap?, developProgress: Float, age: Float) {
    val p = developProgress.coerceIn(0f, 1f)
    androidx.compose.foundation.layout.Box(Modifier.fillMaxSize()) {
        // The develop transition desaturates the whole print at first (saturation
        // ramps with progress) — applied as a layer RenderEffect (API 31+).
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    clip = true
                    renderEffect = saturationEffect(p)
                }
                .drawWithContent {
                    drawContent() // the scene image / fallback
                    // Warm aged grade — warm over cool, both scaling with age.
                    drawRect(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                Color(0xFFD6965A).copy(alpha = 0.12f + age * 0.24f),
                                Color(0xFF78463C).copy(alpha = 0.06f + age * 0.16f),
                            ),
                            start = Offset.Zero,
                            end = Offset(size.width, size.height),
                        ),
                        blendMode = BlendMode.Multiply,
                    )
                    // Film grain.
                    drawRect(brush = com.tumble.ui.theme.Grain.brush, alpha = 0.4f, blendMode = BlendMode.Overlay)
                    // Vignette — clear center, dark edges (center biased upward).
                    drawRect(
                        brush = Brush.radialGradient(
                            0.42f to Color.Transparent,
                            1f to Color(0xFF1C1012).copy(alpha = 0.42f),
                            center = Offset(0.5f * size.width, 0.44f * size.height),
                            radius = 0.72f * size.width,
                        ),
                    )
                    // Sheen — glossy highlight top-left.
                    drawRect(
                        brush = Brush.linearGradient(
                            colors = listOf(Color.White.copy(alpha = 0.16f), Color.Transparent),
                            start = Offset.Zero,
                            end = Offset(0.34f * size.width, 0.34f * size.height),
                        ),
                    )
                },
        ) {
            if (image != null) {
                androidx.compose.foundation.Image(
                    bitmap = image,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
            } else {
                androidx.compose.foundation.layout.Box(
                    Modifier.fillMaxSize().background(Color(0xFF2A3A49)),
                )
            }
        }

        // Washed-out overlay + brightness lift that fade as the print develops.
        androidx.compose.foundation.layout.Box(
            Modifier.fillMaxSize().background(Color.White.copy(alpha = (1f - p) * 0.65f)),
        )
        androidx.compose.foundation.layout.Box(
            Modifier.fillMaxSize().background(Color.White.copy(alpha = (1f - p) * 0.18f)),
        )
    }
}

@Composable
private fun UndevelopedFace(width: Dp) {
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(listOf(Color(0xFFE8DFCC), Color(0xFFD8CDB4))),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Outlined.Draw,
            contentDescription = null,
            tint = Palette.ink.copy(alpha = 0.25f),
            modifier = Modifier.width(width * 0.12f),
        )
    }
}

/** Saturation color-matrix as a Compose [androidx.compose.ui.graphics.RenderEffect]. */
private fun saturationEffect(progress: Float): androidx.compose.ui.graphics.RenderEffect {
    val matrix = ColorMatrix().apply { setSaturation(progress) }
    return RenderEffect
        .createColorFilterEffect(ColorMatrixColorFilter(matrix))
        .asComposeRenderEffect()
}
