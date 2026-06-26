# Thorium Patch Series

`patch_scripts/series/series` is the canonical ordered list for Thorium
patches. Patch files currently remain under `other/*.patch`.

Patch files intentionally remain in `other/` for now. The series layer records
ordering, apply roots, and platform conditions. Both `setup.sh` and
`win_scripts/setup.py` apply patches through this runner.

## Syntax

```text
other/example.patch
chromium/apply/root: other/example.patch
[condition] chromium/apply/root: other/example.patch
```

Patch paths are relative to the Thorium repository root. Apply roots are
relative to the Chromium source tree. Use forward slashes in the series file;
the runner resolves them through Python's `Path` APIs on the host platform.
For example, this applies the patch from inside Chromium's
`third_party/ffmpeg` checkout:

```text
third_party/ffmpeg: other/ffmpeg-branding.patch
```

## Check

Windows:

```powershell
py -3 patch_scripts\series\apply_series.py --source-tree C:\src\chromium\src --check
```

Linux/macOS:

```sh
python3 patch_scripts/series/apply_series.py --source-tree /path/to/chromium/src --check
```

`--check` is the default mode. It validates ordered patch dependencies by
applying each patch cumulatively to temporary Git indexes with
`git apply --cached`. This does not modify the Chromium worktree or its real
index.

If `--source-tree` is omitted, the runner follows the same convention as
Thorium's setup scripts:

1. `CR_DIR`
2. `CR_SRC_DIR`
3. `CHROMIUM_SRC`
4. `CHROMIUM_SRC_DIR`

It then falls back to `C:\src\chromium\src` on Windows or `~/chromium/src` on
Linux/macOS.

If `--thorium-root` is omitted, the runner uses `THOR_DIR` when set, otherwise
it uses the repository containing `patch_scripts/series/apply_series.py`.

## Conditions

Conditional entries are skipped unless explicitly enabled:

Windows:

```powershell
py -3 patch_scripts\series\apply_series.py --source-tree C:\src\chromium\src --check --condition sse2
```

Linux/macOS:

```sh
python3 patch_scripts/series/apply_series.py --source-tree /path/to/chromium/src --check --condition sse2
```

Multiple conditions can be supplied, for example:

Windows:

```powershell
py -3 patch_scripts\series\apply_series.py --source-tree C:\src\chromium\src --check --condition sse2 --condition raspi
```

Linux/macOS:

```sh
python3 patch_scripts/series/apply_series.py --source-tree /path/to/chromium/src --check --condition sse2 --condition raspi
```

## Apply

Windows:

```powershell
py -3 patch_scripts\series\apply_series.py --source-tree C:\src\chromium\src --apply
```

Linux/macOS:

```sh
python3 patch_scripts/series/apply_series.py --source-tree /path/to/chromium/src --apply
```

`--apply` modifies the Chromium checkout. It first checks whether a patch
applies cleanly, applies it with `git apply --reject`, and treats
reverse-applicable patches as already applied.

## Policy

External patches should be imported into `other/` before they become part of
the normal rebase flow. Add a separate external series only if Thorium later
needs to consume a live external patch stack during review.
