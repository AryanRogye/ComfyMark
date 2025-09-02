# Repository Guidelines

## Project Structure & Module Organization
- `ComfyMark/App/`: App entry points (`ComfyMarkApp`, `AppDelegate`, `AppCoordinator`).
- `ComfyMark/Coordinators/`: Window/Menu/Settings flow coordination.
- `ComfyMark/Views/`: SwiftUI views and components; Metal shader at `Views/Components/image.metal`.
- `ComfyMark/Models/`: Rendering primitives and state (`Stroke`, `Vertex`, `MetalContext`).
- `ComfyMark/Services/`: App services (e.g., `ScreenshotService`, `ExportService`).
- `ComfyMark/Extensions/`: Small utility extensions.
- `ComfyMark/Config/`: `Info.plist`, entitlements; `Assets.xcassets/` for images and colors.

## Build, Test, and Development Commands
- Open in Xcode: `open ComfyMark.xcodeproj` then run the `ComfyMark` scheme.
- CLI build (Debug): `xcodebuild -scheme ComfyMark -configuration Debug -destination 'platform=macOS' build`.
- Tests: XCTest target not yet present. When added, run via Xcode (⌘U) or `xcodebuild ... test`.

## Coding Style & Naming Conventions
- Indentation: 4 spaces, no tabs; keep lines reasonably short (~120 cols).
- Swift naming: `UpperCamelCase` for types; `lowerCamelCase` for methods/properties; files match primary type name.
- Suffix patterns: `...View`, `...ViewModel`, `...Coordinator`, `...Service`.
- Imports sorted; mark sections with `// MARK:`; use `final` for non‑subclassed types.
- SwiftUI: keep views small and previewable; push logic into ViewModels/Services.

## Testing Guidelines
- Framework: XCTest with mirror folders under `ComfyMarkTests/` (e.g., `ServicesTests/ExportServiceTests.swift`).
- Naming: `test_<method>_<behavior>()`; prefer deterministic tests.
- Focus: cover core logic in Services and ViewModels; UI snapshot tests optional.

## Commit & Pull Request Guidelines
- Commits: short imperative subject (≤50 chars), optional body for rationale.
  - Examples: `Add ExportService PNG support`, `Fix MenuBarCoordinator window focus`.
- PRs: clear description, linked issues, before/after screenshots for UI, and test/QA steps.
- Scope: keep PRs focused; update README or comments when behavior changes.

## Security & Configuration Tips
- Review `ComfyMark/Config/ComfyMark.entitlements` before adding capabilities; justify changes in PRs.
- Do not commit secrets; keep identifiers and signing settings consistent across schemes.
