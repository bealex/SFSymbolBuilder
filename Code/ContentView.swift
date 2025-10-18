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
    private var selectedSvgUrl: URL?
    @State
    private var svgImage: NSImage?
    @State
    private var isFileImporterPresented = false
    @State
    private var isFileExporterPresented = false
    @State
    private var generatedSVGData: Data?

    var body: some View {
        VStack(spacing: 20) {
            // Image display area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if let svgImage {
                    Image(nsImage: svgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
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
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Open SVG File", systemImage: "folder.badge.plus")
                        .frame(minWidth: 200)
                }

                Button {
                    isFileExporterPresented = true
                } label: {
                    Label("Build SF Symbol", systemImage: "hammer.fill")
                        .frame(minWidth: 200)
                }
                .disabled(selectedSvgUrl == nil)

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [ .svg ], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedSvgUrl = url
                    loadSVG(from: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .fileExporter(
            isPresented: $isFileExporterPresented,
            document: SVGDocument(data: generatedSVGData),
            contentType: .svg,
            defaultFilename: selectedSvgUrl?.deletingPathExtension().appendingPathExtension("sf.svg").lastPathComponent
        ) { result in
            switch result {
            case .success(let url):
                print("File saved to: \(url.path)")
            case .failure(let error):
                print("Error saving file: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSVG(from url: URL) {
        guard url.startAccessingSecurityScopedResource(), let selectedSvgUrl else {
            print("Unable to access file")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let configuration = SFSymbol.Configuration(fileUrl: selectedSvgUrl)
            generatedSVGData = try SFSymbolBuilder.buildToData(from: configuration)
        } catch {
            print("Error converting a symbol: \(error)")
        }

        if let image = NSImage(contentsOf: url) {
            svgImage = image
        } else {
            print("Unable to load SVG file")
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
