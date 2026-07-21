import AppKit
import StargazingCore
import SwiftUI

@main
struct StargazingMyMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = MenuModel()

    var body: some Scene {
        MenuBarExtra {
            ForEach(ThemeFamily.allCases, id: \.self) { family in
                Button {
                    model.select(family)
                } label: {
                    HStack {
                        Text(family.name)
                        if model.selectedFamily == family {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Toggle("Dark Mode", isOn: Binding(
                get: { model.isDark },
                set: { model.setDark($0) }
            ))

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Label("Stargazing MyMac", systemImage: "sparkles")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@MainActor
final class MenuModel: ObservableObject {
    @Published private(set) var selectedFamily: ThemeFamily
    @Published private(set) var isDark = false

    private let engine: ThemeEngine
    private let appearance: AppearanceController

    init(engine: ThemeEngine = ThemeEngine(), appearance: AppearanceController = AppearanceController()) {
        self.engine = engine
        self.appearance = appearance
        selectedFamily = engine.status().selectedFamily
        isDark = (try? appearance.current()) == .dark
    }

    func select(_ family: ThemeFamily) {
        selectedFamily = family
        _ = engine.apply(family)
    }

    func setDark(_ enabled: Bool) {
        do {
            isDark = try appearance.set(enabled ? .dark : .light) == .dark
            _ = engine.apply(selectedFamily)
        } catch {
            isDark = (try? appearance.current()) == .dark
        }
    }
}
