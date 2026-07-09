package com.tumble.ui

import androidx.lifecycle.ViewModel
import com.tumble.data.TumblePrefs
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

/** Decides the first screen: onboarding until the shooter has completed it. */
@HiltViewModel
class RootViewModel @Inject constructor(prefs: TumblePrefs) : ViewModel() {
    val startOnboarding: Boolean = !prefs.hasOnboarded.value
}
