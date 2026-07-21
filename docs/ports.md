# Application ports

Run `python3 scripts/generate_ports.py` after generating the canonical palette. All files under `ports/` are generated here. The canonical palette repository contains no application ports.

| Port | Installed location | Selector |
|---|---|---|
| macOS wallpaper | `~/Lib-rary/Wallpapers/Stargazing/` | Selected family HEIC on every display |
| Ghostty | `~/.config/ghostty/themes/` | Paired theme names in `ghostty/config` |
| Helix (master) | `~/.config/helix/themes/` | `[theme]` light/dark pair in `helix/config.toml` |
| Yazi | `~/.config/yazi/flavors/` | `[flavor]` in `yazi/theme.toml` |
| btop | `~/.config/btop/themes/` | `color_theme` in `btop/btop.conf` |
| Starship | Palette tables in `~/.config/starship.toml` | Root `palette` key |
| Pi | `~/.pi/agent/themes/` | `theme` in Pi settings |
| Feedreader | `~/Code/feedreader/data/config.json` | `theme` key; open tabs poll for changes |
| Obsidian | Per-family snippets in each vault | `enabledCssSnippets` in appearance settings |
| Helium | Helium Application Support | Manual experimental loading |

Each conventional app receives eight static variants: four families times light and dark. Wallpaper receives four HEIC containers; each embeds its light image at index 0, its dark image at index 1, and Apple `apple_desktop:apr` metadata so macOS follows system appearance. The Helix selector follows the current master documentation: `[theme]` names a light and dark variant, and Helix chooses between them when the terminal reports its preference through mode 2031. Other mode-specific apps use their own supported selectors.

Set `STARGAZING_WALLPAPER_ROOT` to test or install elsewhere. Set `STARGAZING_SKIP_SYSTEM_WALLPAPER=1` to install the files without changing the current desktop picture.

Helix dark variants inherit their installed `stargazing_<family>_light` counterpart. Keep those names aligned with `HelixAdapter`; Helix falls back to its default theme when an inherited file cannot be found.

Feedreader serves theme CSS from disk for each request, so the switcher only updates its local config. Open tabs poll that config and replace their stylesheet within two seconds; the Bun process does not need a restart. Set `STARGAZING_FEEDREADER_ROOT` when the checkout is elsewhere.

Ghostty exposes an in-app config reload action but no supported external command that targets every window or tab. Helix also has no external RPC or signal for changing themes in every running editor. The switcher therefore reports Ghostty's reload shortcut and applies Helix on its next launch rather than injecting keystrokes or signals into active sessions.

Fish, Bat, Telegram, fzf, tmux, and Neovim are intentionally excluded because their theming is invisible, redundant with the terminal, or unused.

Helium outputs use Chromium's theme manifest format because Helium is Chromium-based, but they are branded and tested only as Helium ports. The switcher never edits Helium profile `Preferences`.

Template-derived files retain Flexoki attribution. Templates under `templates/` come from Flexoki's MIT-licensed ports or the user's prior Flexoki configuration.
