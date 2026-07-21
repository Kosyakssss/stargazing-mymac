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

        let results = ThemeEngine(paths: paths).apply(.mineralPaper)
        precondition(results.contains(where: { $0.status == .failed }))
        print("Stargazing MyMac self-test passed")
    }
}
