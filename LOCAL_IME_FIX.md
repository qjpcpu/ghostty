# Discard unfinished IME text when switching input sources

This local macOS patch discards an unconfirmed composition when the input
source changes. For example, entering `nihao` with Doubao Pinyin and switching
to ABC with Cmd+Space clears the candidate without inserting text or executing
Vim Normal-mode commands. Confirming a candidate in the same input source
continues to work.

The behavior applies to the shell and all editor modes. Switching between
languages within one input method without changing its macOS input-source ID
is outside the scope of this patch.

## Implementation

`IMECompositionState` records the input-source ID when marked text first
appears. Candidate updates keep that original ID. `SurfaceView.insertText`
compares it with `KeyboardLayout.id` before forwarding a commit. If the source
changed, it clears the composition and pending surrogate, then returns.
Cancellation and completed commits reset the tracker. If either source ID is
unavailable, the normal input path is preserved.

The observed Doubao sequence on macOS 26.6.2 commits its unfinished text after
the current source becomes ABC, but before the input-source-change
notification. Other input methods with different callback ordering need
separate live verification.

## Build

Base commit: `5de703a1b6ca0b91fcebe932b44be1df2de0a683`.
Required: Zig 0.16.0, complete Xcode with the macOS SDK and Metal Toolchain,
gettext, and Nushell. Select the complete Xcode developer directory and
complete its first-launch setup before building.

```sh
xcodebuild -downloadComponent MetalToolchain
zig build -Doptimize=ReleaseFast -Demit-macos-app=false
nu macos/build.nu --configuration ReleaseLocal --action build
```

Output: `macos/build/ReleaseLocal/Ghostty.app`. The build does not replace the
installed application.

```sh
nu macos/build.nu --action test
```

## Validation

- The ReleaseLocal macOS app builds with Zig 0.16.0 and Xcode 27.0.
- The native macOS test target passes: 277 tests passed, one skipped, zero
  failures. This includes five policy tests covering switching, normal
  confirmation, late candidate updates, cancellation followed by a new
  composition, and missing source identity.
- SwiftLint passes for the three Swift files.
- The user verified cancellation and normal confirmation in a standalone
  AppKit app sharing the same policy implementation.
- The user verified both cases in the built Ghostty Debug app with Doubao
  on macOS 26.6.2: switching sources during an unfinished composition in
  Vim Normal mode sends neither text nor commands, and explicitly confirming
  a candidate in Insert mode still enters Chinese text.

AI assistance: OpenAI Codex investigated the input callbacks, implemented the
patch and tests, and ran available validation. The user performed the live
IME tests.
