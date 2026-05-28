import SwiftUI

/// Canvas-based graph renderer with axes, tick labels, curves,
/// key-point markers, intersection callouts, animation clipping,
/// and pinch-to-zoom / pan gestures.
struct GraphCanvasView: View {
    @ObservedObject var vm: GraphViewModel

    // Gesture state
    @State private var baseXMin: Double = -10
    @State private var baseXMax: Double =  10
    @State private var baseYMin: Double = -10
    @State private var baseYMax: Double =  10
    @State private var dragStart: CGPoint = .zero

    // Colors
    private let eq1Color = Color.blue
    private let eq2Color = Color.red
    private let gridColor = Color.gray.opacity(0.18)
    private let axisColor = Color.primary

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { ctx, sz in
                drawGrid(ctx: ctx, size: sz)
                drawAxes(ctx: ctx, size: sz)
                drawTickLabels(ctx: ctx, size: sz)
                if let e = vm.expr1 { drawCurve(ctx: ctx, size: sz, expr: e, color: eq1Color) }
                if let e = vm.expr2 { drawCurve(ctx: ctx, size: sz, expr: e, color: eq2Color) }
                drawKeyPointMarkers(ctx: ctx, size: sz)
                drawIntersections(ctx: ctx, size: sz)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .gesture(dragGesture(size: size))
            .gesture(magnificationGesture())
            .accessibilityElement()
            .accessibilityLabel("Graph canvas showing plotted equations")
        }
    }

    // MARK: - Coordinate mapping

    private func toScreen(_ wx: Double, _ wy: Double, size: CGSize) -> CGPoint {
        let sx = (wx - vm.xMin) / (vm.xMax - vm.xMin) * size.width
        let sy = size.height - (wy - vm.yMin) / (vm.yMax - vm.yMin) * size.height
        return CGPoint(x: sx, y: sy)
    }

    // MARK: - Tick interval

    /// Choose a nice tick spacing (1, 2, 5, 10, 20, …) so roughly 5-10 ticks appear.
    private func tickStep(for range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        let raw = span / 8.0
        let mag = pow(10, floor(log10(raw)))
        let norm = raw / mag
        if norm < 1.5      { return mag }
        else if norm < 3.5  { return 2 * mag }
        else if norm < 7.5  { return 5 * mag }
        else                { return 10 * mag }
    }

    // MARK: - Grid

    private func drawGrid(ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        let xStep = tickStep(for: vm.xMin...vm.xMax)
        let yStep = tickStep(for: vm.yMin...vm.yMax)

        var x = (vm.xMin / xStep).rounded(.down) * xStep
        while x <= vm.xMax {
            let p = toScreen(x, 0, size: size)
            path.move(to: CGPoint(x: p.x, y: 0))
            path.addLine(to: CGPoint(x: p.x, y: size.height))
            x += xStep
        }
        var y = (vm.yMin / yStep).rounded(.down) * yStep
        while y <= vm.yMax {
            let p = toScreen(0, y, size: size)
            path.move(to: CGPoint(x: 0, y: p.y))
            path.addLine(to: CGPoint(x: size.width, y: p.y))
            y += yStep
        }
        ctx.stroke(path, with: .color(gridColor), lineWidth: 0.5)
    }

    // MARK: - Axes

    private func drawAxes(ctx: GraphicsContext, size: CGSize) {
        var path = Path()
        // X axis
        let origin = toScreen(0, 0, size: size)
        let xAxisY = min(max(origin.y, 0), size.height)
        path.move(to: CGPoint(x: 0, y: xAxisY))
        path.addLine(to: CGPoint(x: size.width, y: xAxisY))
        // Y axis
        let yAxisX = min(max(origin.x, 0), size.width)
        path.move(to: CGPoint(x: yAxisX, y: 0))
        path.addLine(to: CGPoint(x: yAxisX, y: size.height))
        ctx.stroke(path, with: .color(axisColor), lineWidth: 1)
    }

    // MARK: - Tick labels (Fix 4)

    private func drawTickLabels(ctx: GraphicsContext, size: CGSize) {
        let xStep = tickStep(for: vm.xMin...vm.xMax)
        let yStep = tickStep(for: vm.yMin...vm.yMax)
        let origin = toScreen(0, 0, size: size)
        let xAxisY = min(max(origin.y, 0), size.height)
        let yAxisX = min(max(origin.x, 0), size.width)

        let labelFont = Font.system(size: 10)
        let labelColor: Color = .secondary

        // X-axis ticks
        var x = (vm.xMin / xStep).rounded(.down) * xStep
        while x <= vm.xMax {
            let p = toScreen(x, 0, size: size)
            // Tick mark
            var tick = Path()
            tick.move(to: CGPoint(x: p.x, y: xAxisY - 3))
            tick.addLine(to: CGPoint(x: p.x, y: xAxisY + 3))
            ctx.stroke(tick, with: .color(axisColor), lineWidth: 0.8)

            // Label: show "0" only on X axis to avoid duplication
            let label = formatTick(x)
            let text = Text(label).font(labelFont).foregroundColor(labelColor)
            let resolved = ctx.resolve(text)
            let tSize = resolved.measure(in: size)
            let lx = p.x - tSize.width / 2
            let ly = xAxisY + 5
            if lx > 0 && lx + tSize.width < size.width && ly + tSize.height < size.height {
                ctx.draw(resolved, at: CGPoint(x: p.x, y: ly + tSize.height / 2))
            }
            x += xStep
        }

        // Y-axis ticks (skip 0 — shown on X axis)
        var y = (vm.yMin / yStep).rounded(.down) * yStep
        while y <= vm.yMax {
            if abs(y) > yStep * 0.1 { // skip zero
                let p = toScreen(0, y, size: size)
                var tick = Path()
                tick.move(to: CGPoint(x: yAxisX - 3, y: p.y))
                tick.addLine(to: CGPoint(x: yAxisX + 3, y: p.y))
                ctx.stroke(tick, with: .color(axisColor), lineWidth: 0.8)

                let label = formatTick(y)
                let text = Text(label).font(labelFont).foregroundColor(labelColor)
                let resolved = ctx.resolve(text)
                let tSize = resolved.measure(in: size)
                let lx = yAxisX - tSize.width - 4
                if lx > 0 && p.y - tSize.height / 2 > 0 && p.y + tSize.height / 2 < size.height {
                    ctx.draw(resolved, at: CGPoint(x: lx + tSize.width / 2, y: p.y))
                }
            }
            y += yStep
        }
    }

    private func formatTick(_ v: Double) -> String {
        if abs(v) < 1e-10 { return "0" }
        if v == v.rounded() && abs(v) < 1e6 { return String(Int(v)) }
        return String(format: "%.1f", v)
    }

    // MARK: - Curve drawing with animation clipping (Fix 1)

    private func drawCurve(ctx: GraphicsContext, size: CGSize,
                           expr: Expression, color: Color) {
        let sampleCount = Int(size.width)  // 1 sample per point for smoothness
        var path = Path()
        var started = false

        // Animation clip: only render up to animationProgress fraction of width
        let clipX = size.width * vm.animationProgress

        for i in 0..<sampleCount {
            let sx = CGFloat(i) // screen x
            if sx > clipX { break }

            let wx = vm.xMin + (Double(i) / Double(sampleCount)) * (vm.xMax - vm.xMin)
            guard let wy = vm.eval(expr, at: wx) else { started = false; continue }

            let sp = toScreen(wx, wy, size: size)
            // Skip points far outside canvas to avoid huge spikes
            guard sp.y > -size.height && sp.y < size.height * 2 else {
                started = false; continue
            }

            if !started { path.move(to: sp); started = true }
            else        { path.addLine(to: sp) }
        }
        ctx.stroke(path, with: .color(color), lineWidth: 2.5)
    }

    // MARK: - Key-point markers (Fix 6 dots on graph)

    private func drawKeyPointMarkers(ctx: GraphicsContext, size: CGSize) {
        func dot(_ pt: CGPoint, color: Color, isStar: Bool = false) {
            let sp = toScreen(Double(pt.x), Double(pt.y), size: size)
            guard sp.x > -10, sp.x < size.width + 10,
                  sp.y > -10, sp.y < size.height + 10 else { return }
            let r: CGFloat = isStar ? 6 : 5
            if isStar {
                // Diamond marker for vertex
                var d = Path()
                d.move(to: CGPoint(x: sp.x, y: sp.y - r))
                d.addLine(to: CGPoint(x: sp.x + r, y: sp.y))
                d.addLine(to: CGPoint(x: sp.x, y: sp.y + r))
                d.addLine(to: CGPoint(x: sp.x - r, y: sp.y))
                d.closeSubpath()
                ctx.fill(d, with: .color(color))
            } else {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: sp.x - r, y: sp.y - r, width: r * 2, height: r * 2)),
                    with: .color(color)
                )
            }
            // Small label next to dot
            let label = "(\(fmt(pt.x)), \(fmt(pt.y)))"
            let text = Text(label).font(.system(size: 9)).foregroundColor(color)
            let resolved = ctx.resolve(text)
            ctx.draw(resolved, at: CGPoint(x: sp.x + 10, y: sp.y - 10))
        }

        // Equation 1 key points
        if let p = vm.keyPoints1.yIntercept { dot(p, color: eq1Color) }
        vm.keyPoints1.xIntercepts.forEach { dot($0, color: eq1Color) }
        if let v = vm.keyPoints1.vertex { dot(v, color: eq1Color, isStar: true) }

        // Equation 2 key points
        if let p = vm.keyPoints2.yIntercept { dot(p, color: eq2Color) }
        vm.keyPoints2.xIntercepts.forEach { dot($0, color: eq2Color) }
        if let v = vm.keyPoints2.vertex { dot(v, color: eq2Color, isStar: true) }
    }

    // MARK: - Intersection callouts (Fix 5)

    private func drawIntersections(ctx: GraphicsContext, size: CGSize) {
        if vm.expr1 != nil && vm.expr2 != nil && vm.intersections.isEmpty {
            // "No intersection" label
            let text = Text("No intersection")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            let resolved = ctx.resolve(text)
            ctx.draw(resolved, at: CGPoint(x: size.width / 2, y: 20))
            return
        }

        for pt in vm.intersections {
            let sp = toScreen(Double(pt.x), Double(pt.y), size: size)
            guard sp.x > 0, sp.x < size.width,
                  sp.y > 0, sp.y < size.height else { continue }

            // Green dot
            let r: CGFloat = 6
            ctx.fill(
                Path(ellipseIn: CGRect(x: sp.x - r, y: sp.y - r, width: r * 2, height: r * 2)),
                with: .color(.green)
            )

            // Callout bubble
            let label = "(\(fmt(pt.x)), \(fmt(pt.y)))"
            let text = Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
            let resolved = ctx.resolve(text)
            let tSize = resolved.measure(in: size)

            let bw = tSize.width + 12
            let bh = tSize.height + 8
            let bx = sp.x - bw / 2
            let by = sp.y - r - bh - 4

            // White card
            let rect = CGRect(x: bx, y: by, width: bw, height: bh)
            let rr = Path(roundedRect: rect, cornerRadius: 6)
            ctx.fill(rr, with: .color(Color(.systemBackground)))
            ctx.stroke(rr, with: .color(Color(.systemGray3)), lineWidth: 0.8)
            ctx.draw(resolved, at: CGPoint(x: sp.x, y: by + bh / 2))
        }
    }

    // MARK: - Gestures

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStart == .zero {
                    baseXMin = vm.xMin; baseXMax = vm.xMax
                    baseYMin = vm.yMin; baseYMax = vm.yMax
                    dragStart = value.startLocation
                }
                let dx = value.translation.width
                let dy = value.translation.height
                let xSpan = baseXMax - baseXMin
                let ySpan = baseYMax - baseYMin
                vm.xMin = baseXMin - Double(dx) / Double(size.width) * xSpan
                vm.xMax = baseXMax - Double(dx) / Double(size.width) * xSpan
                vm.yMin = baseYMin + Double(dy) / Double(size.height) * ySpan
                vm.yMax = baseYMax + Double(dy) / Double(size.height) * ySpan
            }
            .onEnded { _ in dragStart = .zero }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let factor = 1.0 / scale
                let xCenter = (vm.xMin + vm.xMax) / 2
                let yCenter = (vm.yMin + vm.yMax) / 2
                let halfX = (vm.xMax - vm.xMin) / 2 * factor
                let halfY = (vm.yMax - vm.yMin) / 2 * factor
                vm.xMin = xCenter - halfX
                vm.xMax = xCenter + halfX
                vm.yMin = yCenter - halfY
                vm.yMax = yCenter + halfY
            }
    }

    // MARK: - Formatting

    private func fmt(_ v: CGFloat) -> String {
        let d = Double(v)
        if abs(d) < 1e-10 { return "0.00" }
        return String(format: "%.2f", d)
    }
}

#Preview {
    let vm = GraphViewModel()
    GraphCanvasView(vm: vm)
        .frame(height: 350)
        .padding()
}
