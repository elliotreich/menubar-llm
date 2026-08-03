import Cocoa
import SwiftUI

/// Entry point for the menubar-only LLM chat application.
/// This app does not appear in the Dock and lives entirely in the system status bar.
@main
struct MenubarLLMApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Hide dock icon
        app.run()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var mouseEventMonitor: Any?
    var keyEventMonitor: Any?

    let viewModel = ChatViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        setupPopover()
        setupMouseEventMonitor()
        setupGlobalHotkey()
    }

    /// Creates a minimal main menu so Cmd+C, Cmd+V, Cmd+A work in the popover
    func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit MenubarLLM", action: #selector(quitApp), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        // Edit menu (Cmd+C, Cmd+V, Cmd+A)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu

        NSApplication.shared.mainMenu = mainMenu
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "bubble.left.and.bubble.right.fill",
                accessibilityDescription: "LLM Chat"
            )
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            // Right-click: show context menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(
                title: "Quit MenubarLLM",
                action: #selector(quitApp),
                keyEquivalent: "q"
            ))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil // Reset so left-click works again
        } else {
            togglePopover()
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient // Auto-close when clicking outside
        let rootView = ChatView().environmentObject(viewModel)
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            // Bring the app to the foreground so the popover can receive keyboard focus.
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Closes the popover when the user clicks anywhere outside of it.
    func setupMouseEventMonitor() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.popover.isShown {
                    self.popover.performClose(nil)
                }
            }
        }
    }

    /// Sets up a global hotkey listener (Cmd+Shift+Space) to toggle the popover.
    ///
    /// IMPORTANT: This uses `NSEvent.addGlobalMonitorForEvents` which requires
    /// Accessibility permissions. Go to System Settings > Privacy & Security > Accessibility
    /// and add this app if the hotkey does not work.
    func setupGlobalHotkey() {
        keyEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            // keyCode 49 is Space
            let hasCommand = event.modifierFlags.contains(.command)
            let hasShift = event.modifierFlags.contains(.shift)
            let isSpace = event.keyCode == 49

            if hasCommand && hasShift && isSpace {
                Task { @MainActor in
                    self.togglePopover()
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
