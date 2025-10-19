//
//  ContentView.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State
    private var svgImages: [NSImage] = []
    @State
    private var isFileImporterPresented = false
    @State
    private var selectedFiles: [URL] = []

    var body: some View {
        VStack(spacing: 20) {
            // Image display area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if !svgImages.isEmpty {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: [ .init(.adaptive(minimum: 128, maximum: 128)) ], spacing: 10) {
                            ForEach(0 ..< svgImages.count, id: \.self) { imageIndex in
                                Image(nsImage: svgImages[imageIndex]).resizable().aspectRatio(contentMode: .fit)
                                    .border(.tertiary, width: 1)
                                    .padding(12)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No SVG selected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Click the button below to select an SVG file")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Button(
                    action: { isFileImporterPresented = true },
                    label: {
                        Label("Open SVG Files", systemImage: "folder.badge.plus")
                            .frame(minWidth: 200)
                    }
                )

                if !selectedFiles.isEmpty {
                    Button(
                        role: .destructive,
                        action: {
                            selectedFiles = []
                            svgImages = []
                        },
                        label: {
                            Label("Clear Selection", systemImage: "xmark.bin")
                                .frame(minWidth: 200)
                        }
                    )
                    .tint(Color.red)
                }

                Spacer()

                Button(
                    action: { SFBuilderApp.handleDroppedFiles(urls: selectedFiles) },
                    label: {
                        Label(
                            selectedFiles.count > 1
                                ? "Build \(selectedFiles.count) SF Symbols"
                                : "Build SF Symbol",
                            systemImage: "hammer.fill"
                        )
                        .frame(minWidth: 200)
                    }
                )
                .disabled(selectedFiles.isEmpty)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [ .svg ], allowsMultipleSelection: true) { result in
            switch result {
                case .success(let urls):
                    selectedFiles = urls
                    loadSVGs(from: urls)
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSVGs(from urls: [URL]) {
        svgImages = []
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("Unable to access file")
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            if let image = NSImage(contentsOf: url) {
                svgImages.append(image)
            }
        }
    }
}

// Document wrapper for file exporter
struct SVGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.svg] }
    
    var data: Data?
    
    init(data: Data?) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = data else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
