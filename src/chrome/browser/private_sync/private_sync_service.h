// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_H_
#define CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_H_

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "base/android/application_status_listener.h"
#include "base/memory/raw_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/scoped_observation.h"
#include "base/time/time.h"
#include "components/bookmarks/browser/base_bookmark_model_observer.h"
#include "components/history/core/browser/history_service_observer.h"
#include "components/keyed_service/core/keyed_service.h"

class PrefService;
class Profile;
class GURL;

namespace base {
class DictValue;
}

namespace bookmarks {
class BookmarkModel;
class BookmarkNode;
}  // namespace bookmarks

namespace history {
class HistoryService;
}

namespace network {
class SimpleURLLoader;
}

namespace user_prefs {
class PrefRegistrySyncable;
}

// Android-only pull client for the deployment-specific Thorium private sync
// protocol. Phase 1 deliberately imports only history and bookmarks.
class PrivateSyncService : public KeyedService,
                           public history::HistoryServiceObserver,
                           public bookmarks::BaseBookmarkModelObserver {
 public:
  PrivateSyncService(Profile* profile,
                     history::HistoryService* history_service,
                     bookmarks::BookmarkModel* bookmark_model);
  ~PrivateSyncService() override;

  PrivateSyncService(const PrivateSyncService&) = delete;
  PrivateSyncService& operator=(const PrivateSyncService&) = delete;

  static void RegisterProfilePrefs(user_prefs::PrefRegistrySyncable* registry);

  // Requests a pull if the models are ready and no pull is already in flight.
  void PullNow();

  // history::HistoryServiceObserver:
  void OnHistoryServiceLoaded(
      history::HistoryService* history_service) override;
  void HistoryServiceBeingDeleted(
      history::HistoryService* history_service) override;

  // bookmarks::BaseBookmarkModelObserver:
  void BookmarkModelChanged() override;
  void BookmarkModelLoaded(bool ids_reassigned) override;
  void BookmarkModelBeingDeleted() override;

 private:
  struct ClientConfig {
    std::string base_url;
    std::string device_id;
    std::string device_token;
    std::string encryption_key;
  };

  void OnApplicationStateChanged(base::android::ApplicationState state);
  void MaybeStartPull();
  std::optional<ClientConfig> LoadClientConfig() const;
  std::string ConfigFingerprint(const ClientConfig& config) const;
  void OnPullComplete(std::optional<std::string> response_body);
  bool ApplyResponse(const std::string& response_body,
                     const ClientConfig& config,
                     bool* has_more);
  bool ApplyChange(const base::DictValue& change, const ClientConfig& config);
  std::optional<std::string> DecryptPayload(const base::DictValue& change,
                                            const ClientConfig& config) const;
  bool ApplyHistoryChange(const base::DictValue& change,
                          const std::optional<base::DictValue>& payload);
  bool ApplyBookmarkChange(const base::DictValue& change,
                           const std::optional<base::DictValue>& payload);

  const bookmarks::BookmarkNode* GetOrCreateBookmarkRoot();
  const bookmarks::BookmarkNode* FindCurrentBookmarkRoot() const;
  const bookmarks::BookmarkNode* FindBookmarkByMeta(
      const bookmarks::BookmarkNode* root,
      const std::string& key,
      const std::string& value) const;
  const bookmarks::BookmarkNode* FindRemoteBookmark(
      const std::string& remote_id) const;
  const bookmarks::BookmarkNode* FindBookmarkByEntity(
      const std::string& entity_id) const;
  bool IsDescendantOf(const bookmarks::BookmarkNode* node,
                      const bookmarks::BookmarkNode* possible_ancestor) const;
  std::string HistoryMapKey(const std::string& entity_id) const;

  void ResetRequestState();

  const raw_ptr<Profile> profile_;
  raw_ptr<history::HistoryService> history_service_;
  raw_ptr<bookmarks::BookmarkModel> bookmark_model_;
  const raw_ptr<PrefService> prefs_;

  bool history_ready_ = false;
  bool bookmarks_ready_ = false;
  base::TimeTicks last_attempt_;
  std::optional<ClientConfig> active_config_;
  std::unique_ptr<network::SimpleURLLoader> url_loader_;
  std::unique_ptr<base::android::ApplicationStatusListener>
      application_status_listener_;

  base::ScopedObservation<history::HistoryService,
                          history::HistoryServiceObserver>
      history_observation_{this};
  base::ScopedObservation<bookmarks::BookmarkModel,
                          bookmarks::BaseBookmarkModelObserver>
      bookmark_observation_{this};

  base::WeakPtrFactory<PrivateSyncService> weak_factory_{this};
};

#endif  // CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_H_
