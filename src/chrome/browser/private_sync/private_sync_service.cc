// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/private_sync/private_sync_service.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/base64url.h"
#include "base/functional/bind.h"
#include "base/json/json_reader.h"
#include "base/location.h"
#include "base/strings/strcat.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "base/task/sequenced_task_runner.h"
#include "base/time/time.h"
#include "chrome/browser/private_sync/jni_headers/PrivateSyncSecureStorage_jni.h"
#include "chrome/browser/private_sync/jni_headers/PrivateSyncSettings_jni.h"
#include "chrome/browser/private_sync/private_sync_service_factory.h"
#include "chrome/browser/profiles/profile.h"
#include "components/bookmarks/browser/bookmark_model.h"
#include "components/bookmarks/browser/bookmark_node.h"
#include "components/bookmarks/common/bookmark_metrics.h"
#include "components/history/core/browser/history_service.h"
#include "components/history/core/browser/history_types.h"
#include "components/pref_registry/pref_registry_syncable.h"
#include "components/prefs/pref_service.h"
#include "components/prefs/scoped_user_pref_update.h"
#include "crypto/aead.h"
#include "crypto/sha2.h"
#include "net/base/load_flags.h"
#include "net/base/net_errors.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_status_code.h"
#include "net/traffic_annotation/network_traffic_annotation.h"
#include "services/network/public/cpp/resource_request.h"
#include "services/network/public/cpp/shared_url_loader_factory.h"
#include "services/network/public/cpp/simple_url_loader.h"
#include "services/network/public/mojom/fetch_api.mojom.h"
#include "services/network/public/mojom/url_loader.mojom-shared.h"
#include "services/network/public/mojom/url_response_head.mojom.h"
#include "url/gurl.h"

namespace {

constexpr char kCursorPref[] = "thorium.private_sync.cursor";
constexpr char kAppliedSequencePref[] = "thorium.private_sync.applied_sequence";
constexpr char kConfigFingerprintPref[] =
    "thorium.private_sync.config_fingerprint";
constexpr char kHistoryEntityMapPref[] =
    "thorium.private_sync.history_entity_map";
constexpr char kBookmarkRootMetaKey[] = "thorium_private_sync_root";
constexpr char kBookmarkRemoteIdMetaKey[] = "thorium_private_sync_remote_id";
constexpr char kBookmarkEntityIdMetaKey[] = "thorium_private_sync_entity_id";
constexpr char kAllowedHost[] = "sync.aeutlook.com";
constexpr size_t kEncryptionKeySize = 32;
constexpr size_t kNonceSize = 12;
constexpr size_t kMaxClientConfigBytes = 16 * 1024;
// The server caps encoded entity data at 8 MiB. Leave room for the JSON
// envelope and field names so every valid page can be downloaded intact.
constexpr size_t kMaxResponseBytes = 9 * 1024 * 1024;
constexpr base::TimeDelta kMinimumPullInterval = base::Seconds(5);
constexpr double kMaxSafeJsonInteger = 9007199254740991.0;

const net::NetworkTrafficAnnotationTag kTrafficAnnotation =
    net::DefineNetworkTrafficAnnotation("thorium_private_sync_pull", R"(
      semantics {
        sender: "Thorium Private Sync"
        description:
          "Pulls end-to-end encrypted history and bookmark changes from the "
          "private sync server configured by the user."
        trigger:
          "At browser profile startup, when Chrome returns to the foreground, "
          "or when the user taps Sync now."
        data:
          "A per-device bearer token and device ID are sent as headers. The "
          "response contains client-side encrypted sync entities."
        destination: OTHER
        destination_other: "User-configured private sync server"
      }
      policy {
        cookies_allowed: NO
        setting:
          "This is disabled until the user imports a private sync client "
          "configuration in Thorium settings."
        policy_exception_justification:
          "This downstream Thorium feature is not controlled by enterprise "
          "policy."
      })");

std::optional<int64_t> JsonInt64(const base::DictValue& value,
                                 std::string_view key) {
  std::optional<double> number = value.FindDouble(key);
  if (!number || !std::isfinite(*number) || *number < 0 ||
      *number > kMaxSafeJsonInteger || std::floor(*number) != *number) {
    return std::nullopt;
  }
  return static_cast<int64_t>(*number);
}

base::Time TimeFromMilliseconds(const base::DictValue& value,
                                std::string_view key) {
  std::optional<int64_t> milliseconds = JsonInt64(value, key);
  if (!milliseconds || *milliseconds == 0) {
    return base::Time::Now();
  }
  return base::Time::FromMillisecondsSinceUnixEpoch(*milliseconds);
}

bool IsSupportedWebUrl(const GURL& url) {
  return url.is_valid() && (url.SchemeIs("https") || url.SchemeIs("http"));
}

bool IsLowerHexDeviceId(std::string_view device_id) {
  if (device_id.size() != 32) {
    return false;
  }
  return std::ranges::all_of(device_id, [](char character) {
    return (character >= '0' && character <= '9') ||
           (character >= 'a' && character <= 'f');
  });
}

bool IsBase64UrlCharacter(char character) {
  return (character >= 'A' && character <= 'Z') ||
         (character >= 'a' && character <= 'z') ||
         (character >= '0' && character <= '9') || character == '_' ||
         character == '-';
}

bool IsValidDeviceToken(std::string_view token) {
  return token.size() == 47 && token.starts_with("ts1_") &&
         std::ranges::all_of(token.substr(4), IsBase64UrlCharacter);
}

bool IsValidBasePath(std::string_view path) {
  return path.size() >= 25 && path.size() <= 129 && path.front() == '/' &&
         std::ranges::all_of(path.substr(1), IsBase64UrlCharacter);
}

}  // namespace

