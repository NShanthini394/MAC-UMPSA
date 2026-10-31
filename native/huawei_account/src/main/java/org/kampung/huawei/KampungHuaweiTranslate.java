package org.kampung.huawei;

import android.app.Activity;
import com.huawei.hms.mlsdk.common.MLApplication;
import com.huawei.hms.mlsdk.common.MLApplicationSetting;
import com.huawei.hms.mlsdk.translate.MLTranslateLanguage;
import com.huawei.hms.mlsdk.translate.MLTranslatorFactory;
import com.huawei.hms.mlsdk.translate.cloud.MLRemoteTranslateSetting;
import com.huawei.hms.mlsdk.translate.cloud.MLRemoteTranslator;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.HashSet;
import java.util.Set;

public class KampungHuaweiTranslate extends GodotPlugin {
    private volatile int active = -1;
    private MLRemoteTranslator translator;
    public KampungHuaweiTranslate(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "KampungHuaweiTranslate"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("translated", Integer.class, String.class));
        signals.add(new SignalInfo("translation_error", Integer.class, String.class));
        return signals;
    }
    private void release() { if (translator != null) { translator.stop(); translator = null; } }
    private void fail(int request, String message) {
        if (active != request) return;
        active = -1; release();
        emitSignal("translation_error", request, message);
    }
    @UsedByGodot public void cancelTranslation() {
        active = -1;
        Activity activity = getActivity();
        if (activity != null) activity.runOnUiThread(this::release);
    }
    @UsedByGodot public void translate(int request, String text, String target, String appId, String apiKey) {
        active = request;
        Activity activity = getActivity();
        if (activity == null) { fail(request, "Translation is unavailable. Please reopen the game."); return; }
        activity.runOnUiThread(() -> {
            if (active != request) return;
            release();
            if (text.isEmpty() || text.length()>4000 || !(target.equals("ms") || target.equals("zh") || target.equals("ta"))) {
                fail(request, "This text or language cannot be translated."); return;
            }
            if (apiKey.isEmpty() || appId.isEmpty()) { fail(request, "Translation is not configured for this build."); return; }
            try {
                MLApplicationSetting settings = new MLApplicationSetting.Factory().setApplicationId(appId).setApiKey(apiKey).create();
                MLApplication.initialize(activity, settings);
                MLApplication.getInstance().setApiKey(apiKey);
                MLTranslateLanguage.getCloudAllLanguages().addOnSuccessListener(languages -> {
                    if (active != request) return;
                    if (!languages.contains("en") || !languages.contains(target)) {
                        fail(request, "The selected language is not available from Huawei translation for this app."); return;
                    }
                    MLRemoteTranslateSetting setting = new MLRemoteTranslateSetting.Factory().setSourceLangCode("en").setTargetLangCode(target).create();
                    translator = MLTranslatorFactory.getInstance().getRemoteTranslator(setting);
                    translator.asyncTranslate(text).addOnSuccessListener(result -> {
                        if (active != request) return;
                        active = -1; release();
                        emitSignal("translated", request, result);
                    }).addOnFailureListener(error -> fail(request, "Translation could not be completed. Check your connection and try again."));
                }).addOnFailureListener(error -> fail(request, "Cannot reach Huawei translation. Check internet access and ML Kit setup."));
            } catch (Exception error) { fail(request, "Translation is unavailable. Check the app's ML Kit configuration."); }
        });
    }
    @Override public void onMainDestroy() { cancelTranslation(); }
}
