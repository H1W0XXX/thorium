// Copyright 2026 The Chromium Authors and Thorium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_FACTORY_H_
#define CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_FACTORY_H_

#include <memory>

#include "base/no_destructor.h"
#include "chrome/browser/profiles/profile_keyed_service_factory.h"

class PrivateSyncService;
class Profile;

namespace user_prefs {
class PrefRegistrySyncable;
}

class PrivateSyncServiceFactory : public ProfileKeyedServiceFactory {
 public:
  static PrivateSyncService* GetForProfile(Profile* profile);
  static PrivateSyncServiceFactory* GetInstance();

  PrivateSyncServiceFactory(const PrivateSyncServiceFactory&) = delete;
  PrivateSyncServiceFactory& operator=(const PrivateSyncServiceFactory&) =
      delete;

 private:
  friend class base::NoDestructor<PrivateSyncServiceFactory>;

  PrivateSyncServiceFactory();
  ~PrivateSyncServiceFactory() override;

  void RegisterProfilePrefs(
      user_prefs::PrefRegistrySyncable* registry) override;
  std::unique_ptr<KeyedService> BuildServiceInstanceForBrowserContext(
      content::BrowserContext* context) const override;
  bool ServiceIsCreatedWithBrowserContext() const override;
  bool ServiceIsNULLWhileTesting() const override;
};

#endif  // CHROME_BROWSER_PRIVATE_SYNC_PRIVATE_SYNC_SERVICE_FACTORY_H_
