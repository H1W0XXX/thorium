// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.chrome.browser.private_sync;

import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import org.jni_zero.CalledByNative;
import org.jni_zero.JniType;

import org.chromium.base.ContextUtils;
import org.chromium.build.annotations.NullMarked;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyStore;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/** Stores the imported private-sync client configuration behind Android Keystore. */
@NullMarked
public final class PrivateSyncSecureStorage {
    private static final String KEYSTORE_PROVIDER = "AndroidKeyStore";
    private static final String KEY_ALIAS = "thorium_private_sync_config_v1";
    private static final String PREF_FILE = "thorium_private_sync_secure";
    private static final String PREF_ENCRYPTED_CONFIG = "encrypted_client_config";
    private static final String CIPHER_TRANSFORMATION = "AES/GCM/NoPadding";
    private static final byte STORAGE_VERSION = 1;
    private static final int GCM_TAG_BITS = 128;
    private static final int GCM_NONCE_BYTES = 12;
    private static final byte[] ASSOCIATED_DATA =
            "thorium-private-sync-config-v1".getBytes(StandardCharsets.UTF_8);

    private PrivateSyncSecureStorage() {}

    static boolean saveClientConfigJson(String canonicalJson) {
        try {
            Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey());
            cipher.updateAAD(ASSOCIATED_DATA);
            byte[] ciphertext = cipher.doFinal(canonicalJson.getBytes(StandardCharsets.UTF_8));
            byte[] nonce = cipher.getIV();
            if (nonce == null || nonce.length != GCM_NONCE_BYTES) {
                return false;
            }

            ByteBuffer buffer =
                    ByteBuffer.allocate(1 + GCM_NONCE_BYTES + ciphertext.length)
                            .put(STORAGE_VERSION)
                            .put(nonce)
                            .put(ciphertext);
            String encoded =
                    Base64.encodeToString(
                            buffer.array(), Base64.NO_WRAP | Base64.NO_PADDING | Base64.URL_SAFE);
            return preferences().edit().putString(PREF_ENCRYPTED_CONFIG, encoded).commit();
        } catch (GeneralSecurityException | IOException | IllegalArgumentException exception) {
            return false;
        }
    }

    static boolean isConfigured() {
        return !getClientConfigJson().isEmpty();
    }

    @CalledByNative
    public static @JniType("std::string") String getClientConfigJson() {
        String encoded = preferences().getString(PREF_ENCRYPTED_CONFIG, "");
        if (encoded == null || encoded.isEmpty()) {
            return "";
        }
        try {
            byte[] stored =
                    Base64.decode(encoded, Base64.NO_WRAP | Base64.NO_PADDING | Base64.URL_SAFE);
            if (stored.length <= 1 + GCM_NONCE_BYTES || stored[0] != STORAGE_VERSION) {
                return "";
            }
            byte[] nonce = new byte[GCM_NONCE_BYTES];
            byte[] ciphertext = new byte[stored.length - 1 - GCM_NONCE_BYTES];
            System.arraycopy(stored, 1, nonce, 0, nonce.length);
            System.arraycopy(stored, 1 + nonce.length, ciphertext, 0, ciphertext.length);

            Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
            cipher.init(
                    Cipher.DECRYPT_MODE,
                    getOrCreateKey(),
                    new GCMParameterSpec(GCM_TAG_BITS, nonce));
            cipher.updateAAD(ASSOCIATED_DATA);
            return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
        } catch (GeneralSecurityException | IOException | IllegalArgumentException exception) {
            return "";
        }
    }

    private static SharedPreferences preferences() {
        return ContextUtils.getApplicationContext()
                .getSharedPreferences(PREF_FILE, android.content.Context.MODE_PRIVATE);
    }

    private static SecretKey getOrCreateKey() throws GeneralSecurityException, IOException {
        KeyStore keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER);
        keyStore.load(null);
        java.security.Key existing = keyStore.getKey(KEY_ALIAS, null);
        if (existing instanceof SecretKey) {
            return (SecretKey) existing;
        }

        KeyGenerator generator =
                KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER);
        KeyGenParameterSpec specification =
                new KeyGenParameterSpec.Builder(
                                KEY_ALIAS,
                                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        .setRandomizedEncryptionRequired(true)
                        .build();
        generator.init(specification);
        return generator.generateKey();
    }
}
