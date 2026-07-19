# Thorium SSE2

This directory contains build config files for compiling 32 bit Thorium/Chromium with [SSE2](https://en.wikipedia.org/wiki/SSE2).

Chromium no longer officially supports 32-bit Linux, and current upstream x86
build settings normally require SSE3. These argument files select
`thorium_x86_profile = "sse2"` for Thorium's explicitly validated compatibility
build. The central compiler configuration owns the actual ISA flags; this
directory does not duplicate them.
