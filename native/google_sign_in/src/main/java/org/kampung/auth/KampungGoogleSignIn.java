package org.kampung.auth;

import android.app.Activity;
import android.os.CancellationSignal;
import androidx.credentials.*;
import androidx.credentials.exceptions.*;
import com.google.android.libraries.identity.googleid.*;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.HashSet;
import java.util.Set;

public class KampungGoogleSignIn extends GodotPlugin {
    private CancellationSignal cancellation;
    private int attempt = 0;
    public KampungGoogleSignIn(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "KampungGoogleSignIn"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("google_token", String.class));
        signals.add(new SignalInfo("google_error", String.class));
        return signals;
    }
    @UsedByGodot public void cancelSignIn() {
        attempt++;
        if (cancellation != null) cancellation.cancel();
        cancellation = null;
    }
    @UsedByGodot public void signIn(String clientId) {
        cancelSignIn();
        final int current = attempt;
        Activity activity = getActivity();
        if (activity == null) { emitSignal("google_error", "Google sign-in is unavailable. Please reopen the game."); return; }
        activity.runOnUiThread(() -> {
            if (current != attempt) return;
            cancellation = new CancellationSignal();
            GetSignInWithGoogleOption option = new GetSignInWithGoogleOption.Builder(clientId).build();
            GetCredentialRequest request = new GetCredentialRequest.Builder().addCredentialOption(option).build();
            CredentialManager.create(activity).getCredentialAsync(activity, request, cancellation,
                runnable -> activity.runOnUiThread(runnable),
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override public void onResult(GetCredentialResponse response) {
                        if (current != attempt) return;
                        try {
                            GoogleIdTokenCredential credential = GoogleIdTokenCredential.createFrom(response.getCredential().getData());
                            emitSignal("google_token", credential.getIdToken());
                        } catch (Exception exception) {
                            emitSignal("google_error", "Google could not verify this account. Please try again.");
                        }
                    }
                    @Override public void onError(GetCredentialException exception) {
                        if (current != attempt) return;
                        String message = exception instanceof GetCredentialCancellationException
                            ? "Google sign-in was cancelled."
                            : "Google sign-in is unavailable. Check your internet connection, Google Play services, and APK certificate setup, then try again.";
                        emitSignal("google_error", message);
                    }
                });
        });
    }
    @Override public void onMainDestroy() { cancelSignIn(); }
}
