import Foundation

public struct ThemeEngine: Sendable {
    public let paths: RuntimePaths
    public let adapters: [any ThemeAdapter]
    public let stateStore: StateStore

    public init(
        paths: RuntimePaths = RuntimePaths(),
        adapters: [any ThemeAdapter] = AdapterCatalog.standard()
    ) {
        self.paths = paths
        self.adapters = adapters
        stateStore = StateStore(paths: paths)
    }

    @discardableResult
    public func apply(_ family: ThemeFamily) -> [AdapterResult] {
        var state = stateStore.load()
        state.selectedFamily = family
        try? stateStore.save(state)

        let context = AdapterContext(family: family, paths: paths)
        let manager = FileManager.default
        let missingByAdapter = Dictionary(uniqueKeysWithValues: adapters.map { adapter in
            let missing = adapter.requiredSources(in: context).filter { !manager.fileExists(atPath: $0.path) }
            return (adapter.id, missing)
        })
        let allMissing = missingByAdapter.values.flatMap { $0 }

        let results: [AdapterResult]
        if !allMissing.isEmpty {
            results = adapters.map { adapter in
                let missing = missingByAdapter[adapter.id] ?? []
                if adapter.id == "helium" {
                    return adapter.apply(in: context)
                }
                if !missing.isEmpty {
                    let relative = missing.map { relativePath($0, under: paths.portRoot) }.joined(separator: ", ")
                    return AdapterResult(
                        adapterID: adapter.id,
                        adapterName: adapter.name,
                        status: .failed,
                        detail: "Missing canonical port: \(relative)"
                    )
                }
                return AdapterResult(
                    adapterID: adapter.id,
                    adapterName: adapter.name,
                    status: .failed,
                    detail: "Not applied because canonical port preflight failed for another adapter."
                )
            }
        } else {
            results = adapters.map { $0.apply(in: context) }
        }

        state.results = results
        state.lastAppliedAt = Date()
        try? stateStore.save(state)
        return results
    }

    public func status() -> ControllerState {
        stateStore.load()
    }

    private func relativePath(_ url: URL, under root: URL) -> String {
        let prefix = root.standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
    }
}
