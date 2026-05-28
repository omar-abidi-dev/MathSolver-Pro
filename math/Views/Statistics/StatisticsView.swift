import SwiftUI

/// Rebuilt Statistics screen – input + results + charts all in one view.
struct StatisticsView: View {
    @StateObject private var vm = StatisticsViewModel()
    @State private var showKeyboard = false

    private let accent = Color(red: 0, green: 0.749, blue: 0.647) // #00BFA5

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        inputSection
                        if let error = vm.errorMessage { errorBanner(error) }
                        if vm.hasCalculated { resultsSection }
                    }
                    .padding(16)
                    .padding(.bottom, showKeyboard ? 260 : 0)
                }

                if showKeyboard {
                    StatisticsNumKeyboard(
                        text: $vm.inputText,
                        onDone: { showKeyboard = false }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.hasCalculated)
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enter Your Dataset")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation { showKeyboard.toggle() }
                } label: {
                    Image(systemName: showKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                        .font(.subheadline)
                        .foregroundStyle(accent)
                }
                .accessibilityLabel(showKeyboard ? "Hide keyboard" : "Show keyboard")
            }

            Text("Comma or space separated numbers")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Chip tags of parsed numbers
            if !vm.parsedValues.isEmpty && vm.hasCalculated {
                chipTags
            }

            TextEditor(text: $vm.inputText)
                .frame(minHeight: 80, maxHeight: 120)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            vm.errorMessage != nil ? Color.red.opacity(0.6) : accent.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .onTapGesture { showKeyboard = true }

            // Examples
            Text("Examples: 4, 8, 6, 5, 3  or  4 8 6 5 3")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Calculate button
            Button(action: vm.calculate) {
                HStack(spacing: 8) {
                    Image(systemName: "function")
                    Text("Calculate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .accessibilityLabel("Calculate statistics")
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Chip tags

    private var chipTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.parsedValues.indices, id: \.self) { i in
                    Text(StatisticsEngine.fmt(vm.parsedValues[i]))
                        .font(.caption.weight(.medium).monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accent.opacity(0.12))
                        .foregroundStyle(accent)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(spacing: 20) {
            // Stat cards grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.statItems) { item in
                    StatCard(item: item)
                }
            }

            // Charts
            if vm.n >= 2 {
                StatisticsChartSection(vm: vm)
            }
        }
    }
}

#Preview {
    StatisticsView()
}
