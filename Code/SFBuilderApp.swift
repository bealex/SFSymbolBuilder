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
    static func handleDroppedFiles(urls: [URL]) {
        // Filter for SVG files only
        let svgFiles = urls.filter { $0.pathExtension.lowercased() == "svg" }
        
        guard !svgFiles.isEmpty else {
            print("No SVG files found in dropped items")
            showNotification(
                title: "No SVG Files",
                message: "Please drop SVG files to convert"
            )
            return
        }
        
        // Show directory picker for output location
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Output Directory"
        openPanel.message = "Select where to save \(svgFiles.count) converted SF \(svgFiles.count == 1 ? "Symbol" : "Symbols")"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        
        // Default to the directory of the first file
        if let firstFile = svgFiles.first {
            openPanel.directoryURL = firstFile.deletingLastPathComponent()
        }
        
        let response = openPanel.runModal()
        guard response == .OK, let outputDirectory = openPanel.url else {
            print("Save cancelled by user")
            return
        }
        
        // Start security-scoped access for the output directory
        guard outputDirectory.startAccessingSecurityScopedResource() else {
            print("Unable to access output directory")
            showNotification(
                title: "Access Denied",
                message: "Unable to access the selected directory"
            )
            return
        }
        defer { outputDirectory.stopAccessingSecurityScopedResource() }
        
        // Process all files
        var successCount = 0
        var failedFiles: [String] = []
        
        for url in svgFiles {
            guard url.startAccessingSecurityScopedResource() else {
                print("Unable to access file: \(url.path)")
                failedFiles.append(url.lastPathComponent)
                continue
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                // Create configuration for the conversion
                let configuration = SFSymbol.Configuration(fileUrl: url)
                
                // Build output filename
                let outputFilename = url.deletingPathExtension().lastPathComponent + ".sfSymbol.svg"
                let outputURL = outputDirectory.appendingPathComponent(outputFilename)
                
                // Build and save the SF Symbol
                try SFSymbolBuilder.build(from: configuration, to: outputURL)
                
                print("Successfully converted: \(url.lastPathComponent)")
                successCount += 1
            } catch {
                print("Error converting file \(url.lastPathComponent): \(error.localizedDescription)")
                failedFiles.append(url.lastPathComponent)
            }
        }
        
        // Show summary notification
        if successCount > 0 {
            let message: String
            if failedFiles.isEmpty {
                message = "Successfully converted \(successCount) \(successCount == 1 ? "file" : "files")"
            } else {
                message = "Converted \(successCount) \(successCount == 1 ? "file" : "files"). Failed: \(failedFiles.count)"
            }
            
            showNotification(
                title: "Conversion Complete",
                message: message
            )
        } else {
            showNotification(
                title: "Conversion Failed",
                message: "Failed to convert any files"
            )
        }
        
        if !failedFiles.isEmpty {
            print("Failed files: \(failedFiles.joined(separator: ", "))")
        }
    }
    
    // Keep single file handler for backward compatibility
    @MainActor
    static func handleDroppedFile(url: URL) {
        handleDroppedFiles(urls: [url])
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
