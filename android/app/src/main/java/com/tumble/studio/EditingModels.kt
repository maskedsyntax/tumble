package com.tumble.studio

import android.content.Context
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.util.UUID

data class FilmTint(val red: Double = 0.0, val green: Double = 0.0, val blue: Double = 0.0)

data class FilmGrade(
    val saturation: Double = 1.0,
    val contrast: Double = 1.0,
    val brightness: Double = 0.0,
    val blackLift: Double = 0.0,
    val warmth: Double = 0.0,
    val halation: Double = 0.0,
    val grain: Double = 0.0,
    val vignette: Double = 0.0,
    val monochrome: Double = 0.0,
    val monoTint: FilmTint = FilmTint(),
    val fade: Double = 0.0,
    val bloom: Double = 0.0,
    val shadowTint: FilmTint = FilmTint(),
    val shadowStrength: Double = 0.0,
    val highlightTint: FilmTint = FilmTint(),
    val highlightStrength: Double = 0.0,
    val leak: String = "none",
    val leakStrength: Double = 0.0,
    val stampsDate: Boolean = false,
)

data class FilmStock(
    val id: String,
    val name: String,
    val blurb: String,
    val packId: String,
    val grade: FilmGrade,
) {
    val isFree: Boolean get() = packId == "core"
}

data class FilmPack(
    val id: String,
    val name: String,
    val blurb: String,
    val legacyProductId: String?,
)

class FilmCatalog private constructor(
    val version: Int,
    val completeProductId: String,
    val packs: List<FilmPack>,
    val stocks: List<FilmStock>,
) {
    fun stock(id: String?): FilmStock = stocks.firstOrNull { it.id == id }
        ?: stocks.first { it.id == DEFAULT_STOCK_ID }

    companion object {
        const val DEFAULT_STOCK_ID = "fadedInstant"

        fun load(context: Context): FilmCatalog {
            val root = context.assets.open("film-stocks.json").bufferedReader().use { JSONObject(it.readText()) }
            val packsJson = root.getJSONArray("packs")
            val packs = buildList {
                for (index in 0 until packsJson.length()) {
                    val item = packsJson.getJSONObject(index)
                    add(FilmPack(item.getString("id"), item.getString("name"), item.getString("blurb"), item.optString("legacyProductID").ifBlank { null }))
                }
            }
            val stocksJson = root.getJSONArray("stocks")
            val stocks = buildList {
                for (index in 0 until stocksJson.length()) {
                    val item = stocksJson.getJSONObject(index)
                    add(FilmStock(item.getString("id"), item.getString("name"), item.getString("blurb"), item.getString("packID"), grade(item.getJSONObject("grade"))))
                }
            }
            return FilmCatalog(root.getInt("version"), root.getString("completeProductID"), packs, stocks)
        }

        private fun grade(value: JSONObject): FilmGrade = FilmGrade(
            saturation = value.optDouble("saturation", 1.0),
            contrast = value.optDouble("contrast", 1.0),
            brightness = value.optDouble("brightness", 0.0),
            blackLift = value.optDouble("blackLift", 0.0),
            warmth = value.optDouble("warmth", 0.0),
            halation = value.optDouble("halation", 0.0),
            grain = value.optDouble("grain", 0.0),
            vignette = value.optDouble("vignette", 0.0),
            monochrome = value.optDouble("monochrome", 0.0),
            monoTint = tint(value.optJSONObject("monoTint")),
            fade = value.optDouble("fade", 0.0),
            bloom = value.optDouble("bloom", 0.0),
            shadowTint = tint(value.optJSONObject("shadowTint")),
            shadowStrength = value.optDouble("shadowStrength", 0.0),
            highlightTint = tint(value.optJSONObject("highlightTint")),
            highlightStrength = value.optDouble("highlightStrength", 0.0),
            leak = value.optString("leak", "none"),
            leakStrength = value.optDouble("leakStrength", 0.0),
            stampsDate = value.optBoolean("stampsDate", false),
        )

        private fun tint(value: JSONObject?): FilmTint = if (value == null) FilmTint() else FilmTint(
            value.optDouble("red", 0.0), value.optDouble("green", 0.0), value.optDouble("blue", 0.0),
        )
    }
}

enum class SourceKind { CAMERA, LIBRARY }
enum class CropPreset(val label: String, val ratio: Double?) {
    ORIGINAL("Original", null), FREEFORM("Free", null), SQUARE("1:1", 1.0), PORTRAIT("4:5", 4.0 / 5.0), STORY("9:16", 9.0 / 16.0),
}
enum class FrameStyle(val label: String, val aspect: Double) {
    NONE("No frame", 1.0), CLASSIC_INSTANT("Classic", 1.16), VINTAGE_POSTCARD("Vintage", 1.37), BORDERED_FILM("Film", 1.25), DECKLED_EDGE("Deckled", 1.20),
}

data class NormalizedCrop(
    val x: Double = 0.0,
    val y: Double = 0.0,
    val width: Double = 1.0,
    val height: Double = 1.0,
)

data class EditRecipe(
    val stockId: String = FilmCatalog.DEFAULT_STOCK_ID,
    val intensity: Double = 1.0,
    val cropPreset: CropPreset = CropPreset.ORIGINAL,
    val crop: NormalizedCrop = NormalizedCrop(),
    val quarterTurns: Int = 0,
    val frame: FrameStyle = FrameStyle.NONE,
    val note: String = "",
)

data class EditDraft(
    val id: String = UUID.randomUUID().toString(),
    val sourceFile: String,
    val sourceKind: SourceKind,
    val capturedAt: Instant = Instant.now(),
    val recipe: EditRecipe,
    val updatedAt: Instant = Instant.now(),
)

sealed interface AccessState {
    data object Free : AccessState
    data object Complete : AccessState
    data class LegacyPacks(val packIds: Set<String>) : AccessState

    fun unlocks(stock: FilmStock): Boolean = stock.isFree || this is Complete ||
        (this is LegacyPacks && stock.packId in packIds)
}
