// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.chrome.browser.private_sync;

import android.net.Uri;
import android.os.Bundle;
import android.text.InputType;
import android.util.Base64;
import android.view.View;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.widget.Toast;

import androidx.preference.EditTextPreference;
import androidx.preference.Preference;

import org.jni_zero.JniType;
import org.jni_zero.NativeMethods;
import org.json.JSONException;
import org.json.JSONObject;

import org.chromium.base.supplier.MonotonicObservableSupplier;
import org.chromium.base.supplier.ObservableSuppliers;
import org.chromium.base.supplier.SettableMonotonicObservableSupplier;
import org.chromium.build.annotations.NullMarked;
import org.chromium.build.annotations.Nullable;
import org.chromium.chrome.browser.profiles.Profile;
import org.chromium.chrome.browser.settings.ChromeBaseSettingsFragment;
import org.chromium.components.browser_ui.settings.SettingsFragment;
import org.chromium.components.browser_ui.settings.SettingsUtils;

import java.util.regex.Pattern;

/** Settings page for importing a dedicated Android private-sync client configuration. */
@NullMarked
public final class PrivateSyncSettings extends ChromeBaseSettingsFragment {
    private static final String PREF_CLIENT_JSON = "private_sync_client_json";
    private static final String PREF_SYNC_NOW = "private_sync_now";
    private static final String ALLOWED_HOST = "sync.aeutlook.com";
    private static final int MAX_CLIENT_JSON_BYTES = 16 * 1024;
    private static final int MAX_DEVICE_NAME_LENGTH = 128;
    private static final Pattern DEVICE_ID_PATTERN = Pattern.compile("[a-f0-9]{32}");
    private static final Pattern DEVICE_TOKEN_PATTERN = Pattern.compile("ts1_[A-Za-z0-9_-]{43}");
    private static final Pattern ENCRYPTION_KEY_PATTERN = Pattern.compile("[A-Za-z0-9_-]{43}");
    private static final Pattern BASE_PATH_PATTERN = Pattern.compile("/[A-Za-z0-9_-]{24,128}");

    private final SettableMonotonicObservableSupplier<String> mPageTitle =
            ObservableSuppliers.createMonotonic();
    private EditTextPreference mClientJsonPreference;

    @Override
    public void onCreatePreferences(@Nullable Bundle savedInstanceState, @Nullable String rootKey) {
        mPageTitle.set(getString(R.string.private_sync_settings_title));
        SettingsUtils.addPreferencesFromResource(this, R.xml.private_sync_preferences);

        mClientJsonPreference = findPreference(PREF_CLIENT_JSON);
        assert mClientJsonPreference != null;
        mClientJsonPreference.setPersistent(false);
        mClientJsonPreference.setText("");
        mClientJsonPreference.setOnBindEditTextListener(
                editText -> {
                    editText.setInputType(
                            InputType.TYPE_CLASS_TEXT
                                    | InputType.TYPE_TEXT_FLAG_MULTI_LINE
                                    | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
                                    | InputType.TYPE_TEXT_VARIATION_PASSWORD);
                    editText.setImeOptions(EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING);
                    editText.setImportantForAutofill(
                            View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS);
                    editText.setSaveEnabled(false);
                    editText.setMinLines(8);
                    editText.setText("");
                });
        mClientJsonPreference.setOnPreferenceChangeListener(
                (preference, newValue) -> {
                    String canonicalJson = validateAndCanonicalize(String.valueOf(newValue));
                    if (canonicalJson.isEmpty()) {
                        showToast(R.string.private_sync_invalid_config);
                        return false;
                    }
                    if (!PrivateSyncSecureStorage.saveClientConfigJson(canonicalJson)) {
                        showToast(R.string.private_sync_keystore_error);
                        return false;
                    }
                    updateSummary();
                    PrivateSyncSettingsJni.get().syncNow(getProfile());
                    showToast(R.string.private_sync_saved);
                    // Never let EditTextPreference persist the plaintext value.
                    return false;
                });

        Preference syncNow = findPreference(PREF_SYNC_NOW);
        assert syncNow != null;
        syncNow.setOnPreferenceClickListener(
                preference -> {
                    if (!PrivateSyncSecureStorage.isConfigured()) {
                        showToast(R.string.private_sync_not_configured);
                        return true;
                    }
                    PrivateSyncSettingsJni.get().syncNow(getProfile());
                    showToast(R.string.private_sync_requested);
                    return true;
                });
        updateSummary();
    }

