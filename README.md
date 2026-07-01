# VinAppleTV

VinAppleTV is a SwiftUI streaming-app demo for Apple TV. It demonstrates a
tvOS-first interface, focus-aware content rails, modular Swift packages,
AVPlayer-backed HLS playback, local persistence, analytics, and testable MVVM
feature flows.

The app uses a local catalog of 12 mock titles and Apple's public sample HLS
stream, so it can demonstrate the complete browsing and playback experience
without a backend service.

## Prototype

Watch the [VinAppleTV prototype demo on YouTube](https://www.youtube.com/watch?v=6bZDNoif2rY).

## Features

- Animated splash screen and app composition root
- Home screen with Featured, Continue Watching, Trending, and Recommended rails
- Siri Remote focus treatments and preferred initial focus
- Content details with metadata, favorite state, and resume/start-over actions
- Production-oriented HLS playback with deterministic state transitions,
  buffering and stall recovery, bounded retry, network reconnection,
  10-second seeking, progress persistence, and completion tracking
- Persistent favorites and playback progress using `UserDefaults`
- Real-time local title search
- Typed analytics for screen, selection, playback, buffering, recovery,
  milestones, errors, and Quality of Experience metrics
- Player loading, buffering, seeking, reconnecting, retry, quality, and
  terminal-error presentation
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
tracker, local storage, player service, shared favorite state, theme, and
feature view models. Protocol-based dependencies keep feature logic replaceable
in tests.

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
| `VPPlayer` | AVPlayer lifecycle, state machine, buffering, recovery, QoE metrics, progress, seeking, and optional next-item preloading |
| `VPLocalStorage` | Key-value storage abstraction and UserDefaults adapter |
| `VPCommon` | Typed analytics and shared routing primitives |
| `VPAppTheme` | Semantic colors, typography, spacing, radii, focus appearance, layout metrics, and SwiftUI theme environment |
| `VPCore` | Reserved core foundation module |

`AppContainer` owns one immutable `VPTheme`, and `RootView` injects it into the
SwiftUI environment. Feature views compose layout and retain focus ownership,
while shared visual values and accessibility-aware focus styling come from
`VPAppTheme`. Tests and previews can inject a fully custom theme without a
global theme manager.

## Player Architecture

Playback is split between the reusable `VPPlayer` package and the app's Player
feature:

```text
PlayerView
    |
PlayerViewModel
    |-- progress persistence
    |-- typed analytics
    |
VideoPlayerServicing
    |
VideoPlayerService
    |-- PlayerStateMachine
    |-- AVPlayer buffer and stall observation
    |-- PlaybackMetricsCollector
    |-- retry and authorization recovery
    |-- PlaybackNetworkMonitor
    |
AVPlayer / AVPlayerItem
```

`VideoPlayerService` owns the AVPlayer lifecycle and publishes observed state;
the UI does not infer playback state from button taps. Its production state
model covers:

```text
Idle -> Loading -> Ready -> Playing -> Completed
                    |         |
                    |         +-> Buffering -> Playing
                    |         +-> Seeking -> Playing / Paused
                    |         +-> Reconnecting -> Loading
                    |         +-> Retrying -> Loading / Failed
                    +-> Paused
```

The service observes item readiness, `timeControlStatus`, buffer-empty and
likely-to-keep-up signals, playback stalls, completion, and access-log changes.
It configures AVPlayer to minimize stalling, resumes recovered playback only
when the user previously intended to play, and removes item-specific observers
whenever playback stops or the item is replaced.

Transient playback failures use configurable bounded backoff, with defaults of
2, 4, and 8 seconds. `NWPathMonitor` drives offline/reconnect state and restores
the prior position and play/pause intent. An injected authorization-refresh
protocol can replace an expired stream URL without coupling `VPPlayer` to an
account or token implementation.

Each playback session collects:

- startup time and time to first frame
- buffer count and total buffer duration
- stall position and recovery duration
- 25%, 50%, and 75% completion milestones
- observed and indicated bitrate, transfer duration, throughput, and bitrate
  switches from `AVPlayerItemAccessLog`

These values are emitted as typed playback events. `PlayerViewModel` translates
them into the shared analytics model while keeping the metrics collector
independent of any analytics vendor.

`NextItemPreloader` provides an optional 80%-threshold preloading boundary. It
requires an injected next-item provider and remains inactive in the app because
the current content domain does not define episodes, ordering, or autoplay
policy.

## Data and Persistence

`MockContentDataSource` provides the built-in catalog. Every title currently
uses the same Apple sample HLS URL, while metadata and section membership vary
to exercise the UI.

Favorites are stored as content IDs. Playback progress is stored per title as
JSON containing the current position, duration, last-watched date, and
completion state. Both use the `KeyValueStoring` abstraction backed by
`UserDefaults`.

The mock repository also includes seeded Continue Watching entries. Locally
saved player progress is used by the detail and player flows.

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
swift test --package-path AppSPM/VPPlayer
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

## Documentation

- [`Docs/requirement.md`](Docs/requirement.md) describes the product and
  architecture goals.
- [`Docs/Tasks/README.md`](Docs/Tasks/README.md) tracks the implementation plan
  and task status.
- [`Docs/update-theme-plan.md`](Docs/update-theme-plan.md) describes the
  implemented design-system migration.
- [`Docs/improve-player-plan.md`](Docs/improve-player-plan.md) describes the
  production playback requirements.
- [`Docs/player-validation-matrix.md`](Docs/player-validation-matrix.md)
  tracks the manual playback, recovery, focus, and accessibility scenarios.

## Current Scope

VinAppleTV is a technical demonstration rather than a production streaming
service. The catalog and initial Continue Watching data are local, artwork is
represented by generated visual treatments, analytics are printed only in
debug builds, and there is no concrete authentication, DRM, analytics backend,
episode-ordering service, or remote content API.

The production player architecture is implemented and covered by package tests
and generic tvOS compilation. Live stream interruption, reconnect, focus,
VoiceOver, Reduce Motion, and next-item transition scenarios remain explicit
runtime checks in the player validation matrix.
