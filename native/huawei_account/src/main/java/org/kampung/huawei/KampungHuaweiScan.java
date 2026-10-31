package org.kampung.huawei;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.util.Base64;
import com.huawei.hms.hmsscankit.ScanUtil;
import com.huawei.hms.ml.scan.HmsScan;
import com.huawei.hms.ml.scan.HmsScanAnalyzerOptions;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.ByteArrayOutputStream;
import java.util.HashSet;
import java.util.Set;

public class KampungHuaweiScan extends GodotPlugin {
    private static final int SCAN = 43414, CAMERA = 43415;
    private volatile boolean accepting = false;
    private volatile int generation = 0;
    private boolean inFlight = false;
    public KampungHuaweiScan(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "KampungHuaweiScan"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> result = new HashSet<>();
        result.add(new SignalInfo("scan_result", String.class));
        result.add(new SignalInfo("scan_error", String.class));
        result.add(new SignalInfo("qr_image", String.class, String.class));
        return result;
    }
    @UsedByGodot public void scanRoom() {
        final int current = ++generation;
        Activity activity = getActivity();
        if (activity == null) { emitSignal("scan_error", "Please reopen the game and try scanning again."); return; }
        activity.runOnUiThread(() -> {
            if (current != generation) return;
            if (inFlight) { emitSignal("scan_error", "Close the previous scanner first."); return; }
            accepting = true;
            inFlight = true;
            if (activity.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                activity.requestPermissions(new String[]{Manifest.permission.CAMERA}, CAMERA);
            } else launch(activity);
        });
    }
    private void launch(Activity activity) {
        if (!accepting) { inFlight = false; return; }
        try {
            int result = ScanUtil.startScan(activity, SCAN,
                new HmsScanAnalyzerOptions.Creator().setHmsScanTypes(HmsScan.QRCODE_SCAN_TYPE).create());
            if (result != ScanUtil.SUCCESS) fail("Cannot open the camera scanner. Check camera permission or type the room code instead.");
        } catch (Exception error) { fail("QR scanning is unavailable. You can still type the room code."); }
    }
    private void fail(String message) {
        accepting = false; inFlight = false;
        emitSignal("scan_error", message);
    }
    @Override public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] results) {
        if (requestCode != CAMERA) return;
        if (!accepting) { inFlight = false; return; }
        if (results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED && getActivity() != null) launch(getActivity());
        else fail("Camera permission was not granted. Type the room code, or allow camera access in Android Settings.");
    }
    @Override public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != SCAN) return;
        inFlight = false;
        if (!accepting) return;
        accepting = false;
        if (resultCode != Activity.RESULT_OK || data == null) { emitSignal("scan_error", "Scanning cancelled. You can type the code or scan again."); return; }
        HmsScan scan = data.getParcelableExtra(ScanUtil.RESULT);
        if (scan == null || scan.originalValue == null) { emitSignal("scan_error", "No QR code was read. Please try again."); return; }
        emitSignal("scan_result", scan.originalValue);
    }
    @UsedByGodot public void cancelScan() { generation++; accepting = false; }
    @UsedByGodot public void generateRoomQr(String payload) {
        if (!payload.matches("NKR1:[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{5}")) { emitSignal("scan_error", "Invalid room code."); return; }
        try {
            Bitmap bitmap = ScanUtil.buildBitmap(payload, HmsScan.QRCODE_SCAN_TYPE, 512, 512, null);
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes);
            bitmap.recycle();
            emitSignal("qr_image", payload, Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP));
        } catch (Exception error) { emitSignal("scan_error", "The room QR could not be generated. Share the typed code instead."); }
    }
    @Override public void onMainDestroy() { cancelScan(); }
}
