# Stargazing MyMac agent rules

- Keep family selection independent from macOS light/dark appearance.
- Install every generated variant in the supported app's normal theme directory.
- Switch themes by changing a narrow selector in the app's real config. Do not create runtime theme overlays.
- Direct edits to tracked Dotfiles selectors are intentional. Preserve all unrelated config content.
- Supported integrations are macOS wallpaper, Ghostty, Helix, Yazi, btop, Starship, Pi, Feedreader, Obsidian, and experimental Helium.
- Do not add Fish, Bat, Telegram, fzf, tmux, or Neovim integrations.
- Never edit Chromium or Helium profile `Preferences` files directly.
- Keep primary text mapped to Stargazing primary text. Muted and faint colors remain supporting and expendable roles.
- Use no third-party Swift dependencies.
- Run `scripts/test.sh` and `scripts/build-app.sh` before finishing.
