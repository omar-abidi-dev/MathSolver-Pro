import SwiftUI

/// Draggable color legend overlay for the graph canvas (Fix 9-B).
/// Shows which line color maps to which equation text.
/// User can drag the legend to any corner; it snaps to the nearest corner on release.
struct GraphLegendView: View {
    @ObservedObject var vm: GraphViewModel
    let canvasSize: CGSize

    @State private var corner: Corner = .topLeading
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let eq1Color = Color.blue
    private let eq2Color = Color.red

    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    var body: some View {
        if vm.expr1 != nil {
            legendCard
                .position(cardPosition)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            isDragging = true
                            dragOffset = v.translation
                        }
                        .onEnded { v in
                            isDragging = false
                            let pos = CGPoint(
                                x: cardPosition.x + v.translation.width,
                                y: cardPosition.y + v.translation.height
                            )
                            corner = nearestCorner(to: pos)
                            dragOffset = .zero
                        }
                )
                .animation(.spring(response: 0.3), value: corner)
        }
    }

    // MARK: - Legend card

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(color: eq1Color, text: vm.equation1.isEmpty ? "Equation 1" : vm.equation1)
            if vm.expr2 != nil {
                legendRow(color: eq2Color, text: vm.equation2.isEmpty ? "Equation 2" : vm.equation2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial,
                     in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    private func legendRow(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            // Short line sample (20pt)
            color.frame(width: 20, height: 3)
                .clipShape(Capsule())
            Text(text)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Positioning

    private var cardPosition: CGPoint {
        let margin: CGFloat = 12
        let cardW: CGFloat = 130
        let cardH: CGFloat = vm.expr2 != nil ? 50 : 30

        let base: CGPoint = {
            switch corner {
            case .topLeading:     return CGPoint(x: margin + cardW / 2, y: margin + cardH / 2)
            case .topTrailing:    return CGPoint(x: canvasSize.width - margin - cardW / 2, y: margin + cardH / 2)
            case .bottomLeading:  return CGPoint(x: margin + cardW / 2, y: canvasSize.height - margin - cardH / 2)
            case .bottomTrailing: return CGPoint(x: canvasSize.width - margin - cardW / 2, y: canvasSize.height - margin - cardH / 2)
            }
        }()

        if isDragging {
            return CGPoint(x: base.x + dragOffset.width, y: base.y + dragOffset.height)
        }
        return base
    }

    private func nearestCorner(to point: CGPoint) -> Corner {
        let cx = canvasSize.width / 2
        let cy = canvasSize.height / 2
        if point.x < cx {
            return point.y < cy ? .topLeading : .bottomLeading
        } else {
            return point.y < cy ? .topTrailing : .bottomTrailing
        }
    }
}

#Preview {
    let vm = GraphViewModel()
    ZStack {
        Color.gray.opacity(0.1)
        GraphLegendView(vm: vm, canvasSize: CGSize(width: 350, height: 350))
    }
    .frame(width: 350, height: 350)
}
