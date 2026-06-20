# GRD/XTB Rebase

This directory contains the reviewed Thorium GRD/GRDP and XTB rebase tooling
for moving Thorium string changes out of the overlay and into repeatable
scripts.

The runtime surface is intentionally small:

- `sync_grd_strings.py` updates reviewed Chromium GRD/GRDP messages, computes
  old and new GRIT translation IDs, and copies compatible upstream XTB
  translations to the new Thorium IDs.
- `merge_thorium_xtb.py` merges reviewed Thorium-owned translation additions
  from `config/m150_xtb_additions.tsv` into Chromium XTB bundles.

Both scripts use only the Python standard library. They do not require
`vpython`, `depot_tools`, or a Chromium checkout's Python wrapper. Python 3.11
or newer is the supported runtime.

## Configuration

The files in `config/` are reviewed inputs, not generated setup output:

- `file_allowlist.csv`: reviewed GRD/GRDP file scope and file ownership role.
  `from_overlay` records the legacy source of the reviewed change; pure
  `overlay_text_sync` files do not need to remain under `src/` once their
  message IDs are covered by `message_allowlist.csv`.
- `message_allowlist.csv`: reviewed message-level replacement scope.
- `feature_patch_message_ownership.csv`: feature-patch and overlay-added
  message ownership; used to prevent feature-patch strings from being handled
  by the overlay replacement workflow.
- `legacy_xtb_id_reconciliation.csv`: reviewed legacy XTB ID decisions retained
  for audit.
- `m150_xtb_additions.tsv`: canonical reviewed translation additions; currently
  984 translation rows across 241 XTB files.

Generated `.xtb.add` files are not committed. `merge_thorium_xtb.py` still
supports `--additions-root` for compatibility and spot checks, but the normal
source of truth is `m150_xtb_additions.tsv`.

## Run Order

Run the scripts after Chromium and non-string feature patches are in place:

1. Run `sync_grd_strings.py`.
2. Run `merge_thorium_xtb.py`.

This order keeps overlay-derived old/new ID syncing separate from reviewed
Thorium-owned additions.

## Python Runtime

Use any Python 3.11+ interpreter available on the host:

```bash
python3 patch_scripts/grd_rebase/sync_grd_strings.py --help
python3 patch_scripts/grd_rebase/merge_thorium_xtb.py --help
```

On Windows, either `py -3.11`, a normal `python.exe`, or
`C:\src\depot_tools\python3.bat` can be used. The depot_tools wrapper is only a
convenient Chromium-environment Python, not a requirement for these scripts.

All config paths stored in this directory use repository-relative POSIX-style
paths. Command-line paths may use native platform separators or `/`; the scripts
normalize them internally where needed.

## Dry Run

Dry-run the overlay string sync and write audit reports:

```bash
python3 patch_scripts/grd_rebase/sync_grd_strings.py \
  /path/to/chromium/src \
  --file-allowlist patch_scripts/grd_rebase/config/file_allowlist.csv \
  --message-allowlist patch_scripts/grd_rebase/config/message_allowlist.csv \
  --dry-run \
  --xtb-conflict-report out/grd_rebase/m150_xtb_conflicts.tsv \
  --xtb-missing-report out/grd_rebase/m150_xtb_missing.tsv \
  --thorium-added-report out/grd_rebase/m150_thorium_added.tsv \
  > out/grd_rebase/m150_grd_sync_dry_run.tsv
```

Dry-run the reviewed additions merge:

```bash
python3 patch_scripts/grd_rebase/merge_thorium_xtb.py \
  /path/to/chromium/src \
  --dry-run
```

Expected current additions summary:

```text
validated 984 Thorium translations across 241 XTB files: 984 inserted, 0 already present, 241 files changed
```

Equivalent PowerShell form:

```powershell
py -3.11 patch_scripts/grd_rebase/sync_grd_strings.py `
  C:\src\chromium\src `
  --file-allowlist patch_scripts/grd_rebase/config/file_allowlist.csv `
  --message-allowlist patch_scripts/grd_rebase/config/message_allowlist.csv `
  --dry-run `
  --xtb-conflict-report out/grd_rebase/m150_xtb_conflicts.tsv `
  --xtb-missing-report out/grd_rebase/m150_xtb_missing.tsv `
  --thorium-added-report out/grd_rebase/m150_thorium_added.tsv `
  > out/grd_rebase/m150_grd_sync_dry_run.tsv

py -3.11 patch_scripts/grd_rebase/merge_thorium_xtb.py `
  C:\src\chromium\src `
  --dry-run
```

## Apply

Apply overlay GRD/GRDP replacements and copied XTB translations:

```bash
python3 patch_scripts/grd_rebase/sync_grd_strings.py \
  /path/to/chromium/src \
  --file-allowlist patch_scripts/grd_rebase/config/file_allowlist.csv \
  --message-allowlist patch_scripts/grd_rebase/config/message_allowlist.csv
```

Apply reviewed XTB additions:

```bash
python3 patch_scripts/grd_rebase/merge_thorium_xtb.py \
  /path/to/chromium/src
```

Both operations are designed to be idempotent.

## GRIT ID Notes

`sync_grd_strings.py` contains a lightweight GRIT message ID replica for the
reviewed allowlist. It matches Chromium's `GenerateMessageId()` fingerprint and
meaning-combination behavior:

- MD5 first 64 bits interpreted as signed.
- Optional `meaning` fingerprint combined with the message fingerprint.
- The high bit is stripped to produce a positive decimal ID.
- `use_name_for_id="true"` returns the message name.
- `<ph name="...">` uses the placeholder presentation/name in presentable
  content.

The replica is intentionally scoped to the reviewed Thorium string set. The
current changed allowlist contains no changed messages with active
`<if>/<then>/<else>` branches. If future allowlist entries include conditional
message bodies that need platform-specific active-branch resolution, compare
against Chromium GRIT parser output before enabling them.

## Reports

`sync_grd_strings.py` can write three optional audit reports:

- `--xtb-conflict-report`: converged new-ID conflicts where multiple old
  translations map to the same new ID. The script deterministically keeps the
  first candidate and reports rejected candidates.
- `--xtb-missing-report`: mapped XTB files where the old Chromium translation ID
  was not found. Missing translations are reported but do not block the run.
- `--thorium-added-report`: Thorium-added files/messages routed to the separate
  additions workflow instead of the upstream replacement workflow.

Current dry-runs may print warnings for converged XTB conflicts and missing old
IDs. Those warnings are expected when their TSV reports are reviewed.

## Validation

Basic syntax checks:

```bash
python3 -m py_compile \
  patch_scripts/grd_rebase/sync_grd_strings.py \
  patch_scripts/grd_rebase/merge_thorium_xtb.py
```

Behavior validation should compare dry-run/report output hashes before and
after changes. The current stable report hashes for the normal M150 dry-run are:

```text
dry_run.tsv   C3C97E8D9FD33BE4DF3819E5C790955EC8DF07D0FC5AF3F2193D7CF762C24AD0
conflicts.tsv 9EF22D3046D40219A8ED006E9352D9378A72800650F53219010F3E316EBED3D1
missing.tsv   92896E65DF35AF9ABFEB6F64FF33121500E2AA4A07238ABF938B926B5433F407
added.tsv     184E48593B6649E54F60681B9D972B889018CBF067499FE6633ED73C15D60C28
```

These hashes are useful for script refactors. They may intentionally change if
the reviewed allowlists, replacement rules, or translation inventory change.
