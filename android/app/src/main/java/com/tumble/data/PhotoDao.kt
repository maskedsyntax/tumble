package com.tumble.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.tumble.model.Photo
import kotlinx.coroutines.flow.Flow

@Dao
interface PhotoDao {
    @Query("SELECT * FROM photos ORDER BY capturedAt DESC")
    fun observeAll(): Flow<List<Photo>>

    @Query("SELECT * FROM photos WHERE id = :id")
    fun observeById(id: String): Flow<Photo?>

    @Query("SELECT * FROM photos WHERE id = :id")
    suspend fun byId(id: String): Photo?

    @Query("SELECT * FROM photos ORDER BY capturedAt DESC")
    suspend fun all(): List<Photo>

    /** Insert or replace — Photo is immutable, so updates arrive as a fresh copy. */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(photo: Photo)

    @Delete
    suspend fun delete(photo: Photo)
}
