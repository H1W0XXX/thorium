// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/private_sync/private_sync_service_factory.h"

#include <memory>

#include "base/no_destructor.h"
#include "chrome/browser/bookmarks/bookmark_model_factory.h"
#include "chrome/browser/history/history_service_factory.h"
#include "chrome/browser/private_sync/private_sync_service.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/browser/profiles/profile_selections.h"
#include "components/keyed_service/core/keyed_service.h"

// static
PrivateSyncService* PrivateSyncServiceFactory::GetForProfile(Profile* profile) {
  return static_cast<PrivateSyncService*>(
      GetInstance()->GetServiceForBrowserContext(profile, true));
}

// static
PrivateSyncServiceFactory* PrivateSyncServiceFactory::GetInstance() {
  static base::NoDestructor<PrivateSyncServiceFactory> instance;
  return instance.get();
}

PrivateSyncServiceFactory::PrivateSyncServiceFactory()
    : ProfileKeyedServiceFactory(
          "PrivateSyncService",
          ProfileSelections::Builder()
              .WithRegular(ProfileSelection::kOriginalOnly)
              .WithGuest(ProfileSelection::kNone)
              .WithSystem(ProfileSelection::kNone)
              .WithAshInternals(ProfileSelection::kNone)
              .Build()) {
  DependsOn(BookmarkModelFactory::GetInstance());
  DependsOn(HistoryServiceFactory::GetInstance());
}

PrivateSyncServiceFactory::~PrivateSyncServiceFactory() = default;

void PrivateSyncServiceFactory::RegisterProfilePrefs(
    user_prefs::PrefRegistrySyncable* registry) {
  PrivateSyncService::RegisterProfilePrefs(registry);
}

std::unique_ptr<KeyedService>
PrivateSyncServiceFactory::BuildServiceInstanceForBrowserContext(
    content::BrowserContext* context) const {
  Profile* profile = Profile::FromBrowserContext(context);
  history::HistoryService* history_service =
      HistoryServiceFactory::GetForProfile(profile,
                                           ServiceAccessType::EXPLICIT_ACCESS);
  bookmarks::BookmarkModel* bookmark_model =
      BookmarkModelFactory::GetForBrowserContext(profile);
  if (!history_service || !bookmark_model) {
    return nullptr;
  }

  return std::make_unique<PrivateSyncService>(profile, history_service,
                                              bookmark_model);
}

bool PrivateSyncServiceFactory::ServiceIsCreatedWithBrowserContext() const {
  return true;
}

bool PrivateSyncServiceFactory::ServiceIsNULLWhileTesting() const {
  return true;
}
