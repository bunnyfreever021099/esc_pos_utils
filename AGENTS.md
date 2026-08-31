# Repository Guide

## Toolchain

- `pubspec.yaml` requires Dart `>=3.0.0 <4.0.0`; use a Dart 3-compatible Flutter SDK.
- `image` 4.x APIs are used in `Generator`; preserve image byte output when updating it.

## Commands

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/esc_pos_utils_test.dart
flutter test test/esc_pos_utils_test.dart --plain-name 'encodes Thai text with CP874'
flutter pub publish --dry-run
```

There is no repository-defined command runner or enforced verification order.

## Architecture And Gotchas

- `lib/esc_pos_utils.dart` is the public entrypoint. `lib/src/generator.dart` is the core implementation; transport and printer connections belong to separate packages.
- `Generator` is stateful. Its methods update style, font, code-table, and alignment state while returning ESC/POS byte lists. Preserve command ordering and assert exact output bytes when changing generation behavior.
- `Generator.row` requires column widths to total exactly 12 and recursively emits overflow rows. Mixed Chinese/Latin text follows separate GBK/Kanji width and command paths; `textEncoded` is the escape hatch for caller-provided bytes.
- Printer profiles live in `lib/resources/capabilities.json`. They load through Flutter `rootBundle` using the pubspec asset path `packages/esc_pos_utils/resources/capabilities.json`; keep both paths synchronized and use normal `flutter test` asset bundling.
- Direct CP874 encoding supports ASCII and Thai characters and requires a matching printer profile/code-page ID. Other characters throw `FormatException`; do not silently replace them.
- Tests assert exact bytes for Thai and image commands. Add focused byte assertions when changing command generation.
