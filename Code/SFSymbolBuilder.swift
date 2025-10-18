//
//  SFSymbolBuilder.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import Foundation

extension Optional where Wrapped == String {
    var cgFloat: CGFloat {
        CGFloat(Double(self ?? "") ?? 0)
    }
}

extension _XML.Accessor {
    func cgFloat(_ attributeName: String) -> CGFloat {
        attributes[attributeName].cgFloat
    }
}

enum SFSymbolBuilder {
    enum Problem: Error {
        case cantParseXml
        case noViewBox
    }

    struct Template {
        struct Vertical {
            var center: CGFloat
            var height: CGFloat

            init(y1: CGFloat, y2: CGFloat) {
                center = (y1 + y2) / 2
                height = abs(y1 - y2)
            }
        }

        struct Horizontal {
            var center: CGFloat
            var width: CGFloat

            init(x1: CGFloat, x2: CGFloat) {
                center = (x1 + x2) / 2
                width = abs(x1 - x2)
            }
        }

        var vertical: Vertical = .init(y1: 0, y2: 0)

        var ultralight: Horizontal = .init(x1: 0, x2: 0)
        var regular: Horizontal = .init(x1: 0, x2: 0)
        var black: Horizontal = .init(x1: 0, x2: 0)
    }
    
    /// Builds the SF Symbol and returns the SVG data
    static func buildToData(from configuration: SFSymbol.Configuration) throws -> Data {
        let templateXml = try processSymbol(configuration: configuration)
        let result = try _XML.document(templateXml)
        guard let data = result.data(using: .utf8) else { throw CocoaError(.fileWriteUnknown) }
        
        return data
    }

    static func build(from configuration: SFSymbol.Configuration, to directory: URL) throws {
        let templateXml = try processSymbol(configuration: configuration)
        let result = try _XML.document(templateXml)
        let resultUrl = directory.appending(path: configuration.fileUrl.deletingPathExtension().appendingPathExtension("sf.svg").lastPathComponent)
        try result.write(to: resultUrl, atomically: true, encoding: .utf8)
        print("Done with \(configuration.fileUrl.absoluteString)")
    }
    
