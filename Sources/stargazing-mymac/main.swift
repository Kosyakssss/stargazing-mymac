import Darwin
import Foundation
import StargazingCore

@main
struct StargazingCLI {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            usage(exitCode: 64)
        }

        switch command {
        case "list":
            list()
        case "apply":
            apply(Array(arguments.dropFirst()))
        case "status":
            status()
        case "appearance":
            appearance(Array(arguments.dropFirst()))
        case "help", "--help", "-h":
            usage(exitCode: 0)
        default:
            writeError("Unknown command: \(command)")
            usage(exitCode: 64)
        }
    }

    private static func list() {
        for family in ThemeFamily.allCases {
            print("\(family.rawValue)\t\(family.name)")
        }
    }

    private static func apply(_ arguments: [String]) {
        guard arguments.count == 1, let family = ThemeFamily(nameOrSlug: arguments[0]) else {
            writeError("apply requires one family name or slug")
            usage(exitCode: 64)
        }

        let results = ThemeEngine().apply(family)
        print("Selected \(family.name)")
        printResults(results)
        if results.contains(where: { $0.status == .failed }) {
            Darwin.exit(1)
        }
    }

    private static func status() {
        let state = ThemeEngine().status()
        print("Family: \(state.selectedFamily.name) (\(state.selectedFamily.rawValue))")
        if let date = state.lastAppliedAt {
            print("Last applied: \(ISO8601DateFormatter().string(from: date))")
        } else {
            print("Last applied: never")
        }
        printResults(state.results)
        do {
            print("Appearance: \(try AppearanceController().current().rawValue)")
        } catch {
            print("Appearance: unavailable (\(error.localizedDescription))")
        }
    }

    private static func appearance(_ arguments: [String]) {
        let controller = AppearanceController()
        let action = arguments.first ?? "status"
        guard arguments.count <= 1 else {
            writeError("appearance accepts at most one action")
            usage(exitCode: 64)
        }

        do {
            let result: SystemAppearance
            switch action {
            case "status": result = try controller.current()
            case "light": result = try controller.set(.light)
            case "dark": result = try controller.set(.dark)
            case "toggle": result = try controller.toggle()
            default:
                writeError("Unknown appearance action: \(action)")
                usage(exitCode: 64)
            }
            if action != "status" {
                _ = ThemeEngine().apply(ThemeEngine().status().selectedFamily)
            }
            print(result.rawValue)
        } catch {
            writeError(error.localizedDescription)
            Darwin.exit(1)
        }
    }

    private static func printResults(_ results: [AdapterResult]) {
        if results.isEmpty {
            print("Adapters: no results")
            return
        }
        for result in results {
            print("\(result.adapterName)\t\(result.status.rawValue)\t\(result.detail)")
        }
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }

    private static func usage(exitCode: Int32) -> Never {
        let text = """
        Usage:
          stargazing-mymac list
          stargazing-mymac apply <family-name-or-slug>
          stargazing-mymac status
          stargazing-mymac appearance [status|light|dark|toggle]
        """
        let handle = exitCode == 0 ? FileHandle.standardOutput : FileHandle.standardError
        handle.write(Data((text + "\n").utf8))
        Darwin.exit(exitCode)
    }
}
