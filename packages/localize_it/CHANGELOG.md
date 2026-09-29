## 2.1.0

- Requires Dart SDK `^3.11.0`.
- Supports `analyzer` 14 (`>=14.0.0 <15.0.0`), `source_gen` ^4.3.0 and `build` ^4.0.11, so it can be used together with Freezed 4.

## 2.0.0

- **Breaking:** Requires Dart SDK `^3.9.0` and a current Flutter toolchain (e.g. Flutter 3.35+).
- Upgraded codegen stack: `build` ^4, `source_gen` ^4, `build_runner` ^2.13, `http` ^1.6, `flutter_lints` ^6.
- Depends on `localize_it_annotation` ^3.0.0.
- `analyzer` dependency uses a bounded range (`>=8.1.1 <13.0.0`) compatible with `source_gen` / `build`.
- Migrated element visitor to Analyzer 10+ (`SimpleElementVisitor2`, fragment-based source location).
- Default values for optional config fields (`preferDoubleQuotes`, `useGetX`, `deepLAuthKey`) when omitted from the config class.

## 1.1.8
- Fixed analyzer dependency constraint to use 'any' to avoid version conflicts with other packages
- Resolves dependency resolution failures with app_lints and other packages requiring analyzer ^7.0.0 or higher

## 1.1.7
- Updated DeepL API authentication to use Authorization header (required for compatibility after January 15, 2026)
- Migrated from legacy auth_key in request body to DeepL-Auth-Key header format

## 1.1.6
- Log error status code when DeepL fails

## 1.1.5
- Request delay to avoid DeepL timeout
- Option to log translations 

## 1.1.4

- Updated dependencies

## 1.1.3

- No idea what changed here, long time ago.

## 1.1.2

- Fixed bug where saved Strings are reset and everything is translated again.

## 1.1.1

- Added option to use *double-quotes* for project.

## 1.1.0

- Resolved Issue having Single Quotes inside `Strings`.

## 1.0.9

- Added `generate` bug to README

## 1.0.8

- fixed missing translation 

## 1.0.7

- Version solving

## 1.0.6

- Downgrade Analyzer Version

## 1.0.5

- Upgraded dependencies

## 1.0.4

- Sync Annotation Version

## 1.0.3

- Added Example

## 1.0.2

- Refacroting

## 1.0.1

- More Pub Points!

## 1.0.0

- Let's go!

## 0.0.1

- Initial version.