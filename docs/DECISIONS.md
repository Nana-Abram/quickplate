# Decisions

One line per decision made where the spec was silent or ambiguous.

- Android package and iOS bundle id are `com.abraham.quickplate`: `flutter create` was run with `--org com.abraham` because `--org com.abraham.quickplate` would append the project name and produce `com.abraham.quickplate.quickplate`.
- Analyzer runs with `strict-casts` and `strict-raw-types` on top of the lint rules in ARCHITECTURE.md, to catch unsafe JSON casts in hand-written models.
- `.gitattributes` forces LF line endings so the repo looks the same on Windows, macOS and Linux.
- CI pins the Flutter version (3.47.5) so local and CI analysis agree; bump it deliberately.
