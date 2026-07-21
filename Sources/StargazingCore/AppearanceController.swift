import Foundation

public enum AppearanceError: LocalizedError, Sendable {
    case commandFailed(String)
    case invalidResponse(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            if message.localizedCaseInsensitiveContains("not authorized") ||
                message.localizedCaseInsensitiveContains("-1743") {
                return "macOS denied Automation access. Allow this app to control System Events in System Settings → Privacy & Security → Automation."
            }
            return "Could not change macOS appearance: \(message)"
        case .invalidResponse(let response):
            return "System Events returned an unexpected appearance value: \(response)"
        }
    }
}

public struct AppearanceController: Sendable {
    public init() {}

    public func current() throws -> SystemAppearance {
        let output = try runAppleScript("tell application \"System Events\" to tell appearance preferences to get dark mode")
        switch output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true": return .dark
        case "false": return .light
        default: throw AppearanceError.invalidResponse(output)
        }
    }

    @discardableResult
    public func set(_ appearance: SystemAppearance) throws -> SystemAppearance {
        let value = appearance == .dark ? "true" : "false"
        _ = try runAppleScript("tell application \"System Events\" to tell appearance preferences to set dark mode to \(value)")
        return appearance
    }

    @discardableResult
    public func toggle() throws -> SystemAppearance {
        let target: SystemAppearance = try current() == .dark ? .light : .dark
        return try set(target)
    }

    private func runAppleScript(_ source: String) throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errorData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw AppearanceError.commandFailed(message.isEmpty ? "osascript exited with status \(process.terminationStatus)" : message)
        }
        return output
    }
}
