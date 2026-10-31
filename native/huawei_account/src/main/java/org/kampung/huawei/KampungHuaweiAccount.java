package org.kampung.huawei;

import android.app.Activity;
import android.content.Intent;
import com.huawei.hms.api.HuaweiApiAvailability;
import com.huawei.hmf.tasks.Task;
import com.huawei.hms.common.ApiException;
import com.huawei.hms.support.account.AccountAuthManager;
import com.huawei.hms.support.account.request.AccountAuthParams;
import com.huawei.hms.support.account.request.AccountAuthParamsHelper;
import com.huawei.hms.support.account.result.AuthAccount;
import com.huawei.hms.support.account.service.AccountAuthService;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.HashSet;
import java.util.Set;

public class KampungHuaweiAccount extends GodotPlugin {
    private static final int REQUEST = 43413;
    private volatile boolean accepting = false;
    private volatile int generation = 0;
    private boolean awaitingResult = false;
    private AccountAuthService service;
    public KampungHuaweiAccount(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "KampungHuaweiAccount"; }
    @UsedByGodot public int getHmsStatus() {
        Activity activity = getActivity();
        return activity == null ? -1 : HuaweiApiAvailability.getInstance().isHuaweiMobileServicesAvailable(activity);
    }
    @Override public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> result = new HashSet<>();
        result.add(new SignalInfo("huawei_account", String.class, String.class));
        result.add(new SignalInfo("huawei_error", String.class));
        return result;
    }
    @UsedByGodot public void signIn() {
        final int current = ++generation;
        Activity activity = getActivity();
        if (activity == null) { emitSignal("huawei_error", "Please reopen the game and try Huawei sign-in again."); return; }
        activity.runOnUiThread(() -> {
            if (current != generation) return;
            if (awaitingResult) { emitSignal("huawei_error", "Close the previous Huawei sign-in screen before trying again."); return; }
            try {
                // Basic SDK sign-in only: no app secret, auth code or token crosses into Godot.
                AccountAuthParams params = new AccountAuthParamsHelper(AccountAuthParams.DEFAULT_AUTH_REQUEST_PARAM).createParams();
                service = AccountAuthManager.getService(activity, params);
                accepting = true;
                awaitingResult = true;
                activity.startActivityForResult(service.getSignInIntent(), REQUEST);
            } catch (Exception error) {
                accepting = false;
                awaitingResult = false;
                emitSignal("huawei_error", "Huawei sign-in could not start. Check HMS Core and the app registration.");
            }
        });
    }
    @Override public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST) return;
        awaitingResult = false;
        if (!accepting) return;
        accepting = false;
        if (resultCode == Activity.RESULT_CANCELED) { emitSignal("huawei_error", "Huawei sign-in was cancelled."); return; }
        try {
            Task<AuthAccount> task = AccountAuthManager.parseAuthResultFromIntent(data);
            if (!task.isSuccessful()) {
                Exception error = task.getException();
                int code = error instanceof ApiException ? ((ApiException) error).getStatusCode() : -1;
                emitSignal("huawei_error", "Huawei sign-in failed (" + code + "). Check your connection, Account Kit configuration and APK signing fingerprint.");
                return;
            }
            AuthAccount account = task.getResult();
            if (account == null || account.getOpenId() == null || account.getOpenId().isEmpty()) {
                emitSignal("huawei_error", "Huawei returned an incomplete account. Please try again.");
                return;
            }
            emitSignal("huawei_account", account.getOpenId(), account.getDisplayName() == null ? "" : account.getDisplayName());
        } catch (Exception error) { emitSignal("huawei_error", "Huawei sign-in could not be completed. Please try again."); }
    }
    @UsedByGodot public void cancelSignIn() { generation++; accepting = false; }
    @UsedByGodot public void signOut() {
        cancelSignIn();
        Activity activity = getActivity();
        if (activity != null) activity.runOnUiThread(() -> { if (service != null) service.signOut(); });
    }
    @Override public void onMainDestroy() { cancelSignIn(); }
}
