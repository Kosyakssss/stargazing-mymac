import Foundation
import StargazingCore

@main
struct SelfTest {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("stargazing-selftest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let paths = RuntimePaths(environment: [
            "STARGAZING_PORT_ROOT": root.path,
            "XDG_CONFIG_HOME": root.appendingPathComponent("config").path,
            "XDG_STATE_HOME": root.appendingPathComponent("state").path,
            "STARGAZING_WALLPAPER_ROOT": root.appendingPathComponent("wallpapers").path,
            "STARGAZING_SKIP_SYSTEM_WALLPAPER": "1",
        ], home: root)
        precondition(paths.stateRoot.path.hasSuffix("/state/stargazing-mymac"))

        let store = StateStore(paths: paths)
        let state = ControllerState(selectedFamily: .blueHour, lastAppliedAt: Date(timeIntervalSince1970: 1_700_000_000), results: [])
        try store.save(state)
        precondition(store.load() == state)
        precondition(!PathPolicy.contains(paths.configRoot, paths.stateFile))

        try PathPolicy(paths: paths).validateMutation(paths.dotfilesRoot.appendingPathComponent("allowed-selector"))
        do {
            try PathPolicy(paths: paths).validateMutation(URL(fileURLWithPath: "/var/stargazing-forbidden"))
            fatalError("Mutation outside the test home was not rejected")
        } catch PathSafetyError.outsideHome { }

        let helixPorts = root.appendingPathComponent("ports/helix", isDirectory: true)
        try FileManager.default.createDirectory(at: helixPorts, withIntermediateDirectories: true)
        for family in ThemeFamily.allCases {
            let slug = family.rawValue
            let installedSlug = slug.replacingOccurrences(of: "-", with: "_")
            try "\"ui.text\" = \"white\"\n".write(
                to: helixPorts.appendingPathComponent("\(slug)-light.toml"),
                atomically: true,
                encoding: .utf8
            )
            try "inherits = \"stargazing_\(installedSlug)_light\"\n".write(
                to: helixPorts.appendingPathComponent("\(slug)-dark.toml"),
                atomically: true,
                encoding: .utf8
            )
        }
        let helix = AdapterCatalog.standard().first { $0.id == "helix" }!
        let helixResult = helix.apply(in: AdapterContext(family: .galleryPlaster, paths: paths))
        precondition(helixResult.status == .nextLaunch)
        let helixConfig = try String(contentsOf: paths.configRoot.appendingPathComponent("helix/config.toml"), encoding: .utf8)
        precondition(helixConfig == "[theme]\ndark = \"stargazing_gallery_plaster_dark\"\nlight = \"stargazing_gallery_plaster_light\"\n")
        let darkTheme = try String(contentsOf: paths.configRoot.appendingPathComponent("helix/themes/stargazing_gallery_plaster_dark.toml"), encoding: .utf8)
        precondition(darkTheme == "inherits = \"stargazing_gallery_plaster_light\"\n")

        let feedreader = AdapterCatalog.standard().first { $0.id == "feedreader" }!
        let feedreaderResult = feedreader.apply(in: AdapterContext(family: .softParchment, paths: paths))
        precondition(feedreaderResult.status == .appliedLive)
        let feedreaderConfig = try Data(contentsOf: paths.feedreaderRoot.appendingPathComponent("data/config.json"))
        let feedreaderObject = try JSONSerialization.jsonObject(with: feedreaderConfig) as! [String: Any]
        precondition(feedreaderObject["theme"] as? String == "soft-parchment")

        let wallpaperPorts = root.appendingPathComponent("ports/wallpaper", isDirectory: true)
        try FileManager.default.createDirectory(at: wallpaperPorts, withIntermediateDirectories: true)
        for family in ThemeFamily.allCases {
            try Data("test-heic-\(family.rawValue)".utf8).write(to: wallpaperPorts.appendingPathComponent("\(family.rawValue).heic"))
        }
        let wallpaper = AdapterCatalog.standard().first { $0.id == "wallpaper" }!
        let wallpaperResult = wallpaper.apply(in: AdapterContext(family: .blueHour, paths: paths))
        precondition(wallpaperResult.status == .appliedLive)
        precondition(wallpaperResult.detail.contains("skipped by environment"))
        for family in ThemeFamily.allCases {
            let installed = paths.wallpaperRoot.appendingPathComponent("\(family.name).heic")
            precondition(FileManager.default.fileExists(atPath: installed.path))
        }

        let results = ThemeEngine(paths: paths).apply(.mineralPaper)
        precondition(results.contains(where: { $0.status == .failed }))
        print("Stargazing MyMac self-test passed")
    }
}
