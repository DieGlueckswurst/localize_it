## 4.0.0

- Added `String.trWithArgs(Map<String, Object?> args)` for translations with named `{name}` placeholders.
- Added `LocalizeIt.translate` to plug in the runtime lookup (e.g. `LocalizeIt.translate = (key) => key.tr;` with GetX).

## 3.0.0

- **Breaking:** Requires Dart SDK `^3.9.0` (drops support for Dart 2.x and for Dart versions below 3.9).
- Bumped dev dependency `test` to a current major.

## 2.0.0

- Updated README.md.

## 1.0.1

- Migrated to null-safety.

## 1.0.0

- Initial version.