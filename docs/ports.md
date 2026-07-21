# Application ports

Run `python3 scripts/generate_ports.py` after generating the canonical palette. All files under `ports/` are generated here. The canonical palette repository contains no application ports.

| Port | Installed location | Selector |
|---|---|---|
| Ghostty | `~/.config/ghostty/themes/` | Paired theme names in `ghostty/config` |
| Helix | `~/.config/helix/themes/` | Top-level `theme` in `helix/config.toml` |
| Yazi | `~/.config/yazi/flavors/` | `[flavor]` in `yazi/theme.toml` |
| btop | `~/.config/btop/themes/` | `color_theme` in `btop/btop.conf` |
| Starship | Palette tables in `~/.config/starship.toml` | Root `palette` key |
| Pi | `~/.pi/agent/themes/` | `theme` in Pi settings |
| Obsidian | Per-family snippets in each vault | `enabledCssSnippets` in appearance settings |
| Helium | Helium Application Support | Manual experimental loading |

Each conventional app receives eight static variants: four families times light and dark. Mode-specific apps get their selector rewritten after the separate macOS appearance toggle changes.

Fish, Bat, Telegram, fzf, tmux, and Neovim are intentionally excluded because their theming is invisible, redundant with the terminal, or unused.

Helium outputs use Chromium's theme manifest format because Helium is Chromium-based, but they are branded and tested only as Helium ports. The switcher never edits Helium profile `Preferences`.

Template-derived files retain Flexoki attribution. Templates under `templates/` come from Flexoki's MIT-licensed ports or the user's prior Flexoki configuration.