PrivateSyncService::PrivateSyncService(Profile* profile,
                                       history::HistoryService* history_service,
                                       bookmarks::BookmarkModel* bookmark_model)
    : profile_(profile),
      history_service_(history_service),
      bookmark_model_(bookmark_model),
      prefs_(profile->GetPrefs()),
      history_ready_(history_service->BackendLoaded()),
      bookmarks_ready_(bookmark_model->loaded()) {
  application_status_listener_ = base::android::ApplicationStatusListener::New(
      base::BindRepeating(&PrivateSyncService::OnApplicationStateChanged,
                          weak_factory_.GetWeakPtr()));
  history_observation_.Observe(history_service_);
  bookmark_observation_.Observe(bookmark_model_);
  MaybeStartPull();
}

PrivateSyncService::~PrivateSyncService() = default;

// static
void PrivateSyncService::RegisterProfilePrefs(
    user_prefs::PrefRegistrySyncable* registry) {
  registry->RegisterInt64Pref(kCursorPref, 0);
  registry->RegisterInt64Pref(kAppliedSequencePref, 0);
  registry->RegisterStringPref(kConfigFingerprintPref, std::string());
  registry->RegisterDictionaryPref(kHistoryEntityMapPref);
}

void PrivateSyncService::PullNow() {
  MaybeStartPull();
}

void PrivateSyncService::OnHistoryServiceLoaded(
    history::HistoryService* history_service) {
  if (history_service != history_service_) {
    return;
  }
  history_ready_ = true;
  MaybeStartPull();
}

void PrivateSyncService::HistoryServiceBeingDeleted(
    history::HistoryService* history_service) {
  if (history_service == history_service_) {
    history_observation_.Reset();
    history_service_ = nullptr;
    history_ready_ = false;
    ResetRequestState();
  }
}

void PrivateSyncService::BookmarkModelChanged() {}

void PrivateSyncService::BookmarkModelLoaded(bool ids_reassigned) {
  bookmarks_ready_ = true;
  MaybeStartPull();
}

