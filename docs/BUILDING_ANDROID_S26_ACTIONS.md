# Samsung Galaxy S26+ GitHub Actions build

The `Build Android S26+ Oryon APK` workflow creates a signed ARM64 Thorium APK
for the Samsung Galaxy S26+ SM-S9470. It targets LLVM's `oryon-1` CPU model,
which is the newest compatible Oryon model exposed by the Chromium 150 bundled
toolchain for the phone's newer Oryon V3 CPU.

## Remote builder

A full Chromium build does not fit reliably within a standard GitHub-hosted
runner's disk, memory, and time limits. Register a Linux x64 cloud machine as a
GitHub self-hosted runner with these labels:

```text
self-hosted
linux
x64
```

Use Ubuntu 22.04 or newer, Python 3.11 or newer, at least 32 GB RAM, and at
least 150 GiB free disk space. A 250 GB disk and 16 or more CPU cores are
recommended. The workflow keeps Chromium and depot_tools beside the Actions
workspace so later builds can reuse the downloads.

The runner account must have passwordless `sudo` because Chromium's supported
dependency installer runs during bootstrap. Keep this runner dedicated to this
repository: repository Actions execute shell commands on it.

## Repository secrets

Configure these four Actions repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

`ANDROID_KEY_ALIAS` must be the alias stored inside the uploaded keystore. No
keystore or password is committed to the repository. The temporary keystore is
created with owner-only permissions and removed before the signing step exits.

## Run and download

Open **Actions**, choose **Build Android S26+ Oryon APK**, and select **Run
workflow**. The default parallelism is 16; lower it if the remote builder has
less memory.

Live output is shown in the workflow job. On completion, download
`thorium-s26plus-oryon-arm64` from the run's **Artifacts** section. The artifact
contains the signed APK and its SHA-256 file. A separate build-log artifact is
uploaded even when compilation fails.
