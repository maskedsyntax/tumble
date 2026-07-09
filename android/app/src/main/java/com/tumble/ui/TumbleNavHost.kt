package com.tumble.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.tumble.ui.collection.DayCollectionScreen
import com.tumble.ui.capture.CaptureScreen
import com.tumble.ui.detail.PrintDetailScreen
import com.tumble.ui.develop.DevelopScreen
import com.tumble.ui.home.HomeScreen
import com.tumble.ui.onboarding.OnboardingScreen
import com.tumble.ui.paywall.PaywallScreen

/** Top-level route names. */
object Routes {
    const val ONBOARDING = "onboarding"
    const val HOME = "home"
    const val CAPTURE = "capture"
    const val DEVELOP = "develop/{photoId}"
    const val DETAIL = "printDetail/{photoId}"
    const val DAY = "dayCollection/{day}"
    const val PAYWALL = "paywall"

    fun develop(photoId: String) = "develop/$photoId"
    fun detail(photoId: String) = "printDetail/$photoId"
    fun day(epochDay: Long) = "dayCollection/$epochDay"
}

@Composable
fun TumbleNavHost(
    navController: NavHostController = rememberNavController(),
    openCameraSignal: Int = 0,
) {
    val root: RootViewModel = hiltViewModel()
    val start = if (root.startOnboarding) Routes.ONBOARDING else Routes.HOME

    // A quick-capture surface (widget/tile/shortcut) asked to open the camera.
    LaunchedEffect(openCameraSignal) {
        if (openCameraSignal > 0 && !root.startOnboarding) {
            navController.navigate(Routes.CAPTURE)
        }
    }

    NavHost(navController = navController, startDestination = start) {
        composable(Routes.ONBOARDING) {
            OnboardingScreen(onFinish = {
                navController.navigate(Routes.HOME) {
                    popUpTo(Routes.ONBOARDING) { inclusive = true }
                }
            })
        }

        composable(Routes.HOME) {
            HomeScreen(
                onOpenPrint = { id, isDeveloped ->
                    // A blank shot opens the develop table; a developed one, the viewer.
                    if (isDeveloped) navController.navigate(Routes.detail(id))
                    else navController.navigate(Routes.develop(id))
                },
                onOpenDay = { epochDay -> navController.navigate(Routes.day(epochDay)) },
                onOpenPaywall = { navController.navigate(Routes.PAYWALL) },
            )
        }

        composable(Routes.CAPTURE) {
            CaptureScreen(
                onClose = { navController.popBackStack() },
                onCaptured = { id ->
                    navController.navigate(Routes.develop(id)) {
                        popUpTo(Routes.CAPTURE) { inclusive = true }
                    }
                },
            )
        }

        composable(
            Routes.DEVELOP,
            arguments = listOf(navArgument("photoId") { type = NavType.StringType }),
        ) {
            DevelopScreen(onClose = { navController.popBackStack() })
        }

        composable(
            Routes.DETAIL,
            arguments = listOf(navArgument("photoId") { type = NavType.StringType }),
        ) {
            PrintDetailScreen(onClose = { navController.popBackStack() })
        }

        composable(
            Routes.DAY,
            arguments = listOf(navArgument("day") { type = NavType.LongType }),
        ) {
            DayCollectionScreen(
                onClose = { navController.popBackStack() },
                onOpenPrint = { id -> navController.navigate(Routes.detail(id)) },
                onDevelop = { id -> navController.navigate(Routes.develop(id)) },
            )
        }

        composable(Routes.PAYWALL) {
            PaywallScreen(onClose = { navController.popBackStack() })
        }
    }
}