void PrivateSyncService::BookmarkModelBeingDeleted() {
  bookmark_observation_.Reset();
  bookmark_model_ = nullptr;
  bookmarks_ready_ = false;
  ResetRequestState();
}

void PrivateSyncService::OnApplicationStateChanged(
    base::android::ApplicationState state) {
  if (state == base::android::APPLICATION_STATE_HAS_RUNNING_ACTIVITIES) {
    MaybeStartPull();
  }
}

void PrivateSyncService::MaybeStartPull() {
  if (!history_ready_ || !bookmarks_ready_ || !history_service_ ||
      !bookmark_model_ || url_loader_) {
    return;
  }

  std::optional<ClientConfig> config = LoadClientConfig();
  if (!config) {
    return;
  }

  const std::string fingerprint = ConfigFingerprint(*config);
  if (prefs_->GetString(kConfigFingerprintPref) != fingerprint) {
    // A different server path, device, or account key is a different cursor
    // namespace. Keep old imported bookmarks in their fingerprinted folder,
    // but never reuse an unrelated server cursor.
    prefs_->SetInt64(kCursorPref, 0);
    prefs_->SetInt64(kAppliedSequencePref, 0);
    prefs_->SetString(kConfigFingerprintPref, fingerprint);
    last_attempt_ = base::TimeTicks();
  }

  const base::TimeTicks now = base::TimeTicks::Now();
  if (!last_attempt_.is_null() && now - last_attempt_ < kMinimumPullInterval) {
    return;
  }

  const int64_t cursor = prefs_->GetInt64(kCursorPref);
  GURL request_url(base::StrCat({config->base_url, "/v1/pull?cursor=",
                                 base::NumberToString(cursor), "&limit=500"}));
  if (!request_url.is_valid() || !request_url.SchemeIs("https") ||
      request_url.host() != kAllowedHost) {
    return;
  }

  auto request = std::make_unique<network::ResourceRequest>();
  request->url = request_url;
  request->method = "GET";
  request->credentials_mode = network::mojom::CredentialsMode::kOmit;
  request->redirect_mode = network::mojom::RedirectMode::kError;
  request->load_flags = net::LOAD_DISABLE_CACHE;
  request->do_not_prompt_for_login = true;
  request->headers.SetHeader(net::HttpRequestHeaders::kAuthorization,
                             base::StrCat({"Bearer ", config->device_token}));
  request->headers.SetHeader("X-Thorium-Device-ID", config->device_id);

  active_config_ = std::move(config);
  last_attempt_ = now;
  url_loader_ =
      network::SimpleURLLoader::Create(std::move(request), kTrafficAnnotation);
  url_loader_->SetTimeoutDuration(base::Seconds(30));
  url_loader_->DownloadToString(
      profile_->GetURLLoaderFactory().get(),
      base::BindOnce(&PrivateSyncService::OnPullComplete,
                     weak_factory_.GetWeakPtr()),
      kMaxResponseBytes);
}

