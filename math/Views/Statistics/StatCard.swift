import SwiftUI

/// Reusable expandable card showing one statistic with icon, value,
/// formula text, and an optional step-by-step explanation.
struct StatCard: View {
    let item: StatItem
    @State private var isExpanded = false

    // MARK: Accent

    private let accent = Color(red: 0, green: 0.749, blue: 0.647)   // #00BFA5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header row: icon + name
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.subheadline)
                    .foregroundStyle(accent)
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Large value
            Text(item.value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(item.isAvailable ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Formula
            Text(item.formula)
                .font(.caption)
                .italic()
                .foregroundStyle(.secondary)

            // Expand toggle
            if item.isAvailable && !item.steps.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Hide steps" : "How is this calculated?")
                            .font(.caption2.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .foregroundStyle(accent)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(item.steps.enumerated()), id: \.offset) { _, step in
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.primary.opacity(0.85))
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(accent.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name): \(item.value)")
    }
}
