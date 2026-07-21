import Foundation

public struct RuntimePaths: Sendable {
    public let home: URL
    public let portRoot: URL
    public let configRoot: URL
    public let stateRoot: URL
    public let dotfilesRoot: URL
    public let notesRoot: URL
    public let projectsRoot: URL
    public let piRoot: URL
    public let feedreaderRoot: URL
    public let wallpaperRoot: URL
    public let applySystemWallpaper: Bool

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.home = home.standardizedFileURL
        portRoot = Self.url(
            environment["STARGAZING_PORT_ROOT"],
            fallback: home.appendingPathComponent("Code/stargazing-mymac")
        )
        configRoot = Self.url(
            environment["XDG_CONFIG_HOME"],
            fallback: home.appendingPathComponent(".config")
        )
        stateRoot = Self.url(
            environment["XDG_STATE_HOME"].map { "\($0)/stargazing-mymac" },
            fallback: home.appendingPathComponent(".local/state/stargazing-mymac")
        )
        dotfilesRoot = home.appendingPathComponent("Dotfiles").standardizedFileURL
        notesRoot = home.appendingPathComponent("Notes").standardizedFileURL
        projectsRoot = home.appendingPathComponent("Projects").standardizedFileURL
        piRoot = home.appendingPathComponent(".pi").standardizedFileURL
        feedreaderRoot = Self.url(
            environment["STARGAZING_FEEDREADER_ROOT"],
            fallback: home.appendingPathComponent("Code/feedreader")
        )
        wallpaperRoot = Self.url(
            environment["STARGAZING_WALLPAPER_ROOT"],
            fallback: home.appendingPathComponent("Lib-rary/Wallpapers/Stargazing")
        )
        applySystemWallpaper = environment["STARGAZING_SKIP_SYSTEM_WALLPAPER"] != "1"
    }

    public var stateFile: URL { stateRoot.appendingPathComponent("state.json") }

    public func port(_ relativePath: String) -> URL {
        portRoot
            .appendingPathComponent("ports", isDirectory: true)
            .appendingPathComponent(relativePath)
            .standardizedFileURL
    }

    private static func url(_ value: String?, fallback: URL) -> URL {
        guard let value, !value.isEmpty else { return fallback.standardizedFileURL }
        let expanded = NSString(string: value).expandingTildeInPath
        return URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
    }
}
