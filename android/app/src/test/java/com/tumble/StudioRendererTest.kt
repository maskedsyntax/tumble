package com.tumble

import com.tumble.studio.FilmGrade
import com.tumble.studio.StudioRenderer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class StudioRendererTest {
    @Test fun exportCapPreservesLandscapeRatio() {
        assertEquals(4096 to 2731, StudioRenderer.scaledDimensions(6000, 4000, 4096))
    }

    @Test fun everyGradeUsesDeterministicTextureSeed() {
        val grade = FilmGrade(saturation = .62, contrast = .8, blackLift = .11, grain = .24)
        val first = StudioRenderer.gradePixel(0xff334455.toInt(), grade, 42, 99, .7, .3, .8)
        val second = StudioRenderer.gradePixel(0xff334455.toInt(), grade, 42, 99, .7, .3, .8)
        val otherSeed = StudioRenderer.gradePixel(0xff334455.toInt(), grade, 42, 100, .7, .3, .8)
        assertEquals(first, second)
        assertNotEquals(first, otherSeed)
    }
}