std::optional<PrivateSyncService::ClientConfig>
PrivateSyncService::LoadClientConfig() const {
  JNIEnv* env = base::android::AttachCurrentThread();
  std::string json = Java_PrivateSyncSecureStorage_getClientConfigJson(env);
  if (json.size() > kMaxClientConfigBytes) {
    return std::nullopt;
  }
  std::optional<base::DictValue> value =
      base::JSONReader::ReadDict(json, base::JSON_PARSE_RFC);
  if (!value || value->size() != 6) {
    return std::nullopt;
  }

  const std::string* base_url = value->FindString("base_url");
  const std::string* device_id = value->FindString("device_id");
  const std::string* device_name = value->FindString("device_name");
  const std::string* device_token = value->FindString("device_token");
  const std::string* encryption_key = value->FindString("encryption_key");
  if (value->FindInt("version").value_or(0) != 1 || !base_url || !device_id ||
      !device_name || device_name->empty() || device_name->size() > 128 ||
      !device_token || !encryption_key || !IsLowerHexDeviceId(*device_id) ||
      !IsValidDeviceToken(*device_token) || encryption_key->size() != 43 ||
      !std::ranges::all_of(*encryption_key, IsBase64UrlCharacter)) {
    return std::nullopt;
  }

  GURL parsed_base_url(*base_url);
  if (!parsed_base_url.is_valid() || !parsed_base_url.SchemeIs("https") ||
      parsed_base_url.host() != kAllowedHost || parsed_base_url.has_query() ||
      parsed_base_url.has_ref() || parsed_base_url.has_username() ||
      parsed_base_url.has_password() || parsed_base_url.has_port() ||
      !IsValidBasePath(parsed_base_url.path())) {
    return std::nullopt;
  }

  std::optional<std::vector<uint8_t>> decoded_key = base::Base64UrlDecode(
      *encryption_key, base::Base64UrlDecodePolicy::DISALLOW_PADDING);
  if (!decoded_key || decoded_key->size() != kEncryptionKeySize) {
    return std::nullopt;
  }
  std::string canonical_key;
  base::Base64UrlEncode(*decoded_key, base::Base64UrlEncodePolicy::OMIT_PADDING,
                        &canonical_key);
  if (canonical_key != *encryption_key) {
    return std::nullopt;
  }

  std::string normalized_base_url = parsed_base_url.spec();
  while (normalized_base_url.ends_with('/')) {
    normalized_base_url.pop_back();
  }
  return ClientConfig{std::move(normalized_base_url), *device_id, *device_token,
                      *encryption_key};
}

std::string PrivateSyncService::ConfigFingerprint(
    const ClientConfig& config) const {
  return base::HexEncode(crypto::SHA256HashString(base::StrCat(
      {config.base_url, "\n", config.device_id, "\n", config.encryption_key})));
}

void PrivateSyncService::OnPullComplete(
    std::optional<std::string> response_body) {
  if (!url_loader_ || !active_config_) {
    ResetRequestState();
    return;
  }

  const network::mojom::URLResponseHead* response = url_loader_->ResponseInfo();
  const bool request_ok = response_body && url_loader_->NetError() == net::OK &&
                          response && response->headers &&
                          response->headers->response_code() == net::HTTP_OK;

  bool has_more = false;
  const bool applied =
      request_ok && ApplyResponse(*response_body, *active_config_, &has_more);
  ResetRequestState();

  if (applied && has_more) {
    // Pagination is one logical pull. Do not let the foreground/manual
    // request throttle strand a response that explicitly says more is ready.
    last_attempt_ = base::TimeTicks();
    base::SequencedTaskRunner::GetCurrentDefault()->PostTask(
        FROM_HERE, base::BindOnce(&PrivateSyncService::MaybeStartPull,
                                  weak_factory_.GetWeakPtr()));
  }
}

