import Foundation

public struct StateStore: Sendable {
    public let paths: RuntimePaths

    public init(paths: RuntimePaths = RuntimePaths()) {
        self.paths = paths
    }

    public func load() -> ControllerState {
        guard let data = try? Data(contentsOf: paths.stateFile) else {
            return ControllerState()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(ControllerState.self, from: data)) ?? ControllerState()
    }

    public func save(_ state: ControllerState) throws {
        let policy = PathPolicy(paths: paths)
        try policy.validateMutation(paths.stateFile)
        try FileManager.default.createDirectory(at: paths.stateRoot, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(state).write(to: paths.stateFile, options: .atomic)
    }
}
