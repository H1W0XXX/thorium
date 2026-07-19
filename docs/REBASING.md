# Rebasing Thorium

Thorium is maintained as ordered patches plus a small source overlay. The
Chromium worktree is a disposable application target; patch ownership remains
in this repository.

## Sources of truth

- `patch_scripts/series/series`: authoritative patch order and conditions.
- `other/**/*.patch`: feature and platform patches.
- `src/`: files that cannot yet be represented safely as patches, including
  selected binary resources and metadata.
- `patch_scripts/grd_rebase/config/`: string ownership and translation data.
- [`PATCHES.md`](PATCHES.md): reviewer-facing mirror of the active series.

Do not fix a patch conflict only in the Chromium worktree. Refresh the owning
patch so the change survives the next setup.

## Prepare a clean Chromium baseline

Commit or back up work first. `version.py` force-checks out Thorium's pinned
Chromium tag, deletes untracked Chromium files, synchronizes dependencies, and
runs hooks:

```shell
python3 version.py
```

Use `trunk.py` only when intentionally auditing tip-of-tree. It is similarly
destructive and should normally be followed by `version.py` before refreshing
release patches.

## Check or apply the series

Dry-run the normal series without changing Chromium:

```shell
python3 patch_scripts/series/apply_series.py \
  --source-tree /path/to/chromium/src
```

Apply it only to a disposable clean worktree:

```shell
python3 patch_scripts/series/apply_series.py \
  --source-tree /path/to/chromium/src --apply
```

Conditional entries use `--condition`, for example `--condition raspi` or
`--condition sse2`.

## Refresh patches

`refresh_series.py` uses temporary Git indexes and does not modify Chromium's
real worktree or index. To audit every entry, including every conditional
variant, run:

```shell
python3 patch_scripts/series/refresh_series.py \
  --source-tree /path/to/chromium/src --all-conditions
```

`--all-conditions` is a dry-run-only audit mode and cannot be combined with
`--write`. After reviewing the reported ownership and drift, refresh the
unconditional series separately:

```shell
python3 patch_scripts/series/refresh_series.py \
  --source-tree /path/to/chromium/src --write
```

Then refresh each conditional variant in its own run. The current series uses
the `sse2` and `raspi` conditions:

```shell
python3 patch_scripts/series/refresh_series.py \
  --source-tree /path/to/chromium/src --condition sse2 --write

python3 patch_scripts/series/refresh_series.py \
  --source-tree /path/to/chromium/src --condition raspi --write
```

Refresh failures usually indicate an obsolete context, an ordering dependency,
or responsibility that has drifted into another patch. Resolve ownership
before weakening context merely to make a patch apply.

## Strings and translations

User-facing strings should enter Chromium's GRIT flow. Feature patches own
their GRD/GRDP message declarations; translation additions and migration
metadata are maintained under `patch_scripts/grd_rebase/config`.

When message declarations change:

1. update `feature_patch_message_ownership.csv`;
2. update the message and file allowlists where required;
3. keep additions grouped by owning patch in the normalized TSV inventory;
4. provide all 81 supported locales for a new user-facing message unless the
   source has a documented narrower platform scope;
5. run the GRD synchronization and XTB merge in dry-run mode;
6. inspect missing/conflict reports before writing anything.

The detailed commands, data format, and current validation totals are in
[`patch_scripts/grd_rebase/README.md`](../patch_scripts/grd_rebase/README.md).
`setup.py` runs the non-dry-run synchronization after applying the series.

## Review checklist

- Every `other/**/*.patch` is represented in `series` or intentionally
  documented as inactive.
- Patch ordering comments and `PATCHES.md` match the series.
- Conditional patches were checked under every applicable condition.
- `git diff --check` reports no whitespace errors.
- New overlay files have real build, GRIT, packaging, or runtime references.
- Desktop, Android, ARM, macOS, Windows, and Linux conditionals do not leak
  unsupported flags or files into another platform.
- New user-visible strings have ownership and locale coverage.
- Copyright and third-party license text is preserved.

Compilation and tests are separate from patch refresh. Choose verification in
proportion to the affected platform and risk.
