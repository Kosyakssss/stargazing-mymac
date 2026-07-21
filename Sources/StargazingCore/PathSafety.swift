import Foundation

public enum PathSafetyError: LocalizedError, Equatable, Sendable {
    case outsideHome(String)
    case sourceEscapesPortRoot(String)

    public var errorDescription: String? {
        switch self {
        case .outsideHome(let path): "Refusing a path outside the home directory: \(path)"
        case .sourceEscapesPortRoot(let path): "Theme source escapes the port root: \(path)"
        }
    }
}

public struct PathPolicy: Sendable {
    public let paths: RuntimePaths

    public init(paths: RuntimePaths) { self.paths = paths }

    public func validateMutation(_ candidate: URL) throws {
        let resolved = resolveExistingAncestors(candidate)
        let home = paths.home.resolvingSymlinksInPath().standardizedFileURL
        guard Self.contains(home, resolved) else {
            throw PathSafetyError.outsideHome(resolved.path)
        }
    }

    public func validatePortSource(_ source: URL) throws {
        let root = paths.portRoot.resolvingSymlinksInPath().standardizedFileURL
        let resolved = source.resolvingSymlinksInPath().standardizedFileURL
        guard Self.contains(root, resolved) else {
            throw PathSafetyError.sourceEscapesPortRoot(resolved.path)
        }
    }

    public func resolveExistingAncestors(_ url: URL) -> URL {
        let manager = FileManager.default
        var cursor = url.standardizedFileURL
        var suffix: [String] = []
        while cursor.path != "/", !manager.fileExists(atPath: cursor.path) {
            suffix.insert(cursor.lastPathComponent, at: 0)
            cursor.deleteLastPathComponent()
        }
        var resolved = cursor.resolvingSymlinksInPath().standardizedFileURL
        for component in suffix { resolved.appendPathComponent(component) }
        return resolved.standardizedFileURL
    }

    public static func contains(_ root: URL, _ candidate: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let candidatePath = candidate.standardizedFileURL.path
        return candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/")
    }
}

public struct SafeFileInstaller: Sendable {
    private let policy: PathPolicy

    public init(paths: RuntimePaths) { policy = PathPolicy(paths: paths) }

    @discardableResult
    public func install(source: URL, destination: URL, adapterID _: String, family _: ThemeFamily) throws -> URL {
        try policy.validatePortSource(source)
        try policy.validateMutation(destination)
        let manager = FileManager.default
        try manager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if (try? destination.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
            try manager.removeItem(at: destination)
        }
        try Data(contentsOf: source).write(to: destination, options: .atomic)
        return destination
    }
}