    @Override
    public void onResume() {
        super.onResume();
        requireActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
    }

    @Override
    public void onPause() {
        requireActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
        super.onPause();
    }

    @Override
    public MonotonicObservableSupplier<String> getPageTitle() {
        return mPageTitle;
    }

    @Override
    public @SettingsFragment.AnimationType int getAnimationType() {
        return SettingsFragment.AnimationType.PROPERTY;
    }

    private void updateSummary() {
        mClientJsonPreference.setSummary(
                PrivateSyncSecureStorage.isConfigured()
                        ? R.string.private_sync_configured_summary
                        : R.string.private_sync_not_configured_summary);
    }

    private String validateAndCanonicalize(String rawJson) {
        if (rawJson.length() > MAX_CLIENT_JSON_BYTES) {
            return "";
        }
        try {
            JSONObject source = new JSONObject(rawJson);
            if (source.length() != 6) {
                return "";
            }
            String baseUrl = normalizeBaseUrl(source.getString("base_url"));
            String deviceId = source.getString("device_id").trim();
            String deviceName = source.getString("device_name").trim();
            String deviceToken = source.getString("device_token").trim();
            String encryptionKey = source.getString("encryption_key").trim();
            int version = source.getInt("version");

            if (version != 1
                    || !DEVICE_ID_PATTERN.matcher(deviceId).matches()
                    || deviceName.isEmpty()
                    || deviceName.length() > MAX_DEVICE_NAME_LENGTH
                    || containsControlCharacter(deviceName)
                    || !DEVICE_TOKEN_PATTERN.matcher(deviceToken).matches()
                    || !ENCRYPTION_KEY_PATTERN.matcher(encryptionKey).matches()) {
                return "";
            }
            byte[] key =
                    Base64.decode(
                            encryptionKey, Base64.NO_WRAP | Base64.NO_PADDING | Base64.URL_SAFE);
            String canonicalKey =
                    Base64.encodeToString(
                            key, Base64.NO_WRAP | Base64.NO_PADDING | Base64.URL_SAFE);
            if (key.length != 32 || !canonicalKey.equals(encryptionKey)) {
                return "";
            }

            JSONObject canonical = new JSONObject();
            canonical.put("version", 1);
            canonical.put("base_url", baseUrl);
            canonical.put("device_id", deviceId);
            canonical.put("device_name", deviceName);
            canonical.put("device_token", deviceToken);
            canonical.put("encryption_key", encryptionKey);
            return canonical.toString();
        } catch (JSONException | IllegalArgumentException exception) {
            return "";
        }
    }

    private String normalizeBaseUrl(String rawValue) {
        String raw = rawValue.trim();
        if (raw.length() > 512) {
            throw new IllegalArgumentException();
        }
        while (raw.endsWith("/")) {
            raw = raw.substring(0, raw.length() - 1);
        }
        Uri uri = Uri.parse(raw);
        String path = uri.getEncodedPath();
        if (!"https".equals(uri.getScheme())
                || !ALLOWED_HOST.equals(uri.getHost())
                || uri.getPort() != -1
                || uri.getUserInfo() != null
                || uri.getQuery() != null
                || uri.getFragment() != null
                || path == null
                || !BASE_PATH_PATTERN.matcher(path).matches()) {
            throw new IllegalArgumentException();
        }
        return raw;
    }

    private static boolean containsControlCharacter(String value) {
        for (int i = 0; i < value.length(); ++i) {
            if (Character.isISOControl(value.charAt(i))) {
                return true;
            }
        }
        return false;
    }

    private void showToast(int messageId) {
        Toast.makeText(requireContext(), messageId, Toast.LENGTH_SHORT).show();
    }

    @NativeMethods
    interface Natives {
        void syncNow(@JniType("Profile*") Profile profile);
    }
}
