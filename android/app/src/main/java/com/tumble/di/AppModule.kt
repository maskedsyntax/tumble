package com.tumble.di

import android.content.Context
import androidx.room.Room
import com.tumble.data.PhotoDao
import com.tumble.data.PhotoStore
import com.tumble.data.TumbleDatabase
import com.tumble.data.TumblePrefs
import com.tumble.roll.RollManager
import com.tumble.roll.RollStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): TumbleDatabase =
        Room.databaseBuilder(context, TumbleDatabase::class.java, TumbleDatabase.NAME)
            .fallbackToDestructiveMigration(dropAllTables = true)
            .build()

    @Provides
    fun providePhotoDao(db: TumbleDatabase): PhotoDao = db.photoDao()

    @Provides
    @Singleton
    fun providePhotoStore(@ApplicationContext context: Context): PhotoStore =
        PhotoStore(context)

    @Provides
    @Singleton
    fun provideTumblePrefs(@ApplicationContext context: Context): TumblePrefs =
        TumblePrefs(context)

    @Provides
    fun provideRollStore(prefs: TumblePrefs): RollStore = prefs

    @Provides
    @Singleton
    fun provideRollManager(store: RollStore): RollManager = RollManager(store)
}
