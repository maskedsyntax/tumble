package com.tumble.studio

import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File
import java.time.Instant

class DraftRepository(context: Context) {
    private val root = File(context.noBackupFilesDir, "tumble-draft").apply { mkdirs() }
    private val metadata = File(root, "draft.json")

    var active: EditDraft? = load()
        private set

    @Synchronized
    fun create(bytes: ByteArray, source: SourceKind, stockId: String): EditDraft {
        discard()
        val name = "${java.util.UUID.randomUUID()}-source"
        val sourceFile = File(root, name)
        try {
            AtomicFile(sourceFile).writeBytes(bytes)
            val draft = EditDraft(sourceFile = name, sourceKind = source, recipe = EditRecipe(stockId = stockId))
            persist(draft)
            active = draft
            cleanupOrphans()
            return draft
        } catch (error: Throwable) {
            sourceFile.delete()
            throw error
        }
    }

    @Synchronized
    fun update(recipe: EditRecipe): EditDraft? {
        val current = active ?: return null
        val next = current.copy(recipe = recipe, updatedAt = Instant.now())
        persist(next)
        active = next
        return next
    }

    fun source(draft: EditDraft): File = File(root, draft.sourceFile)

    @Synchronized
    fun discard() {
        active?.let { File(root, it.sourceFile).delete() }
        metadata.delete()
        active = null
        cleanupOrphans()
    }

    private fun persist(draft: EditDraft) {
        AtomicFile(metadata).writeBytes(draft.toJson().toString().toByteArray())
    }

    private fun load(): EditDraft? = runCatching {
        if (!metadata.exists()) return null
        val value = draftFromJson(JSONObject(metadata.readText()))
        if (!source(value).exists()) {
            metadata.delete()
            null
        } else value
    }.getOrNull()

    private fun cleanupOrphans() {
        val keep = active?.sourceFile
        root.listFiles()?.filter { it.name != "draft.json" && it.name != keep }?.forEach(File::delete)
    }
}

private fun AtomicFile.writeBytes(bytes: ByteArray) {
    val stream = startWrite()
    try {
        stream.write(bytes)
        finishWrite(stream)
    } catch (error: Throwable) {
        failWrite(stream)
        throw error
    }
}

private fun EditDraft.toJson(): JSONObject = JSONObject()
    .put("id", id).put("sourceFile", sourceFile).put("sourceKind", sourceKind.name)
    .put("capturedAt", capturedAt.toString()).put("updatedAt", updatedAt.toString())
    .put("recipe", recipe.toJson())

private fun EditRecipe.toJson(): JSONObject = JSONObject()
    .put("stockId", stockId).put("intensity", intensity).put("cropPreset", cropPreset.name)
    .put("quarterTurns", quarterTurns).put("frame", frame.name).put("note", note.take(60))
    .put("crop", JSONObject().put("x", crop.x).put("y", crop.y).put("width", crop.width).put("height", crop.height))

private fun draftFromJson(value: JSONObject): EditDraft {
    val recipe = value.getJSONObject("recipe")
    val crop = recipe.getJSONObject("crop")
    return EditDraft(
        id = value.getString("id"), sourceFile = value.getString("sourceFile"),
        sourceKind = SourceKind.valueOf(value.getString("sourceKind")), capturedAt = Instant.parse(value.getString("capturedAt")),
        updatedAt = Instant.parse(value.getString("updatedAt")),
        recipe = EditRecipe(
            stockId = recipe.getString("stockId"), intensity = recipe.getDouble("intensity"),
            cropPreset = CropPreset.valueOf(recipe.getString("cropPreset")),
            crop = NormalizedCrop(crop.getDouble("x"), crop.getDouble("y"), crop.getDouble("width"), crop.getDouble("height")),
            quarterTurns = recipe.getInt("quarterTurns"), frame = FrameStyle.valueOf(recipe.getString("frame")), note = recipe.getString("note"),
        ),
    )
}
