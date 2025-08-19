// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    
    var bounds: ClosedRange<Double> = 0...1
    var steps: Double?
    
    @State private var lowerInternal: Double = 0
    @State private var upperInternal: Double = 1
    
    private let knobSize: CGFloat = 48
    private let trackHeight: CGFloat = 8
    
    @State private var draggingLower: Bool = false
    @State private var draggingUpper: Bool = false
    
    private var tintColor: Color = .accentColor
    
    init(
        _ range: Binding<ClosedRange<Double>>,
        in bounds: ClosedRange<Double> = 0...1
    ) {
        self._range = range
        self.bounds = bounds
    }
    
    init(
        _ range: Binding<ClosedRange<Double>>,
        in bounds: ClosedRange<Double> = 0...1,
        steps: Double
    ) {
        self._range = range
        self.bounds = bounds
        self.steps = steps
    }
    
    public var body: some View {
        VStack {
            Text("Internal values from \(lowerInternal) to \(upperInternal)")
            
            GeometryReader { geo in
                let fullWidth = geo.size.width
                let halfWidth = geo.size.width / 2
                
                ZStack {
                    Capsule()
                        .fill(.clear)
                        .frame(height: knobSize)
                    
                    Capsule()
                        .fill(.gray)
                        .frame(height: trackHeight)
                    
                    Capsule()
                        .fill(tintColor)
                        .frame(width: upperInternal - lowerInternal + knobSize, height: trackHeight)
                        .offset(x: (upperInternal + lowerInternal) / 2)
                        .animation(.easeInOut, value: range)
                    
                    Group {
                        if #available(iOS 26.0, macOS 26.0, *) {
                            Capsule().fill(draggingLower ? .clear : .primary.opacity(1))
                                .contentShape(Capsule())
                                .glassEffect(draggingLower ? .regular.interactive() : .identity)
                                .animation(.bouncy, value: draggingLower)
                        } else {
                            Capsule().fill(.primary.opacity(1))
                        }
                    }
                    .frame(width: knobSize, height: knobSize / 1.5)
                    .animation(.easeInOut, value: lowerInternal)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                draggingLower = true
                                let translation = value.translation.width
                                let newLower = max(-halfWidth + knobSize / 2, min(lowerInternal + translation, halfWidth - 1.5 * knobSize))
                                
                                lowerInternal = lowerStep(newLower, width: fullWidth)
                                let lower = lowerToValue(lowerInternal, width: fullWidth)
                                var upper = range.upperBound
                                if upper + (steps ?? 0) <= lower {
                                    let newUpper = max(-halfWidth + 1.5 * knobSize, min(upperInternal + translation, halfWidth - knobSize / 2))
                                    upperInternal = upperStep(newUpper, width: fullWidth)
                                    upper = upperToValue(upperInternal, width: fullWidth)
                                }
                                if lower < upper {
                                    range = lower...upper
                                } else {
                                    range = upper...lower
                                }
                            }
                            .onEnded { _ in
                                draggingLower = false
                            }
                    )
                    .offset(x: lowerInternal)
                    
                    Group {
                        if #available(iOS 26.0, macOS 26.0, *) {
                            Capsule().fill(draggingUpper ? .clear : .primary.opacity(1))
                                .contentShape(Capsule())
                                .glassEffect(draggingUpper ? .regular.interactive() : .identity)
                                .animation(.bouncy, value: draggingUpper)
                        } else {
                            Capsule().fill(.primary.opacity(1))
                        }
                    }
                    .frame(width: knobSize, height: knobSize / 1.5)
                    .animation(.easeInOut, value: upperInternal)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                draggingUpper = true
                                let translation = value.translation.width
                                let newUpper = max(-halfWidth + 1.5 * knobSize, min(upperInternal + translation, halfWidth - knobSize / 2))
                                
                                upperInternal = upperStep(newUpper, width: fullWidth)
                                let upper = upperToValue(upperInternal, width: fullWidth)
                                var lower = range.lowerBound
                                if lower - (steps ?? 0) >= upper {
                                    let newLower = max(-halfWidth + knobSize / 2, min(lowerInternal + translation, halfWidth - 1.5 * knobSize))
                                    lowerInternal = lowerStep(newLower, width: fullWidth)
                                    lower = lowerToValue(lowerInternal, width: fullWidth)
                                }
                                if lower < upper {
                                    range = lower...upper
                                } else {
                                    range = upper...lower
                                }
                            }
                            .onEnded { _ in
                                draggingUpper = false
                            }
                    )
                    .offset(x: upperInternal)
                    
                }
                .onAppear {
                    lowerInternal = lowerToPosition(range.lowerBound, width: geo.size.width)
                    upperInternal = upperToPosition(range.upperBound, width: geo.size.width)
                }
            }
        }
        .padding()
    }
    
    private func lowerToValue(_ pos: CGFloat, width: CGFloat) -> Double {
        let percentage = (pos + (width / 2) - knobSize / 2) / (width - 2 * knobSize)
        return bounds.lowerBound - (percentage * bounds.lowerBound) + (percentage * bounds.upperBound)
    }
    
    private func upperToValue(_ pos: CGFloat, width: CGFloat) -> Double {
        let percentage = (pos + (width / 2) - 1.5 * knobSize) / (width - 2 * knobSize)
        return bounds.lowerBound - (percentage * bounds.lowerBound) + (percentage * bounds.upperBound)
    }
    
    private func lowerStep(_ pos: CGFloat, width: CGFloat) -> CGFloat {
        guard let steps else { return pos }
        
        let externalSpan = bounds.upperBound - bounds.lowerBound
        let internalSpan = width - 2 * knobSize
        
        // how many pixels correspond to one step
        let pixelsPerStep = (steps / externalSpan) * internalSpan
        
        // snap relative to lower knob’s offset
        let adjusted = pos + (width / 2 - knobSize / 2)
        let snapped = (adjusted / pixelsPerStep).rounded() * pixelsPerStep
        return snapped - (width / 2 - knobSize / 2)
    }

    private func upperStep(_ pos: CGFloat, width: CGFloat) -> CGFloat {
        guard let steps else { return pos }
        
        let externalSpan = bounds.upperBound - bounds.lowerBound
        let internalSpan = width - 2 * knobSize
        
        let pixelsPerStep = (steps / externalSpan) * internalSpan
        
        // snap relative to upper knob’s offset
        let adjusted = pos + (width / 2 - 1.5 * knobSize)
        let snapped = (adjusted / pixelsPerStep).rounded() * pixelsPerStep
        return snapped - (width / 2 - 1.5 * knobSize)
    }
    
    private func lowerToPosition(_ value: Double, width: CGFloat) -> CGFloat {
        let percentage = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percentage * (width - 2 * knobSize) - (width / 2 - knobSize / 2)
    }

    private func upperToPosition(_ value: Double, width: CGFloat) -> CGFloat {
        let percentage = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percentage * (width - 2 * knobSize) - (width / 2 - 1.5 * knobSize)
    }
    
    func tint(_ color: Color) -> RangeSlider {
        var copy = self
        copy.tintColor = color
        return copy
    }
}
