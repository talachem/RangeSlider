# Double Range Slider

Range Sliders are dime a dozen out there. This one works with macOS/iOS 26 in the "glass effect" style. I still don't understand enough of this to make is look as native as I hoped.

## Usage

It's super simple, define a state variable of type closed double range. Because I didn't want to use a geometry reader, one needs to provide a width.

```swift
import SwiftUI
import RangeSlider

struct ContentView: View {
    @State var myRange: ClosedRange<Double> = 1...50

    var body: some View {
        VStack {
            Text("External from \(myRange.lowerBound) to \(myRange.upperBound)")
            RangeSlider(
                range: $myRange,
                bounds: 1...60,
                steps: 5,
                useTicks: true,
                width: 250
            )
            .padding(32)
        }
    }
}
```

It is possible to tint the range slider like so:

```swift
RangeSlider(
    range: $myRange,
    bounds: 1...60,
    steps: 5,
    useTicks: true,
    width: 250
)
.tint(.green)
```

Further users can define their own ticks:

```swift
RangeSlider(
    range: $myRange,
    bounds: 0...100,
    steps: 5,
    width: 300
)
.ticks([
    Tick(place: 10, style: TickStyle(color: .red, width: 2, height: 12)),
    Tick(place: 50, style: TickStyle(color: .blue, width: 3, height: 16)),
    Tick(place: 90) // default style
])
```
