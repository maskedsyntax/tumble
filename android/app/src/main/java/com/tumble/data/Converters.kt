package com.tumble.data

import androidx.room.TypeConverter
import java.time.Instant

/** Room converters for the fields Photo stores that aren't primitives. */
class Converters {
    @TypeConverter
    fun instantToEpochMs(value: Instant?): Long? = value?.toEpochMilli()

    @TypeConverter
    fun epochMsToInstant(value: Long?): Instant? = value?.let(Instant::ofEpochMilli)
}
