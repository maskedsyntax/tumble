package com.tumble.account

import android.app.Activity
import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.OAuthProvider
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.getCustomerInfoWith
import com.revenuecat.purchases.logInWith
import com.revenuecat.purchases.logOutWith
import com.revenuecat.purchases.syncPurchasesWith
import com.tumble.BuildConfig
import com.tumble.R
import com.tumble.studio.AccessState
import kotlinx.coroutines.tasks.await

enum class AuthProvider { APPLE, GOOGLE }

sealed interface AuthState {
    data object SignedOut : AuthState
    data object Authenticating : AuthState
    data class SignedIn(val uid: String, val providers: Set<AuthProvider>) : AuthState
    data class Error(val message: String) : AuthState
}

class AccountCoordinator(private val context: Context) {
    var state by mutableStateOf<AuthState>(AuthState.SignedOut)
        private set
    var accountAccess by mutableStateOf<AccessState>(AccessState.Free)
        private set
    var message by mutableStateOf<String?>(null)
        private set

    private val auth = FirebaseAuth.getInstance()
    private val credentialManager = CredentialManager.create(context)
    private val revenueCatReady get() = BuildConfig.REVENUECAT_API_KEY.isNotBlank()
    private var identifiedUid: String? = null

    private val authListener = FirebaseAuth.AuthStateListener { firebase ->
        val user = firebase.currentUser
        state = if (user == null) AuthState.SignedOut else AuthState.SignedIn(
            user.uid,
            user.providerData.mapNotNull {
                when (it.providerId) {
                    "apple.com" -> AuthProvider.APPLE
                    "google.com" -> AuthProvider.GOOGLE
                    else -> null
                }
            }.toSet(),
        )
    }

    init {
        auth.addAuthStateListener(authListener)
        if (revenueCatReady) {
            Purchases.sharedInstance.updatedCustomerInfoListener = UpdatedCustomerInfoListener(::applyCustomerInfo)
            auth.currentUser?.let { user -> identify(user.uid) }
        }
    }

    suspend fun continueWithGoogle(activity: Activity, link: Boolean = false) {
        state = AuthState.Authenticating
        runCatching {
            val firebaseCredential = googleCredential(activity)
            val user = if (link && auth.currentUser != null) {
                auth.currentUser!!.linkWithCredential(firebaseCredential).await().user
            } else {
                auth.signInWithCredential(firebaseCredential).await().user
            } ?: error("Google sign-in did not return an account.")
            identify(user.uid)
        }.onFailure(::handleAuthFailure)
    }

    suspend fun continueWithApple(activity: Activity, link: Boolean = false) {
        state = AuthState.Authenticating
        runCatching {
            val provider = appleProvider()
            val user = if (link && auth.currentUser != null) {
                auth.currentUser!!.startActivityForLinkWithProvider(activity, provider).await().user
            } else {
                val pending = auth.pendingAuthResult
                (pending ?: auth.startActivityForSignInWithProvider(activity, provider)).await().user
            } ?: error("Apple sign-in did not return an account.")
            identify(user.uid)
        }.onFailure(::handleAuthFailure)
    }

    fun refresh() {
        if (!revenueCatReady || auth.currentUser?.uid != identifiedUid) return
        Purchases.sharedInstance.getCustomerInfoWith(
            onError = { message = it.message },
            onSuccess = ::applyCustomerInfo,
        )
    }

    fun syncPurchases(onComplete: (Boolean) -> Unit = {}) {
        if (!revenueCatReady || auth.currentUser == null) {
            onComplete(false)
            return
        }
        Purchases.sharedInstance.syncPurchasesWith(
            onError = { message = it.message; onComplete(false) },
            onSuccess = { applyCustomerInfo(it); onComplete(true) },
        )
    }

    fun signOut() {
        identifiedUid = null
        auth.signOut()
        accountAccess = AccessState.Free
        if (revenueCatReady) {
            Purchases.sharedInstance.logOutWith(
                onError = { message = it.message },
                onSuccess = {},
            )
        }
    }

    suspend fun deleteAccount(activity: Activity): Boolean = runCatching {
        val user = auth.currentUser ?: return@runCatching true
        state = AuthState.Authenticating
        when {
            user.providerData.any { it.providerId == "apple.com" } ->
                user.startActivityForReauthenticateWithProvider(activity, appleProvider()).await()
            user.providerData.any { it.providerId == "google.com" } ->
                user.reauthenticate(googleCredential(activity)).await()
        }
        identifiedUid = null
        user.delete().await()
        accountAccess = AccessState.Free
        if (revenueCatReady) Purchases.sharedInstance.logOutWith(onError = {}, onSuccess = {})
        true
    }.getOrElse { handleAuthFailure(it); false }

    fun clearMessage() { message = null }

    private suspend fun googleCredential(activity: Activity) = run {
        val option = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(context.getString(R.string.default_web_client_id))
            .setAutoSelectEnabled(false)
            .build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
        val result = credentialManager.getCredential(activity, request)
        val credential = result.credential
        require(credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL)
        val token = GoogleIdTokenCredential.createFrom(credential.data)
        GoogleAuthProvider.getCredential(token.idToken, null)
    }

    private fun appleProvider() = OAuthProvider.newBuilder("apple.com").apply {
        scopes = listOf("email", "name")
    }.build()

    private fun identify(uid: String) {
        if (!revenueCatReady) return
        identifiedUid = uid
        Purchases.sharedInstance.logInWith(
            appUserID = uid,
            onError = { message = it.message },
            onSuccess = { customerInfo, _ -> applyCustomerInfo(customerInfo) },
        )
    }

    private fun applyCustomerInfo(info: CustomerInfo) {
        if (auth.currentUser?.uid != identifiedUid) {
            accountAccess = AccessState.Free
            return
        }
        val ids = info.entitlements.active.keys
        accountAccess = when {
            "complete" in ids -> AccessState.Complete
            else -> AccessState.LegacyPacks(buildSet {
                if ("pack_nineties" in ids) add("nineties")
                if ("pack_darkroom" in ids) add("darkroom")
                if ("pack_summer" in ids) add("summer")
            }).takeUnless { it.packIds.isEmpty() } ?: AccessState.Free
        }
    }

    private fun handleAuthFailure(error: Throwable) {
        val text = if (error is FirebaseAuthUserCollisionException) {
            "This credential belongs to another Tumble account. Sign in with the existing provider first, then link this provider in Account settings."
        } else {
            error.localizedMessage ?: "Authentication could not be completed."
        }
        message = text
        state = auth.currentUser?.let { user ->
            AuthState.SignedIn(
                user.uid,
                user.providerData.mapNotNull {
                    when (it.providerId) {
                        "apple.com" -> AuthProvider.APPLE
                        "google.com" -> AuthProvider.GOOGLE
                        else -> null
                    }
                }.toSet(),
            )
        } ?: AuthState.Error(text)
    }
}
