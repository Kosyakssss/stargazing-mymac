# Stargazing MyMac

A native macOS menu-bar controller for the four [Stargazing](https://github.com/Kosyakssss/Stargazing) families:

- Soft Parchment
- Gallery Plaster
- Mineral Paper
- Blue Hour

Family selection and macOS appearance are independent. The menu contains only the four families, a real Dark Mode toggle, and Quit.

This is entirely vibe-coded specifically for me, so if you want to use it - I suggest forking.

## Design

Every supported app gets all four light variants and all four dark variants in its normal theme directory. The switcher changes the selected theme name in the app's real config. It does not build runtime theme overlays.

## Build and test

```sh
python3 scripts/generate_ports.py
scripts/test.sh
scripts/build-app.sh
```

## Install

```sh
scripts/install.sh
```

This installs the app under `~/Applications`, the CLI under `~/.local/bin`, and a LaunchAgent under `~/Library/LaunchAgents`.

## CLI

```sh
stargazing-mymac list
stargazing-mymac apply gallery-plaster
stargazing-mymac status
stargazing-mymac appearance toggle
```

The generator reads the canonical palette from `~/Code/stargazing`; set `STARGAZING_PALETTE_ROOT` to override it. Set `STARGAZING_PORT_ROOT` at runtime only when this repository is elsewhere.
