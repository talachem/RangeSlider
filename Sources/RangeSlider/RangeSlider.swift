import SwiftUI

public struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    var bounds: ClosedRange<Double>
    var steps: Double?
    var useTicks: Bool
    var width: CGFloat
    
    private var numTicks: Int {
        guard let step = steps, step > 0 else { return 0 }
        return Int((bounds.upperBound - bounds.lowerBound) / step)
    }
    var ticks: [Tick]?
    
    private var halfwidth: CGFloat { width / 2 }
    private var endPoints: CGFloat { halfwidth - knobWidth }
    private var actualWidth: CGFloat { 2 * endPoints }
    private var valueSpan: Double { bounds.upperBound - bounds.lowerBound }
    
    @Namespace private var namespace
    
    #if os(macOS)
    private let draggingScale: CGFloat = 1.25
    private let scaleFactor: CGFloat = 1.1
    private let baseHeight: CGFloat = 20
    private let baseWidth: CGFloat = 30
    
    @State private var knobHeight: CGFloat = 20
    @State private var knobWidth: CGFloat = 30
    #else
    private let draggingScale: CGFloat = 1.25
    private let scaleFactor: CGFloat = 1.1
    private let baseHeight: CGFloat = 30
    private let baseWidth: CGFloat = 40
    
    @State private var knobHeight: CGFloat = 30
    @State private var knobWidth: CGFloat = 40
    #endif
    private let trackHeight: CGFloat = 6
    private let tickHeight: CGFloat = 8
    
    @State private var draggingLower: Bool = false
    @State private var draggingUpper: Bool = false
    
    private var tint = Color.accentColor
    
    public init(
        range: Binding<ClosedRange<Double>>,
        bounds: ClosedRange<Double> = 0...1,
        steps: Double? = nil,
        useTicks: Bool = false,
        width: CGFloat
    ) {
        self._range = range
        self.bounds = bounds
        self.steps = steps
        self.useTicks = useTicks
        self.width = width
    }
    
    public var body: some View {
        VStack {
            ZStack {
                Capsule()
                    .fill(.gray.opacity(0.25))
                    .frame(height: trackHeight)
                
                Capsule()
                    .fill(tint)
                    .frame(
                        width: valueToPixels(range.upperBound - range.lowerBound) + 2 * knobWidth * (range.upperBound - range.lowerBound) / (bounds.upperBound - bounds.lowerBound),
                        height: trackHeight
                    )
                    .offset(x: valueToPixels((range.upperBound + range.lowerBound)/2 - midValue))
                    .animation(.bouncy, value: range)
                
                if let ticks = ticks {
                    ForEach(ticks) { tick in
                        let xOffset = valueToPixels(tick.place - midValue)
                        Capsule()
                            .fill(tick.style.color)
                            .frame(width: tick.style.width, height: tick.style.height)
                            .offset(x: xOffset, y: tick.style.height)
                            .zIndex(-1)
                    }
                } else if let step = steps, useTicks {
                    ForEach(0...numTicks, id: \.self) { i in
                        let tickValue = bounds.lowerBound + Double(i) * step
                        let xOffset = valueToPixels(tickValue - midValue)
                        Capsule()
                            .fill(Color.gray)
                            .frame(width: 1.5, height: tickHeight / 2)
                            .offset(x: xOffset, y: tickHeight)
                            .zIndex(-1)
                    }
                }
                
                if #available(macOS 26.0, iOS 26.0, *) {
                    GlassEffectContainer(spacing: 20) {
                        handles
                    }
                } else {
                    handles
                }
                
            }
            .frame(width: width, height: baseHeight * scaleFactor)
        }
        .frame(width: width + baseWidth * scaleFactor)
    }
    
    private var midValue: Double {
        (bounds.lowerBound + bounds.upperBound) / 2
    }
    
    var handles: some View {
        HStack(spacing: 0) {
            // Lower knob
            knob(dragging: draggingLower, id: "lower")
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if #available(macOS 26.0, iOS 26.0, *) {
                                draggingLower = true
                                knobWidth = baseWidth / scaleFactor
                                knobHeight = baseHeight * scaleFactor
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    knobWidth = baseWidth
                                    knobHeight = baseHeight
                                }
                            }
                            
                            let deltaValue = pixelsToValue(value.translation.width)
                            let newLower = snap(range.lowerBound + deltaValue)
                            
                            if newLower <= range.upperBound {
                                range = min(max(bounds.lowerBound, newLower), range.upperBound)...range.upperBound
                            } else {
                                let newUpper = snap(range.upperBound + deltaValue)
                                
                                range = min(max(bounds.lowerBound, newLower), range.upperBound)...max(min(bounds.upperBound, newUpper), bounds.lowerBound)
                            }
                        }
                        .onEnded { _ in
                            draggingLower = false
                            knobWidth = baseWidth
                            knobHeight = baseHeight
                        }
                )
                .offset(x: valueToPixels(range.lowerBound - midValue))
            
            // Upper knob
            knob(dragging: draggingUpper, id: "upper")
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if #available(macOS 26.0, iOS 26.0, *) {
                                draggingUpper = true
                                knobWidth = baseWidth / scaleFactor
                                knobHeight = baseHeight * scaleFactor
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    knobWidth = baseWidth
                                    knobHeight = baseHeight
                                }
                            }
                            
                            let deltaValue = pixelsToValue(value.translation.width)
                            let newUpper = snap(range.upperBound + deltaValue)
                            
                            if newUpper >= range.lowerBound {
                                range = range.lowerBound...max(min(bounds.upperBound, newUpper), range.lowerBound)
                            } else {
                                let newLower = snap(range.lowerBound + deltaValue)
                                
                                range = max(newLower, bounds.lowerBound)...max(min(bounds.upperBound, newUpper), bounds.lowerBound)
                            }
                        }
                        .onEnded { _ in
                            draggingUpper = false
                            knobWidth = baseWidth
                            knobHeight = baseHeight
                        }
                )
                .offset(x: valueToPixels(range.upperBound - midValue))
        }
    }
    
    func knob(dragging: Bool, id: String) -> some View {
        Group {
            if #available(macOS 26.0, iOS 26.0, *) {
                Capsule()
                    .fill(dragging ? .clear : .white)
                    .shadow(color: .gray.opacity(!dragging ? 0.25 : 0), radius: 8)
                    .contentShape(Capsule())
                    .frame(width: dragging ? knobWidth * draggingScale : baseWidth, height: dragging ? knobHeight * draggingScale : baseHeight)
                    .glassEffect(.regular.interactive(), in: .capsule)
//                    .glassEffectID(id, in: namespace)
                    .animation(.bouncy, value: dragging)
                    .animation(.bouncy, value: knobWidth)
            } else {
                Capsule()
                    .fill(.white.opacity(1))
                    .frame(width: baseWidth * (dragging ? draggingScale : 1), height: baseHeight * (dragging ? draggingScale : 1))
                    .shadow(color: .gray.opacity(0.25), radius: 8)
            }
        }
    }
    
    func tint(_ color: Color) -> RangeSlider {
        var copy = self
        copy.tint = color
        return copy
    }
    
    func ticks(_ ticks: [Tick]) -> RangeSlider {
        var copy = self
        copy.useTicks = true
        copy.ticks = ticks
        return copy
    }
    
    // MARK: - Mapping
    
    private func valueToPixels(_ value: Double) -> Double {
        (value / valueSpan) * actualWidth
    }
    
    private func pixelsToValue(_ pixels: Double) -> Double {
        (pixels / actualWidth) * valueSpan
    }
    
//    private func snap(_ value: Double) -> Double {
//        guard let step = steps else { return value }
//        return (value / step).rounded() * step
//    }
    
    private func snap(_ value: Double) -> Double {
        var candidates: [Double] = []
        
        if let ticks {
            for tick in ticks where tick.snapTo {
                candidates.append(tick.place)
            }
            candidates.append(bounds.lowerBound)
            candidates.append(bounds.upperBound)
        } else if let step = steps {
            let stepped = (value / step).rounded() * step
            candidates.append(stepped)
            candidates.append(bounds.lowerBound)
            candidates.append(bounds.upperBound)
        }
        
        return candidates.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }
}

#Preview {
    @Previewable @State var myRange: ClosedRange<Double> = 1...50
    VStack {
        Text("External from \(myRange.lowerBound) to \(myRange.upperBound)")
        RangeSlider(
            range: $myRange,
            bounds: 1...60,
//            steps: 5,
            useTicks: true,
            width: 250
        )
        .ticks([
            Tick(place: 25, snapTo: true),
            Tick(place: 45, snapTo: true),
        ])
        .tint(.green)
        .padding(32)
    }
}
