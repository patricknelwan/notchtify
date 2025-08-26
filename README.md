# Notchtify

Transform your MacBook’s notch into a Dynamic Island for Spotify.

Notchtify creates a floating, interactive island at the top of the screen that shows what’s playing on Spotify, with album art, status, and quick controls.

---

## Features

- Dynamic Island-style UI at the notch
- Spotify detection: running/playing status
- Live album artwork via Spotify Web API
- Playback controls: play/pause, next, previous
- Auto-expand on track change
- Hover enlarge (configurable)
- Lightweight SwiftUI + AppKit implementation

---

## Requirements

- macOS 13+ (Ventura or newer)
- Spotify desktop app
- Internet connection (for album art)

---

## Install

1) Clone the repo
- git clone https://github.com/patricknelwan/notchtify.git
- cd notchtify
- Open the project in Xcode and build

2) First launch
- Open Spotify desktop
- Launch Notchtify
- Grant Accessibility permissions if prompted
- Start playing music

---

## Configuration

Album art uses Spotify Web API credentials.

1) Create an app at Spotify Developer Dashboard
- https://developer.spotify.com/dashboard
- Create App → note Client ID and Client Secret

2) Configure the app
- Copy Config.plist.example to Config.plist
- Fill in SpotifyClientID and SpotifyClientSecret

3) Keep credentials private
- Config.plist is ignored by git
- If it was committed before, run:
  - git rm --cached Config.plist
  - git commit -m "Remove Config.plist from tracking"
  - git push

---

## Usage

- Click the island to expand/collapse
- Hover to enlarge the notch
- Use playback buttons (prev/play-pause/next)

---

## Project Structure

- NotchtifyApp.swift — App entry and window wiring
- ContentView.swift — Settings/control panel UI
- FloatingWindowManager.swift — Floating window at the notch
- SpotifyDynamicIsland.swift — Compact/expanded island views
- SpotifyManager.swift — Spotify state via AppleScript, UI state
- SpotifyWebAPIManager.swift — Token + album art fetching
- Config.plist.example — Template for secrets

---

## Development Notes

- SwiftUI for UI; AppKit for window management
- AppleScript reads Spotify state (track, artist, playing)
- Web API fetches album art (Client Credentials flow)
- Borderless floating window positioned at top center

Tip: On first app open with music already playing, album art may need a brief moment; the manager includes retries and delayed fetch on initial detection.

---

## Troubleshooting

Album art not showing
- Verify Config.plist credentials
- Check network connectivity
- Try switching tracks once to refresh metadata

Spotify not detected
- Ensure Spotify desktop app is running
- Restart both Spotify and Notchtify

Click issues on the island
- Ensure Accessibility permissions are granted
- Avoid other apps’ overlays covering the menu bar

---

## Contributing

- Fork → feature branch → PR
- Keep credentials out of git
- UI/UX improvements and bug fixes welcome

---

## ⚠️ Disclaimer

Notchtify is an independent project, not affiliated with or endorsed by Spotify AB or Apple Inc. Dynamic Island is a design by Apple Inc.
