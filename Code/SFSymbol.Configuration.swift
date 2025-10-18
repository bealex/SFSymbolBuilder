//
//  SFSymbol.Configuration.swift
//  SFBuilder
//
//  Created by Alexander Babaev on 10/18/25.
//

import Foundation

public struct SFSymbol {
    public struct Configuration: Sendable {
        public var fileUrl: URL

        public var scale: CGFloat = 1
        public var widthScale: CGFloat = 1

        public var dx: CGFloat = 0
        public var dy: CGFloat = 0
    }
}
