//
//  File.swift
//  RangeSlider
//
//  Created by Johannes Bilk on 21.08.25.
//

import Foundation
import SwiftUI

public struct Tick: Identifiable {
    public let id = UUID()
    var place: Double
    var style: TickStyle = .default
    var snapTo: Bool = false
}

public struct TickStyle {
    var color: Color
    var width: CGFloat
    var height: CGFloat
    
    static var `default`: TickStyle {
        TickStyle(color: .gray, width: 1.5, height: 8)
    }
}
