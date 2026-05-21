# AGENTS.md
## Run Tests
```
xcodebuild test \
  -workspace iPlayground/iPlayground.xcworkspace \
  -scheme iPlayground \
  -testPlan iPlayground \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64'
```

## Git Workflow Rules
- **When implementing a new feature**: ALWAYS create a new feature branch from `main`
- **Feature branch naming**: Use descriptive names like `featureName`
- **REQUIRED**: Feature branches → PR to `main` → GitHub Copilot review → Squash merge
- **CRITICAL**: Never commit directly to `main` branch - ALWAYS use feature branches
- **After creating PR**: ALWAYS open the PR URL in browser using `open` command
- **Squash merge messages**: Always provide clean, summarized commit message for squash merges
- **Prune feature branches after merge**

## Testing
- **TDD**: Write tests first before implementation
- **CRITICAL**: Run each test immediately after writing it - never batch-write multiple tests without running them
- **TDD Order**: When modifying existing code, ALWAYS update tests first, then implementation
- **Test Coverage**: Always write tests for new features, refactorings, and bug fixes
- For non-macOS projects, use xcodebuild to run tests

## Swift Programming Rules
- **ALWAYS run `swift-format` before committing**
- **ALWAYS fix all tests before committing**
- No spaces for empty lines
- Use 2-space indentation
- Prefer using Swift 6.0
- **Prefer `case let .action(value)` over `case .action(let value)`**
- **Prefer `else` when writing `if`** - for consistency and readability
- **Logging**: Always use OSLog instead of print
  ```swift
  import OSLog
  private let logger = Logger(subsystem: "LibraryName", category: "FileName") // file scoped logger
  ```

## SwiftUI Rules
- Prefer .buttonStyle(.plain) over PlainButtonStyle()
- Always use `.task` instead of `.onAppear` / `.onDisappear`
- Every SwiftUI view needs `#Preview` for quickly looking up UI of different states

## TCA(The Composable Architecture) Rules
- One TCA feature per file
- **Core function pattern**: Move reducer logic to `func core` for better compiler error detection
  ```swift
  package var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(core)
      .forEach(\.path, action: \.path)
  }
  
  package func core(into state: inout State, action: Action) -> Effect<Action> {
    // reducer logic here
  }
  ```
- Always create custom error enums (never `Error` directly, no `unknown(String)` cases)
- **SwiftUI Lifecycle**: ALWAYS use SwiftUI `.task` instead of `.onAppear` / `.onDisappear` for TCA actions
  ```swift
  // ❌ WRONG - Use onAppear
  case onAppear
  
  // ✅ CORRECT - Use task + specific internal actions
  case task
  case setVersions(appVersion: String, buildNumber: String)
  case setUserInfo(isAuthenticated: Bool, userMobile: String)
  ```
- **ViewAction pattern**: Separate user actions from internal actions
  ```swift
  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case view(ViewAction)
    case binding(BindingAction<State>)
    case delegate(Delegate)
  }
  ```
- **Use `@ViewAction(for:)` macro on SwiftUI views** to restrict available actions and enable `send()` function
  ```swift
  @ViewAction(for: WelcomeFeature.self)
  package struct WelcomeView: View {
    @Bindable package var store: StoreOf<WelcomeFeature>
    
    var body: some View {
      Button("Start") { send(.start) } // send() available via @ViewAction macro. `store.send` will be forbidden automatically
      .task { send(.checkAppVersion) }
    }
  }
  ```
- **Delegate pattern**: Use switch for robust handling that won't miss future actions
  ```swift
  case let .path(.element(id: _, action: .child(.delegate(delegateAction)))):
    switch delegateAction {
    case .someAction(let data): handleAction(data)
    }
  ```
- For custom action enums, need `@CasePathable` macro for dot syntax  (`await store.send(\.action)`)
- **BindingReducer**: For simple state updates (no custom actions needed)
- **Stack navigation**: Use `StackState`/`StackAction` for hierarchical navigation
- **Path reducer pattern**: Use @Reducer enum for navigation paths
  ```swift
  extension SomeFeature {
    @Reducer(state: .equatable, action: .equatable)
    package enum Path {
      case detail(DetailFeature)
    }
  }
  ```
- **Shared state**: 
  - Prefer to add a custom SharedKey for better readability
  - When implement with .appStorage persistence, only can use primitive types that supported by `UserDefaults`
  - For read only state, prefer to use `@SharedReader` macro. For writeable state, need to use `@Shared` macro.
  - When modifying a shared state in tests, use `$value.withLock { $0 = ... }` syntax
- **TCA Test Syntax**: 
  ```swift
  // Single parameter or no parameters
  await store.receive(\.action)
  await store.receive(\.action, .someCase)
  
  // Multiple parameters - use upper level action as container
  await store.receive(\.view, .setVersions(appVersion: "2.0.0", buildNumber: "42", isAuthenticated: true, localAuthEnabled: true))
  await store.receive(\.view, .setUserInfo(isAuthenticated: true, userMobile: "0912345678"))
  ```
- Swift Testing for Models, XCTest for Features (TCA integration)
- Use `expectNoDifference(a, b)` instead of `XCTAssertEqual(a, b)`(XCTest) or `#expect(a == b)`(Swift Testing) for better diff output

### Swift Dependencies Rules
- **DependencyClients library**: Define protocols with `TestDependencyKey` conformance for test values
- **DependencyClientsLive library**: Define `DependencyKey` conformance with `liveValue` implementation
- **Leverage @DependencyClient Macro**: provides default method implementations, use `Self()` for testValue structs, custom implementations for complex clients
- **Dependencies in Reducers**: NEVER use @Dependency as properties in Reducer - causes Sendable issues
  ```swift
  // ❌ WRONG - Sendable issue
  @Dependency(\.apiClient) var apiClient
  
  // ✅ CORRECT - Use in Effect closures
  return .run { send in
    @Dependency(\.apiClient) var apiClient
    let result = await apiClient.getData()
    await send(.dataLoaded(result))
  }
  ```