bool PrivateSyncService::ApplyResponse(const std::string& response_body,
                                       const ClientConfig& config,
                                       bool* has_more) {
  std::optional<base::DictValue> root =
      base::JSONReader::ReadDict(response_body, base::JSON_PARSE_RFC);
  if (!root) {
    return false;
  }
  const base::ListValue* changes = root->FindList("changes");
  std::optional<int64_t> next_cursor = JsonInt64(*root, "next_cursor");
  std::optional<bool> response_has_more = root->FindBool("has_more");
  const int64_t current_cursor = prefs_->GetInt64(kCursorPref);
  if (!changes || !next_cursor || !response_has_more ||
      *next_cursor < current_cursor || changes->size() > 500 ||
      (*response_has_more && *next_cursor == current_cursor)) {
    return false;
  }

  int64_t applied_through =
      std::max(current_cursor, prefs_->GetInt64(kAppliedSequencePref));
  if (*next_cursor < applied_through) {
    return false;
  }
  int64_t previous_sequence = current_cursor;
  for (const base::Value& value : *changes) {
    const base::DictValue* change = value.GetIfDict();
    if (!change) {
      return false;
    }
    std::optional<int64_t> sequence = JsonInt64(*change, "sequence");
    const std::string* source_device_id =
        change->FindString("source_device_id");
    if (!sequence || *sequence <= previous_sequence ||
        *sequence > *next_cursor || !source_device_id) {
      return false;
    }
    previous_sequence = *sequence;

    // A prior attempt may have applied the beginning of this same response
    // before a later entity failed validation. The progress marker makes
    // retries resume at that exact sequence while the public cursor remains
    // unchanged until the entire response succeeds.
    if (*sequence <= applied_through) {
      continue;
    }
    if (*source_device_id != config.device_id &&
        !ApplyChange(*change, config)) {
      return false;
    }
    applied_through = *sequence;
    prefs_->SetInt64(kAppliedSequencePref, applied_through);
  }

  if ((!changes->empty() && previous_sequence != *next_cursor) ||
      (changes->empty() && *next_cursor != current_cursor)) {
    return false;
  }

  // Advancing the cursor is deliberately the final operation. Reapplying a
  // partially completed batch resumes from kAppliedSequencePref.
  prefs_->SetInt64(kCursorPref, *next_cursor);
  prefs_->SetInt64(kAppliedSequencePref, *next_cursor);
  *has_more = *response_has_more;
  return true;
}

bool PrivateSyncService::ApplyChange(const base::DictValue& change,
                                     const ClientConfig& config) {
  const std::string* kind = change.FindString("kind");
  const std::string* operation = change.FindString("operation");
  const std::string* entity_id = change.FindString("entity_id");
  if (!kind || !operation || !entity_id || entity_id->empty() ||
      (*operation != "upsert" && *operation != "delete")) {
    return false;
  }

  // Phase 1 intentionally ignores supported future entity kinds while still
  // consuming their cursor positions.
  if (*kind != "history" && *kind != "bookmark") {
    return true;
  }

  std::optional<std::string> plaintext = DecryptPayload(change, config);
  if (!plaintext) {
    // Delete is destructive, so an unauthenticated tombstone is safely
    // ignored and consumed. This prevents a compromised transport or server
    // from turning an invalid record into local deletion.
    return *operation == "delete";
  }
  std::optional<base::DictValue> payload =
      base::JSONReader::ReadDict(*plaintext, base::JSON_PARSE_RFC);
  if (!payload) {
    return *operation == "delete";
  }

  if (*kind == "history") {
    return ApplyHistoryChange(change, payload);
  }
  return ApplyBookmarkChange(change, payload);
}

std::optional<std::string> PrivateSyncService::DecryptPayload(
    const base::DictValue& change,
    const ClientConfig& config) const {
  const std::string* kind = change.FindString("kind");
  const std::string* entity_id = change.FindString("entity_id");
  const std::string* operation = change.FindString("operation");
  const std::string* nonce_b64 = change.FindString("nonce");
  const std::string* ciphertext_b64 = change.FindString("ciphertext");
  if (!kind || !entity_id || !operation || !nonce_b64 || !ciphertext_b64) {
    return std::nullopt;
  }

  std::optional<std::vector<uint8_t>> key = base::Base64UrlDecode(
      config.encryption_key, base::Base64UrlDecodePolicy::DISALLOW_PADDING);
  std::optional<std::vector<uint8_t>> nonce = base::Base64UrlDecode(
      *nonce_b64, base::Base64UrlDecodePolicy::DISALLOW_PADDING);
  std::optional<std::vector<uint8_t>> ciphertext = base::Base64UrlDecode(
      *ciphertext_b64, base::Base64UrlDecodePolicy::DISALLOW_PADDING);
  if (!key || key->size() != kEncryptionKeySize || !nonce ||
      nonce->size() != kNonceSize || !ciphertext || ciphertext->empty()) {
    return std::nullopt;
  }

  const std::string key_string(reinterpret_cast<const char*>(key->data()),
                               key->size());
  const std::string nonce_string(reinterpret_cast<const char*>(nonce->data()),
                                 nonce->size());
  const std::string ciphertext_string(
      reinterpret_cast<const char*>(ciphertext->data()), ciphertext->size());
  const std::string aad = base::StrCat(
      {"thorium-sync-v1\n", *kind, "\n", *entity_id, "\n", *operation});

  crypto::Aead aead(crypto::Aead::AES_256_GCM);
  aead.Init(&key_string);
  std::string plaintext;
  if (!aead.Open(ciphertext_string, nonce_string, aad, &plaintext)) {
    return std::nullopt;
  }
  return plaintext;
}

