import Foundation

public enum ThemeFamily: String, CaseIterable, Codable, Sendable {
    case softParchment = "soft-parchment"
    case galleryPlaster = "gallery-plaster"
    case mineralPaper = "mineral-paper"
    case blueHour = "blue-hour"

    public var name: String {
        switch self {
        case .softParchment: "Soft Parchment"
        case .galleryPlaster: "Gallery Plaster"
        case .mineralPaper: "Mineral Paper"
        case .blueHour: "Blue Hour"
        }
    }

    public init?(nameOrSlug value: String) {
        if let family = Self(rawValue: value.lowercased()) {
            self = family
            return
        }
        guard let family = Self.allCases.first(where: {
            $0.name.compare(value, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else { return nil }
        self = family
    }
}

public enum ApplyStatus: String, Codable, CaseIterable, Sendable {
    case appliedLive = "applied-live"
    case nextLaunch = "next-launch"
    case reloadRequired = "reload-required"
    case restartRequired = "restart-required"
    case unsupported
    case failed

    public var label: String {
        switch self {
        case .appliedLive: "Applied live"
        case .nextLaunch: "Next launch"
        case .reloadRequired: "Reload required"
        case .restartRequired: "Restart required"
        case .unsupported: "Unsupported"
        case .failed: "Failed"
        }
    }
}

public struct AdapterResult: Codable, Equatable, Sendable {
    public let adapterID: String
    public let adapterName: String
    public let status: ApplyStatus
    public let detail: String

    public init(adapterID: String, adapterName: String, status: ApplyStatus, detail: String) {
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.status = status
        self.detail = detail
    }
}

public struct ControllerState: Codable, Equatable, Sendable {
    public var selectedFamily: ThemeFamily
    public var lastAppliedAt: Date?
    public var results: [AdapterResult]

    public init(
        selectedFamily: ThemeFamily = .galleryPlaster,
        lastAppliedAt: Date? = nil,
        results: [AdapterResult] = []
    ) {
        self.selectedFamily = selectedFamily
        self.lastAppliedAt = lastAppliedAt
        self.results = results
    }
}

public enum SystemAppearance: String, Codable, Sendable {
    case light
    case dark
}
