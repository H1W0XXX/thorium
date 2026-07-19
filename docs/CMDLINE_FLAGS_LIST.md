# Command-line switches

Chromium command-line switches are implementation details and change between
revisions. Thorium does not keep a copied switch database in this repository.

Useful references are:

- the current checked-out Chromium source, searched through
  [Chromium Code Search](https://source.chromium.org/chromium/chromium/src);
- the community-maintained [Chromium command-line switch
  list](https://peter.sh/experiments/chromium-command-line-switches/).

The community list is not an official Chromium specification and may not match
Thorium's exact Chromium revision. Confirm security-sensitive or
platform-specific switches in source before relying on them.

Thorium's development launch examples remain in
[`infra/DEV_CMDLINE_FLAGS.txt`](../infra/DEV_CMDLINE_FLAGS.txt). Some disable
security boundaries or alter profile behavior; use them only with disposable
test data.

The command line used by a running desktop build is shown on
`thorium://version` (or `chrome://version`). Flags exposed through
`thorium://flags` are experiments and do not necessarily map one-to-one to a
single command-line switch.
