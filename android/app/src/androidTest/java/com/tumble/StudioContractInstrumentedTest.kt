package com.tumble

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tumble.studio.DraftRepository
import com.tumble.studio.FilmCatalog
import com.tumble.studio.SourceKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class StudioContractInstrumentedTest {
    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()

    @Test fun sharedManifestHasSixFreeAndFifteenPremiumFilms() {
        val catalog = FilmCatalog.load(context)
        assertEquals(21, catalog.stocks.size)
        assertEquals(6, catalog.stocks.count { it.isFree })
    }

    @Test fun draftSurvivesRepositoryRecreationAndDiscardsSource() {
        val repository = DraftRepository(context).also { it.discard() }
        val draft = repository.create(byteArrayOf(1, 2, 3), SourceKind.LIBRARY, "fadedInstant")
        assertTrue(repository.source(draft).exists())
        assertEquals(draft.id, DraftRepository(context).active?.id)
        repository.discard()
        assertFalse(repository.source(draft).exists())
    }
}
