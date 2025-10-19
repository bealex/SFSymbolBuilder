//
//  AppDelegate.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            SFBuilderApp.handleDroppedFiles(urls: urls)
        }
    }
}
