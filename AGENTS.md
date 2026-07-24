# AGENTS.md

## Project Baseline

- Treat `Package.swift` as the source of truth for Swift tools, deployment targets, and package versions; do not duplicate version pins here.
- Inspect `Package.swift`, the workspace `Package.resolved`, and the dependency's checked-out API before changing package or migration code.
- Preserve the module boundaries: `Models`, `DependencyClients`, `DependencyClientsLive`, `Features`, `Views`, and `PublicApp`.

## Git Workflow Rules

- Create one version branch from `main` for each release, named after the version (for example, `2026.0.1`).
- Do all development for that release directly on its version branch.
- Never commit directly to `main`.
- Split commits by user-visible concern; keep unrelated dirty files unstaged.
- Open one PR from the version branch to `main`, and open its URL in the browser.
- Merge with a merge commit; never squash or rebase merge.

## Work Order

- Read source, types, package manifests, and dependency APIs before using builds or tests as confirmation.
- Prefer `xcode-cli` for focused local build/test checks. Use `xcodebuild` for the full test plan and CI parity.
- Run only one `xcodebuild` process at a time and use the default DerivedData path.

## Build and Tests

- For behavior changes and bug fixes, add or update the smallest relevant test first, run it immediately, then implement.
- Run focused tests while iterating; run the full test plan before committing release work.
- Use Swift Testing for model tests. Use XCTest and `TestStore` for feature tests; use XCTest for view/presentation tests.
- Use `expectNoDifference` for structured state/value diffs. Native `XCTAssert*` and `#expect` remain appropriate for scalar and boolean assertions.
- Fix all unexpected test failures before committing.

```sh
xcodebuild test \
  -workspace iPlayground/iPlayground.xcworkspace \
  -scheme iPlayground \
  -testPlan iPlayground \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64'
```

## Swift Style

- Treat `.swift-format` as the formatting source of truth. Use 2-space indentation and no whitespace-only blank lines.
- Run `xcrun swift-format format --in-place` on changed Swift files before committing, then review the formatting diff.
- Prefer `case let .action(value)` for bound enum cases.
- Use `guard` for early exits and `else` for mutually exclusive branches.
- Use OSLog instead of `print` for runtime logging; keep loggers file-scoped.

## SwiftUI

- Prefer `.buttonStyle(.plain)` over `PlainButtonStyle()`.
- Use `.task` or `.task(id:)` for async lifecycle work instead of `.onAppear` / `.onDisappear`.
- Add `#Preview` to user-facing screens and meaningful states. Small reusable primitives may be covered by a parent preview or focused tests.
- Prefer native `Link(destination:)` for simple external URLs; add copy actions with a context menu when needed.
- When changing user-visible copy, update every supported localization in `Localizable.xcstrings`.

## The Composable Architecture

- Keep one feature domain per file. Keep stack destinations in the feature's `+Path.swift` extension file.
- Use modern observation-based TCA APIs; do not add legacy `ViewStore`, `WithViewStore`, `@BindableState`, or `@PresentationState` APIs.
- Keep reducer logic in the repo's `Reduce(core)` seam:

  ```swift
  package var body: some ReducerOf<Self> {
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    // Reducer logic
  }
  ```

- Put user-originated actions under `ViewAction`; keep effect responses and navigation actions at the feature-action level.
- For `ViewAction`-conforming features, use `@ViewAction(for:)` on the corresponding SwiftUI view and send view actions through `send`.
- Add `BindableAction`, a `binding` case, and `BindingReducer()` only when the feature exposes store bindings.
- Use `StackState` / `StackAction` and an `@Reducer` path enum for hierarchical navigation.
- Add `@CasePathable` when case-key-path syntax is needed by views or tests.
- Use domain-specific error types at subsystem boundaries; do not add catch-all `unknown(String)` cases.

### Dependencies and Shared State

- Prefer controlled `@Dependency` values over direct calls to clocks, UUIDs, clients, pasteboards, and other side effects.
- `@Dependency` is valid directly in reducers and derived state. Resolve it inside an effect closure when the dependency must be captured at effect execution time.
- Define interfaces as `@DependencyClient` types in `DependencyClients`, with `TestDependencyKey` values safe for tests and previews.
- Add live implementations through `DependencyKey.liveValue` in `DependencyClientsLive`.
- Prefer named custom `SharedKey` values. Use `@SharedReader` for read-only access and `@Shared` for mutation.
- Mutate shared values through their projected-value lock, including in tests: `$value.withLock { ... }`.
