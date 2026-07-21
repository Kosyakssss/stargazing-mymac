import AppKit
import Foundation

public struct AdapterContext: Sendable {
    public let family: ThemeFamily
    public let appearance: SystemAppearance
    public let paths: RuntimePaths
    public let installer: SafeFileInstaller

    public init(family: ThemeFamily, paths: RuntimePaths) {
        self.family = family
        appearance = (try? AppearanceController().current()) ?? .light
        self.paths = paths
        installer = SafeFileInstaller(paths: paths)
    }

    var mode: String { appearance.rawValue }
    var selectedSlug: String { "\(family.rawValue)-\(mode)" }
    var selectedUnderscore: String { selectedSlug.replacingOccurrences(of: "-", with: "_") }
    var selectedDisplayName: String { "Stargazing \(family.name) \(mode.capitalized)" }
    func source(_ relative: String) -> URL { paths.port(relative) }
}

public protocol ThemeAdapter: Sendable {
    var id: String { get }
    var name: String { get }
    func requiredSources(in context: AdapterContext) -> [URL]
    func apply(in context: AdapterContext) -> AdapterResult
}

private let variants: [(ThemeFamily, String)] = ThemeFamily.allCases.flatMap { family in
    ["light", "dark"].map { (family, $0) }
}

private func result(_ adapter: any ThemeAdapter, _ status: ApplyStatus, _ detail: String) -> AdapterResult {
    AdapterResult(adapterID: adapter.id, adapterName: adapter.name, status: status, detail: detail)
}