bool PrivateSyncService::ApplyHistoryChange(
    const base::DictValue& change,
    const std::optional<base::DictValue>& payload) {
  const std::string& operation = *change.FindString("operation");
  const std::string& entity_id = *change.FindString("entity_id");
  const std::string map_key = HistoryMapKey(entity_id);
  if (operation == "delete") {
    const std::string* payload_kind =
        payload ? payload->FindString("kind") : nullptr;
    const std::string* payload_url =
        payload ? payload->FindString("url") : nullptr;
    if (!payload || payload->FindInt("version").value_or(0) != 1 ||
        !payload_kind || *payload_kind != "history" || !payload_url) {
      return true;
    }
    const base::DictValue& entity_map = prefs_->GetDict(kHistoryEntityMapPref);
    const std::string* mapped_url = entity_map.FindString(map_key);
    if (!mapped_url || *mapped_url != *payload_url) {
      return true;
    }
    GURL url(*mapped_url);
    if (!IsSupportedWebUrl(url)) {
      return true;
    }
    history_service_->DeleteURLs({url});
    ScopedDictPrefUpdate update(prefs_, kHistoryEntityMapPref);
    update->Remove(map_key);
    return true;
  }

  const std::string* payload_kind =
      payload ? payload->FindString("kind") : nullptr;
  if (!payload || payload->FindInt("version").value_or(0) != 1 ||
      !payload_kind || *payload_kind != "history") {
    return false;
  }
  const std::string* url_string = payload->FindString("url");
  const std::string* title = payload->FindString("title");
  if (!url_string || !title) {
    return false;
  }
  GURL url(*url_string);
  if (!IsSupportedWebUrl(url)) {
    return false;
  }

  const base::Time visit_time =
      TimeFromMilliseconds(*payload, "last_visit_time_ms");
  history_service_->AddPage(url, visit_time, history::SOURCE_SYNCED);
  history_service_->SetPageTitle(url, base::UTF8ToUTF16(*title));
  ScopedDictPrefUpdate update(prefs_, kHistoryEntityMapPref);
  update->Set(map_key, url.spec());
  return true;
}