    private static func processSymbol(configuration: SFSymbol.Configuration) throws -> _XML.Accessor {
        var template: Template = .init()

        let templateUrl = Bundle.main.url(forResource: "template", withExtension: "svg")!
        let templateData = try Data(contentsOf: templateUrl)

        let templateXml = _XML.parse(templateData)
        guard case .singleElement = templateXml else { throw Problem.cantParseXml }

        let guideBaselineS = templateXml["svg"]["g#Guides"]["line#Baseline-S"]
        let guideCaplineS = templateXml["svg"]["g#Guides"]["line#Capline-S"]

        template.vertical = .init(y1: guideBaselineS.cgFloat("y1"), y2: guideCaplineS.cgFloat("y1"))

        let leftMarginUltralight = templateXml["svg"]["g#Guides"]["line#left-margin-Ultralight-S"]
        let rightMarginUltralight = templateXml["svg"]["g#Guides"]["line#right-margin-Ultralight-S"]
        template.ultralight = .init(x1: leftMarginUltralight.cgFloat("x1"), x2: rightMarginUltralight.cgFloat("x1"))

        let leftMarginRegular = templateXml["svg"]["g#Guides"]["line#left-margin-Regular-S"]
        let rightMarginRegular = templateXml["svg"]["g#Guides"]["line#right-margin-Regular-S"]
        template.regular = .init(x1: leftMarginRegular.cgFloat("x1"), x2: rightMarginRegular.cgFloat("x1"))

        let leftMarginBlack = templateXml["svg"]["g#Guides"]["line#left-margin-Black-S"]
        let rightMarginBlack = templateXml["svg"]["g#Guides"]["line#right-margin-Black-S"]
        template.black = .init(x1: leftMarginBlack.cgFloat("x1"), x2: rightMarginBlack.cgFloat("x1"))

        let data = try Data(contentsOf: configuration.fileUrl)

        let xml = _XML.parse(data)
        guard case .singleElement = xml else { throw Problem.cantParseXml }

        let viewBox = xml["svg"].attributes["viewBox"]?.components(separatedBy: " ").map { CGFloat(Double($0) ?? 0) } ?? []
        guard viewBox.count == 4 else { throw Problem.noViewBox }

        let centerX = viewBox[0] + viewBox[2] / 2
        let centerY = viewBox[1] + viewBox[3] / 2
        let height = viewBox[3]

        let finalTemplateXml = _XML.parse(templateData)
        let svgElement = finalTemplateXml["svg"]
        for accessor in xml["svg"]["path"] {
            guard case .singleElement = accessor else { continue }

            accessor.setA(attribute: nil, forKey: "clip-rule")
            accessor.setA(attribute: nil, forKey: "fill-rule")

            svgElement["g#Symbols"]["g#Black-S"].append(accessor: accessor)
            svgElement["g#Symbols"]["g#Regular-S"].append(accessor: accessor)
            svgElement["g#Symbols"]["g#Ultralight-S"].append(accessor: accessor)
        }

        let scale = template.vertical.height / height * configuration.scale
        let y = template.vertical.center - centerY * scale
        let ultralightX = template.ultralight.center - centerX * scale
        let regularX = template.regular.center - centerX * scale
        let blackX = template.black.center - centerX * scale
        svgElement["g#Symbols"]["g#Ultralight-S"].setA(attribute: "matrix(\(scale) 0 0 \(scale) \(ultralightX) \(y)", forKey: "transform")
        svgElement["g#Symbols"]["g#Regular-S"].setA(attribute: "matrix(\(scale) 0 0 \(scale) \(regularX) \(y)", forKey: "transform")
        svgElement["g#Symbols"]["g#Black-S"].setA(attribute: "matrix(\(scale) 0 0 \(scale) \(blackX) \(y)", forKey: "transform")

        let ultralightMarginLeft = template.ultralight.center - template.ultralight.width / 2 * configuration.widthScale
        let ultralightMarginRight = template.ultralight.center + template.ultralight.width / 2 * configuration.widthScale
        svgElement["g#Guides"]["line#left-margin-Ultralight-S"].setA(attribute: "\(ultralightMarginLeft)", forKey: "x1")
        svgElement["g#Guides"]["line#left-margin-Ultralight-S"].setA(attribute: "\(ultralightMarginLeft)", forKey: "x2")
        svgElement["g#Guides"]["line#right-margin-Ultralight-S"].setA(attribute: "\(ultralightMarginRight)", forKey: "x1")
        svgElement["g#Guides"]["line#right-margin-Ultralight-S"].setA(attribute: "\(ultralightMarginRight)", forKey: "x2")

        let regularMarginLeft = template.regular.center - template.regular.width / 2 * configuration.widthScale
        let regularMarginRight = template.regular.center + template.regular.width / 2 * configuration.widthScale
        svgElement["g#Guides"]["line#left-margin-Regular-S"].setA(attribute: "\(regularMarginLeft)", forKey: "x1")
        svgElement["g#Guides"]["line#left-margin-Regular-S"].setA(attribute: "\(regularMarginLeft)", forKey: "x2")
        svgElement["g#Guides"]["line#right-margin-Regular-S"].setA(attribute: "\(regularMarginRight)", forKey: "x1")
        svgElement["g#Guides"]["line#right-margin-Regular-S"].setA(attribute: "\(regularMarginRight)", forKey: "x2")

        let blackMarginLeft = template.black.center - template.black.width / 2 * configuration.widthScale
        let blackMarginRight = template.black.center + template.black.width / 2 * configuration.widthScale
        svgElement["g#Guides"]["line#left-margin-Black-S"].setA(attribute: "\(blackMarginLeft)", forKey: "x1")
        svgElement["g#Guides"]["line#left-margin-Black-S"].setA(attribute: "\(blackMarginLeft)", forKey: "x2")
        svgElement["g#Guides"]["line#right-margin-Black-S"].setA(attribute: "\(blackMarginRight)", forKey: "x1")
        svgElement["g#Guides"]["line#right-margin-Black-S"].setA(attribute: "\(blackMarginRight)", forKey: "x2")

        return finalTemplateXml
    }
}
