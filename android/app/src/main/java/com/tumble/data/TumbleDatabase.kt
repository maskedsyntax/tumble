package com.tumble.data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.tumble.model.Photo

/**
 * The on-device store — no cloud, no account, the entire persistence layer for
 * Photo metadata (pixels live on disk via [PhotoStore]). Mirrors the iOS
 * SwiftData container in `app/TumbleKit/Storage/PhotoStore.swift`.
 */
@Database(entities = [Photo::class], version = 1, exportSchema = false)
@TypeConverters(Converters::class)
abstract class TumbleDatabase : RoomDatabase() {
    abstract fun photoDao(): PhotoDao

    companion object {
        const val NAME = "tumble.db"
    }
}