bool PrivateSyncService::ApplyBookmarkChange(
    const base::DictValue& change,
    const std::optional<base::DictValue>& payload) {
  const std::string& operation = *change.FindString("operation");
  const std::string& entity_id = *change.FindString("entity_id");
  if (operation == "delete") {
    const std::string* payload_kind =
        payload ? payload->FindString("kind") : nullptr;
    const std::string* remote_id =
        payload ? payload->FindString("id") : nullptr;
    if (!payload || payload->FindInt("version").value_or(0) != 1 ||
        !payload_kind || *payload_kind != "bookmark" || !remote_id ||
        remote_id->empty()) {
      return true;
    }
    const bookmarks::BookmarkNode* existing = FindBookmarkByEntity(entity_id);
    std::string existing_remote_id;
    if (existing &&
        existing->GetMetaInfo(kBookmarkRemoteIdMetaKey, &existing_remote_id) &&
        existing_remote_id == *remote_id &&
        !bookmark_model_->is_permanent_node(existing)) {
      bookmark_model_->Remove(
          existing, bookmarks::metrics::BookmarkEditSource::kOther, FROM_HERE);
    }
    return true;
  }

  const std::string* payload_kind =
      payload ? payload->FindString("kind") : nullptr;
  if (!payload || payload->FindInt("version").value_or(0) != 1 ||
      !payload_kind || *payload_kind != "bookmark") {
    return false;
  }
  const std::string* remote_id = payload->FindString("id");
  const std::string* parent_id = payload->FindString("parent_id");
  const std::string* title = payload->FindString("title");
  const std::string* url_string = payload->FindString("url");
  const std::string* node_type = payload->FindString("node_type");
  std::optional<int> requested_index = payload->FindInt("index");
  if (!remote_id || remote_id->empty() || !parent_id || !title || !url_string ||
      !node_type || !requested_index || *requested_index < 0 ||
      (*node_type != "bookmark" && *node_type != "folder")) {
    return false;
  }

  GURL url(*url_string);
  if (*node_type == "bookmark" && !IsSupportedWebUrl(url)) {
    return false;
  }

  const bookmarks::BookmarkNode* sync_root = GetOrCreateBookmarkRoot();
  if (!sync_root) {
    return false;
  }
  const bookmarks::BookmarkNode* desired_parent =
      parent_id->empty() || *parent_id == "0" ? sync_root
                                              : FindRemoteBookmark(*parent_id);
  if (!desired_parent || !desired_parent->is_folder()) {
    desired_parent = sync_root;
  }

  const bookmarks::BookmarkNode* existing = FindBookmarkByEntity(entity_id);
  if (existing && existing->is_folder() != (*node_type == "folder")) {
    bookmark_model_->Remove(
        existing, bookmarks::metrics::BookmarkEditSource::kOther, FROM_HERE);
    existing = nullptr;
  }

  const size_t requested_position = static_cast<size_t>(*requested_index);
  size_t desired_index =
      std::min(requested_position, desired_parent->children().size());
  const base::Time date_added = TimeFromMilliseconds(*payload, "date_added_ms");
  bookmarks::BookmarkNode::MetaInfoMap meta_info{
      {kBookmarkRemoteIdMetaKey, *remote_id},
      {kBookmarkEntityIdMetaKey, entity_id},
  };

  if (!existing) {
    if (*node_type == "folder") {
      existing = bookmark_model_->AddFolder(desired_parent, desired_index,
                                            base::UTF8ToUTF16(*title),
                                            &meta_info, date_added);
    } else {
      existing = bookmark_model_->AddURL(
          desired_parent, desired_index, base::UTF8ToUTF16(*title), url,
          &meta_info, date_added, std::nullopt, false);
    }
    return existing != nullptr;
  }

  bookmark_model_->SetTitle(existing, base::UTF8ToUTF16(*title),
                            bookmarks::metrics::BookmarkEditSource::kOther);
  if (existing->is_url() && existing->url() != url) {
    bookmark_model_->SetURL(existing, url,
                            bookmarks::metrics::BookmarkEditSource::kOther);
  }
  bookmark_model_->SetDateAdded(existing, date_added);
  bookmark_model_->SetNodeMetaInfoMap(existing, meta_info);

  if (desired_parent != existing->parent()) {
    if (!IsDescendantOf(desired_parent, existing)) {
      bookmark_model_->Move(existing, desired_parent, desired_index);
    }
  } else {
    std::optional<size_t> current_index = desired_parent->GetIndexOf(existing);
    const size_t final_index =
        std::min(requested_position, desired_parent->children().size() - 1);
    if (current_index && *current_index != final_index) {
      size_t insertion_index = final_index;
      if (*current_index < final_index) {
        ++insertion_index;
      }
      bookmark_model_->Move(existing, desired_parent, insertion_index);
    }
  }
  return true;
}

