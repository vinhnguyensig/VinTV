# VinAppleTV

VinAppleTV is a SwiftUI streaming-app demo for Apple TV. It demonstrates a
tvOS-first interface, focus-aware content rails, modular Swift packages,
AVPlayer-backed HLS playback, local persistence, analytics, and testable MVVM
feature flows.

The app uses a local catalog of 12 mock titles and Apple's public sample HLS
stream, so it can demonstrate the complete browsing and playback experience
without a backend service.

## Features

- Animated splash screen and app composition root
- Home screen with Featured, Continue Watching, Trending, and Recommended rails
- Siri Remote focus treatments and preferred initial focus
- Content details with metadata, favorite state, and resume/start-over actions
- HLS playback with play/pause, 10-second seeking, progress display, and
  completion tracking
- Persistent favorites and playback progress using `UserDefaults`
- Real-time local title search
- Typed analytics for screen, selection, and playback events
- Loading, empty, error, and retry states
- Unit tests for app composition, view models, storage, domain logic, data, and
  package services
- GitHub Actions jobs for build, unit tests, and SwiftLint

## Requirements

- macOS with Xcode 26 or later
- tvOS 26 SDK for the app target
- Swift 6 toolchain for the local Swift packages
- SwiftLint for local linting

The package manifests support tvOS 18+ and macOS 14+, but the current Xcode app
and test targets have a tvOS 26.0 deployment target.

## Getting Started

1. Clone the repository.
2. Open `VinAppleTV.xcodeproj` in Xcode.
3. Select the `VinAppleTV` scheme.
4. Choose an Apple TV simulator or a configured Apple TV device.
5. Build and run.

No API keys or environment files are required. Network access is needed only
when playing the public sample HLS stream.

To build from the command line:

```sh
xcodebuild build \
  -project VinAppleTV.xcodeproj \
  -scheme VinAppleTV \
  -destination 'generic/platform=tvOS' \
  -derivedDataPath /tmp/VinAppleTVDerivedData \
  CODE_SIGNING_ALLOWED=NO
```

## Architecture

The app follows MVVM with a lightweight Clean Architecture boundary:

```text
SwiftUI View
    |
ViewModel
    |
Domain Use Case
    |
Repository Protocol
    |
Mock Data Source / Local Storage / AVPlayer
```

`AppContainer` is the composition root. It creates the repository, analytics
tracker, local storage, shared playback-progress and favorite state, theme, and
feature view models. Each playback session receives its own player service,
while protocol-based dependencies keep feature logic replaceable in tests.

Navigation begins in `RootView`:

```text
Splash
  -> Home tab
     -> Content detail
        -> Player
  -> Favorites tab
     -> Content detail
  -> Search tab
     -> Content detail
```

## Modules

The main tvOS target contains app composition and feature presentation:

```text
VinAppleTV/
├── App/                 App container, root view, and startup state
├── Features/
│   ├── Splash/          Animated launch experience
│   ├── Home/            Hero content and horizontal rails
│   ├── Detail/          Metadata, favorites, and playback entry
│   ├── Player/          Playback UI and progress persistence
│   ├── Favorites/       Saved-content grid
│   └── Search/          Real-time local search
└── Assets.xcassets/
```

Reusable foundations live in local Swift packages under `AppSPM`:

| Package | Responsibility |
| --- | --- |
| `TVDomain` | Content models, repository contracts, and use cases |
| `TVData` | Mock catalog, mock progress, filtering, lookup, and search |
| `VPPlayer` | AVPlayer lifecycle, playback state, progress, and seeking |
| `VPLocalStorage` | Key-value storage abstraction and UserDefaults adapter |
| `VPCommon` | Typed analytics primitives |
| `VPAppTheme` | Semantic colors, typography, spacing, radii, focus appearance, layout metrics, and SwiftUI theme environment |
| `VPCore` | Reserved core foundation module |

`AppContainer` owns one immutable `VPTheme`, and `RootView` injects it into the
SwiftUI environment. Feature views compose layout and retain focus ownership,
while shared visual values and accessibility-aware focus styling come from
`VPAppTheme`. Tests and previews can inject a fully custom theme without a
global theme manager.

## Data and Persistence

`MockContentDataSource` provides the built-in catalog. Every title currently
uses the same Apple sample HLS URL, while metadata and section membership vary
to exercise the UI.

Favorites are stored as content IDs. Playback progress is stored per title as
JSON containing the current position, duration, last-watched date, and
completion state. Both use the `KeyValueStoring` abstraction backed by
`UserDefaults`.

The mock repository also includes seeded Continue Watching entries. A
workflow-level Home loader reconciles those seeds with locally saved player
progress, so Detail, Player, and Continue Watching share the same effective
state and completed titles disappear from the rail.

## Testing

Run the app unit tests with an available Apple TV simulator:

```sh
xcodebuild test \
  -project VinAppleTV.xcodeproj \
  -scheme VinAppleTV \
  -destination 'platform=tvOS Simulator,name=Apple TV,OS=latest' \
  -derivedDataPath /tmp/VinAppleTVTestDerivedData \
  -only-testing:VinAppleTVTests \
  CODE_SIGNING_ALLOWED=NO
```

Each local package also has an independent test target. For example:

```sh
swift test --package-path AppSPM/TVDomain
swift test --package-path AppSPM/TVData
swift test --package-path AppSPM/VPCommon
swift test --package-path AppSPM/VPAppTheme
```

Run lint checks with:

```sh
swiftlint --no-cache --config .swiftlint.yml
```

## Continuous Integration

`.github/workflows/ci.yml` runs for pull requests and manual dispatches. It uses
separate jobs to:

- build the unsigned tvOS app
- run `VinAppleTVTests` and upload the result bundle
- run SwiftLint


## Current Scope

VinAppleTV is a technical demonstration rather than a production streaming
service. The catalog and initial Continue Watching data are local, artwork is
represented by generated visual treatments, analytics are printed only in
debug builds, and there is no authentication or remote content API.

See the task plan for remaining splash-status reconciliation and optional bonus
work such as richer production integrations.
