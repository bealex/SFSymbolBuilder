//
//  SFBuilderApp.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import SwiftUI

@main
struct SFBuilderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
            // Get the directory where the original file is located
            let directory = url.deletingLastPathComponent()

            // Create configuration for the conversion
            let configuration = SFSymbol.Configuration(fileUrl: url)

            // Build and save the SF Symbol to the same directory
            try SFSymbolBuilder.build(from: configuration, to: directory)

            print("Successfully converted: \(url.lastPathComponent)")
            print("Output saved to: \(directory.path)")

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
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