const bookmarks::BookmarkNode* PrivateSyncService::GetOrCreateBookmarkRoot() {
  if (!bookmark_model_ || !bookmark_model_->loaded() ||
      !bookmark_model_->mobile_node()) {
    return nullptr;
  }
  if (const bookmarks::BookmarkNode* existing = FindCurrentBookmarkRoot()) {
    return existing;
  }

  const std::string& fingerprint = prefs_->GetString(kConfigFingerprintPref);
  if (fingerprint.empty()) {
    return nullptr;
  }
  const bookmarks::BookmarkNode* mobile = bookmark_model_->mobile_node();
  bookmarks::BookmarkNode::MetaInfoMap meta_info{
      {kBookmarkRootMetaKey, fingerprint},
  };
  return bookmark_model_->AddFolder(mobile, mobile->children().size(),
                                    u"Private Sync", &meta_info,
                                    base::Time::Now());
}

const bookmarks::BookmarkNode* PrivateSyncService::FindCurrentBookmarkRoot()
    const {
  if (!bookmark_model_ || !bookmark_model_->mobile_node()) {
    return nullptr;
  }
  const std::string& fingerprint = prefs_->GetString(kConfigFingerprintPref);
  if (fingerprint.empty()) {
    return nullptr;
  }
  for (const auto& child : bookmark_model_->mobile_node()->children()) {
    std::string current_value;
    if (child->is_folder() &&
        child->GetMetaInfo(kBookmarkRootMetaKey, &current_value) &&
        current_value == fingerprint) {
      return child.get();
    }
  }
  return nullptr;
}

const bookmarks::BookmarkNode* PrivateSyncService::FindBookmarkByMeta(
    const bookmarks::BookmarkNode* root,
    const std::string& key,
    const std::string& value) const {
  if (!root) {
    return nullptr;
  }
  std::string current_value;
  if (root->GetMetaInfo(key, &current_value) && current_value == value) {
    return root;
  }
  for (const auto& child : root->children()) {
    if (const bookmarks::BookmarkNode* found =
            FindBookmarkByMeta(child.get(), key, value)) {
      return found;
    }
  }
  return nullptr;
}

const bookmarks::BookmarkNode* PrivateSyncService::FindRemoteBookmark(
    const std::string& remote_id) const {
  const bookmarks::BookmarkNode* root = FindCurrentBookmarkRoot();
  if (!root) {
    return nullptr;
  }
  return FindBookmarkByMeta(root, kBookmarkRemoteIdMetaKey, remote_id);
}

const bookmarks::BookmarkNode* PrivateSyncService::FindBookmarkByEntity(
    const std::string& entity_id) const {
  const bookmarks::BookmarkNode* root = FindCurrentBookmarkRoot();
  if (!root) {
    return nullptr;
  }
  return FindBookmarkByMeta(root, kBookmarkEntityIdMetaKey, entity_id);
}

bool PrivateSyncService::IsDescendantOf(
    const bookmarks::BookmarkNode* node,
    const bookmarks::BookmarkNode* possible_ancestor) const {
  for (const bookmarks::BookmarkNode* current = node; current;
       current = current->parent()) {
    if (current == possible_ancestor) {
      return true;
    }
  }
  return false;
}

std::string PrivateSyncService::HistoryMapKey(
    const std::string& entity_id) const {
  return base::StrCat(
      {prefs_->GetString(kConfigFingerprintPref), ":", entity_id});
}

void PrivateSyncService::ResetRequestState() {
  url_loader_.reset();
  active_config_.reset();
}

static void JNI_PrivateSyncSettings_SyncNow(JNIEnv* env, Profile* profile) {
  if (profile) {
    if (PrivateSyncService* service =
            PrivateSyncServiceFactory::GetForProfile(profile)) {
      service->PullNow();
    }
  }
}

DEFINE_JNI(PrivateSyncSettings)