private struct GhosttyAdapter: ThemeAdapter {
    let id = "ghostty"; let name = "Ghostty"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("ghostty/\($0.0.rawValue)-\($0.1)") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            for (family, mode) in variants {
                let display = "Stargazing \(family.name) \(mode.capitalized)"
                try c.installer.install(
                    source: c.source("ghostty/\(family.rawValue)-\(mode)"),
                    destination: c.paths.configRoot.appendingPathComponent("ghostty/themes/\(display)"),
                    adapterID: id,
                    family: c.family
                )
            }
            let config = c.paths.configRoot.appendingPathComponent("ghostty/config")
            var lines = readLines(config)
            lines.removeAll { line in
                let value = line.trimmingCharacters(in: .whitespaces)
                return value.hasPrefix("theme =") || value.contains("stargazing-mymac/active/ghostty.conf") || value == "# Mutable Stargazing paths are generated outside this public repository."
            }
            let selector = "theme = dark:Stargazing \(c.family.name) Dark, light:Stargazing \(c.family.name) Light"
            lines.insert(selector, at: min(10, lines.count))
            try writeLines(lines, to: config, paths: c.paths)
            return result(self, .reloadRequired, "Installed all eight themes and selected the \(c.family.name) light/dark pair. Reload with Command-Shift-,.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct HelixAdapter: ThemeAdapter {
    let id = "helix"; let name = "Helix"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("helix/\($0.0.rawValue)-\($0.1).toml") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            for (family, mode) in variants {
                let slug = "stargazing_\(family.rawValue.replacingOccurrences(of: "-", with: "_"))_\(mode)"
                try c.installer.install(
                    source: c.source("helix/\(family.rawValue)-\(mode).toml"),
                    destination: c.paths.configRoot.appendingPathComponent("helix/themes/\(slug).toml"),
                    adapterID: id,
                    family: c.family
                )
            }
            let config = c.paths.configRoot.appendingPathComponent("helix/config.toml")
            var text = (try? String(contentsOf: config, encoding: .utf8)) ?? ""
            text = removingTOMLTable("theme", from: text)
            var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            lines.removeAll { $0.trimmingCharacters(in: .whitespaces).hasPrefix("theme =") }
            let family = c.family.rawValue.replacingOccurrences(of: "-", with: "_")
            lines.insert(contentsOf: [
                "[theme]",
                "dark = \"stargazing_\(family)_dark\"",
                "light = \"stargazing_\(family)_light\"",
                "",
            ], at: 0)
            try writeLines(lines, to: config, paths: c.paths)
            return result(self, .nextLaunch, "Selected the Stargazing \(c.family.name) light/dark pair. Restart Helix; terminals with mode 2031 support will select the matching appearance.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct YaziAdapter: ThemeAdapter {
    let id = "yazi"; let name = "Yazi"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("yazi/\($0.0.rawValue)-\($0.1).yazi/flavor.toml") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            for (family, mode) in variants {
                let name = "stargazing-\(family.rawValue)-\(mode)"
                try c.installer.install(
                    source: c.source("yazi/\(family.rawValue)-\(mode).yazi/flavor.toml"),
                    destination: c.paths.configRoot.appendingPathComponent("yazi/flavors/\(name).yazi/flavor.toml"),
                    adapterID: id,
                    family: c.family
                )
            }
            let config = c.paths.configRoot.appendingPathComponent("yazi/theme.toml")
            let original = (try? String(contentsOf: config, encoding: .utf8)) ?? ""
            let remainder = removingTOMLTable("flavor", from: original).trimmingCharacters(in: .whitespacesAndNewlines)
            let selected = "stargazing-\(c.selectedSlug)"
            var text = "[flavor]\nlight = \"\(selected)\"\ndark = \"\(selected)\"\n"
            if !remainder.isEmpty { text += "\n\(remainder)\n" }
            try writeText(text, to: config, paths: c.paths)
            return result(self, .nextLaunch, "Selected \(selected) for both terminal color reports, so Yazi cannot choose the wrong mode.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct BtopAdapter: ThemeAdapter {
    let id = "btop"; let name = "btop"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("btop/\($0.0.rawValue)-\($0.1).theme") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            for (family, mode) in variants {
                let name = "stargazing-\(family.rawValue)-\(mode)"
                try c.installer.install(
                    source: c.source("btop/\(family.rawValue)-\(mode).theme"),
                    destination: c.paths.configRoot.appendingPathComponent("btop/themes/\(name).theme"),
                    adapterID: id,
                    family: c.family
                )
            }
            let config = c.paths.configRoot.appendingPathComponent("btop/btop.conf")
            var lines = readLines(config)
            let selector = "color_theme = \"stargazing-\(c.selectedSlug)\""
            if let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("color_theme =") }) {
                lines[index] = selector
            } else { lines.insert(selector, at: 0) }
            try writeLines(lines, to: config, paths: c.paths)
            return result(self, .nextLaunch, "Selected stargazing-\(c.selectedSlug) in btop.conf.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct StarshipAdapter: ThemeAdapter {
    let id = "starship"; let name = "Starship"
    private let begin = "# BEGIN STARGAZING PALETTES"
    private let end = "# END STARGAZING PALETTES"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("starship/\($0.0.rawValue)-\($0.1).toml") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            let config = c.paths.configRoot.appendingPathComponent("starship.toml")
            var text = (try? String(contentsOf: config, encoding: .utf8)) ?? ""
            text = removingMarkedBlock(begin: begin, end: end, from: text)
            var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            lines.removeAll { $0.trimmingCharacters(in: .whitespaces).hasPrefix("palette =") }
            let palette = "stargazing_\(c.selectedUnderscore)"
            lines.insert("palette = \"\(palette)\"", at: 0)
            let fragments = try variants.map { family, mode in
                try String(contentsOf: c.source("starship/\(family.rawValue)-\(mode).toml"), encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            }.joined(separator: "\n\n")
            let output = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                + "\n\n\(begin)\n\(fragments)\n\(end)\n"
            try writeText(output, to: config, paths: c.paths)
            return result(self, .appliedLive, "Selected \(palette); Starship uses it on the next prompt.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct PiAdapter: ThemeAdapter {
    let id = "pi"; let name = "Pi"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("pi/\($0.0.rawValue)-\($0.1).json") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            for (family, mode) in variants {
                let name = "stargazing-\(family.rawValue)-\(mode).json"
                try c.installer.install(
                    source: c.source("pi/\(family.rawValue)-\(mode).json"),
                    destination: c.paths.piRoot.appendingPathComponent("agent/themes/\(name)"),
                    adapterID: id,
                    family: c.family
                )
            }
            let settings = c.paths.piRoot.appendingPathComponent("agent/settings.json")
            var lines = readLines(settings)
            let selector = "  \"theme\": \"stargazing-\(c.selectedSlug)\","
            if let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("\"theme\":") }) {
                lines[index] = selector
            } else {
                lines.insert(selector, at: min(1, lines.count))
            }
            try writeLines(lines, to: settings, paths: c.paths)
            return result(self, .appliedLive, "Selected stargazing-\(c.selectedSlug); Pi hot-reloads the theme.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct FeedreaderAdapter: ThemeAdapter {
    let id = "feedreader"; let name = "Feedreader"

    func requiredSources(in _: AdapterContext) -> [URL] { [] }

    func apply(in c: AdapterContext) -> AdapterResult {
        let config = c.paths.feedreaderRoot.appendingPathComponent("data/config.json")
        do {
            var object: [String: Any] = [:]
            if let data = try? Data(contentsOf: config),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                object = existing
            }
            object["theme"] = c.family.rawValue
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            try writeData(data + Data("\n".utf8), to: config, paths: c.paths)
            return result(self, .appliedLive, "Selected Stargazing \(c.family.name); open Feedreader tabs pick it up within two seconds.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct ObsidianAdapter: ThemeAdapter {
    let id = "obsidian"; let name = "Obsidian"

    func requiredSources(in c: AdapterContext) -> [URL] {
        ThemeFamily.allCases.map { c.source("obsidian/\($0.rawValue).css") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        let vaults = discover(c.paths)
        guard !vaults.isEmpty else { return result(self, .unsupported, "No vaults found under ~/Notes or ~/Projects.") }
        do {
            for vault in vaults {
                for family in ThemeFamily.allCases {
                    try c.installer.install(
                        source: c.source("obsidian/\(family.rawValue).css"),
                        destination: vault.appendingPathComponent(".obsidian/snippets/stargazing-\(family.rawValue).css"),
                        adapterID: id,
                        family: c.family
                    )
                }
                try selectSnippet(c.family, in: vault, paths: c.paths)
            }
            return result(self, .appliedLive, "Selected stargazing-\(c.family.rawValue) in \(vaults.count) vaults; each snippet handles light and dark mode.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }

    private func selectSnippet(_ family: ThemeFamily, in vault: URL, paths: RuntimePaths) throws {
        let file = vault.appendingPathComponent(".obsidian/appearance.json")
        var object: [String: Any] = [:]
        if let data = try? Data(contentsOf: file), let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { object = existing }
        var snippets = object["enabledCssSnippets"] as? [String] ?? []
        snippets.removeAll { $0 == "stargazing" || $0.hasPrefix("stargazing-") }
        snippets.append("stargazing-\(family.rawValue)")
        object["enabledCssSnippets"] = snippets
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try writeData(data + Data("\n".utf8), to: file, paths: paths)
    }

    private func discover(_ p: RuntimePaths) -> [URL] {
        var found: [URL] = []
        for root in [p.notesRoot, p.projectsRoot] where FileManager.default.fileExists(atPath: root.path) {
            if FileManager.default.fileExists(atPath: root.appendingPathComponent(".obsidian").path) { found.append(root) }
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            while let url = enumerator.nextObject() as? URL {
                if FileManager.default.fileExists(atPath: url.appendingPathComponent(".obsidian").path) {
                    found.append(url)
                    enumerator.skipDescendants()
                }
            }
        }
        return Array(Set(found)).sorted { $0.path < $1.path }
    }
}

private enum WallpaperError: LocalizedError {
    case noDisplays

    var errorDescription: String? {
        switch self {
        case .noDisplays: "No connected displays are available."
        }
    }
}

private struct WallpaperAdapter: ThemeAdapter {
    let id = "wallpaper"; let name = "macOS Wallpaper"

    func requiredSources(in c: AdapterContext) -> [URL] {
        ThemeFamily.allCases.map { c.source("wallpaper/\($0.rawValue).heic") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            var selected: URL?
            for family in ThemeFamily.allCases {
                let destination = c.paths.wallpaperRoot.appendingPathComponent("\(family.name).heic")
                try c.installer.install(
                    source: c.source("wallpaper/\(family.rawValue).heic"),
                    destination: destination,
                    adapterID: id,
                    family: c.family
                )
                if family == c.family { selected = destination }
            }
            guard let selected else { return result(self, .failed, "Selected family wallpaper was not installed.") }
            guard c.paths.applySystemWallpaper else {
                return result(self, .appliedLive, "Installed all four appearance-aware HEIC files; system wallpaper change skipped by environment.")
            }
            let displayCount = try MainActor.assumeIsolated { () throws -> Int in
                let screens = NSScreen.screens
                guard !screens.isEmpty else { throw WallpaperError.noDisplays }
                let workspace = NSWorkspace.shared
                for screen in screens {
                    let options = workspace.desktopImageOptions(for: screen) ?? [:]
                    try workspace.setDesktopImageURL(selected, for: screen, options: options)
                }
                return screens.count
            }
            return result(self, .appliedLive, "Selected the \(c.family.name) appearance-aware wallpaper on \(displayCount) display\(displayCount == 1 ? "" : "s").")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private struct HeliumAdapter: ThemeAdapter {
    let id = "helium"; let name = "Helium"

    func requiredSources(in c: AdapterContext) -> [URL] {
        variants.map { c.source("helium/\($0.0.rawValue)-\($0.1).zip") }
    }

    func apply(in c: AdapterContext) -> AdapterResult {
        do {
            let root = c.paths.home.appendingPathComponent("Library/Application Support/net.imput.helium/Stargazing Themes")
            for (family, mode) in variants {
                try c.installer.install(
                    source: c.source("helium/\(family.rawValue)-\(mode).zip"),
                    destination: root.appendingPathComponent("Stargazing \(family.name) \(mode.capitalized).zip"),
                    adapterID: id,
                    family: c.family
                )
            }
            return result(self, .unsupported, "Installed all Helium packages in its Application Support directory. Helium still requires manual theme loading.")
        } catch { return result(self, .failed, error.localizedDescription) }
    }
}

private func readLines(_ url: URL) -> [String] {
    ((try? String(contentsOf: url, encoding: .utf8)) ?? "")
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map(String.init)
}

private func writeLines(_ lines: [String], to url: URL, paths: RuntimePaths) throws {
    try writeText(lines.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n", to: url, paths: paths)
}

private func writeText(_ text: String, to url: URL, paths: RuntimePaths) throws {
    try writeData(Data(text.utf8), to: url, paths: paths)
}

private func writeData(_ data: Data, to url: URL, paths: RuntimePaths) throws {
    let manager = FileManager.default
    let target = manager.fileExists(atPath: url.path) ? url.resolvingSymlinksInPath() : url
    try PathPolicy(paths: paths).validateMutation(target)
    try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: target, options: .atomic)
}

private func removingTOMLTable(_ table: String, from text: String) -> String {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var output: [String] = []
    var skipping = false
    for line in lines {
        let value = line.trimmingCharacters(in: .whitespaces)
        if value == "[\(table)]" { skipping = true; continue }
        if skipping, value.hasPrefix("["), value.hasSuffix("]") { skipping = false }
        if !skipping { output.append(line) }
    }
    return output.joined(separator: "\n")
}

private func removingMarkedBlock(begin: String, end: String, from text: String) -> String {
    guard let start = text.range(of: begin), let finish = text.range(of: end, range: start.upperBound..<text.endIndex) else { return text }
    return String(text[..<start.lowerBound]) + String(text[finish.upperBound...])
}

public enum AdapterCatalog {
    public static func standard() -> [any ThemeAdapter] {
        [WallpaperAdapter(), GhosttyAdapter(), HelixAdapter(), YaziAdapter(), BtopAdapter(), StarshipAdapter(), PiAdapter(), FeedreaderAdapter(), ObsidianAdapter(), HeliumAdapter()]
    }
}
