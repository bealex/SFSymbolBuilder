//
//  SFBuilderApp.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@main
struct SFBuilderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .handlesExternalEvents(matching: [])
    }
}

extension SFBuilderApp {
    @MainActor
    static func handleDroppedFile(url: URL) {
        guard url.pathExtension.lowercased() == "svg" else {
            print("Not an SVG file: \(url.path)")
            return
        }

        guard url.startAccessingSecurityScopedResource() else {
            print("Unable to access file: \(url.path)")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // Create configuration for the conversion
            let configuration = SFSymbol.Configuration(fileUrl: url)

            // Show save panel to let user choose where to save
            let savePanel = NSSavePanel()
            savePanel.title = "Save SF Symbol"
            savePanel.message = "Choose where to save the converted SF Symbol"
            savePanel.nameFieldStringValue = url.deletingPathExtension().lastPathComponent + ".svg"
            savePanel.allowedContentTypes = [ .svg ]
            savePanel.canCreateDirectories = true
            savePanel.directoryURL = url.deletingLastPathComponent()
            
            let response = savePanel.runModal()
            guard response == .OK, let saveURL = savePanel.url else {
                print("Save cancelled by user")
                return
            }

            // Build and save the SF Symbol to the chosen location
            try SFSymbolBuilder.build(from: configuration, to: saveURL.deletingLastPathComponent())

            print("Successfully converted: \(url.lastPathComponent)")
            print("Output saved to: \(saveURL.path)")

            // Show notification to user
            showNotification(
                title: "SF Symbol Created",
                message: "Converted \(url.lastPathComponent) successfully"
            )
        } catch {
            print("Error converting file: \(error.localizedDescription)")
            showNotification(
                title: "Conversion Failed",
                message: "Failed to convert \(url.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }

    private static func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // nil trigger means deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}
