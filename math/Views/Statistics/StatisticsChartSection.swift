import SwiftUI
import Charts

/// Three Swift Charts visualizations for the statistics dataset:
/// (A) Frequency bar chart, (B) Number-line markers, (C) Box plot.
struct StatisticsChartSection: View {
    let vm: StatisticsViewModel

    private let accent = Color(red: 0, green: 0.749, blue: 0.647)

    var body: some View {
        VStack(spacing: 20) {
            frequencyChart
            numberLineChart
            boxPlot
        }
    }

    // MARK: - A) Frequency Bar Chart

    private var frequencyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency Distribution")
                .font(.headline)

            Chart(vm.frequencyTable, id: \.value) { entry in
                BarMark(
                    x: .value("Value", StatisticsEngine.fmt(entry.value)),
                    y: .value("Frequency", entry.count)
                )
                .foregroundStyle(accent.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(entry.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxisLabel("Frequency")
            .frame(height: 200)
        }
        .chartPadding()
    }

    // MARK: - B) Number-line with key markers

    private var numberLineChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number Line")
                .font(.headline)

            let markers: [(label: String, value: Double, color: Color)] = buildMarkers()

            Chart {
                ForEach(vm.parsedValues.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Value", vm.parsedValues[i]),
                        y: .value("Row", "Data")
                    )
                    .foregroundStyle(.gray.opacity(0.35))
                    .symbolSize(30)
                }

                ForEach(markers, id: \.label) { m in
                    PointMark(
                        x: .value("Value", m.value),
                        y: .value("Row", "Data")
                    )
                    .foregroundStyle(m.color)
                    .symbolSize(80)
                    .annotation(position: .top) {
                        Text(m.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(m.color)
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 100)
        }
        .chartPadding()
    }

    // MARK: - C) Box-and-Whisker Plot

    private var boxPlot: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Box Plot")
                .font(.headline)

            let minV = vm.minVal
            let maxV = vm.maxVal
            let q1 = vm.q1
            let q3 = vm.q3
            let med = vm.median
            let meanV = vm.mean
            let f = StatisticsEngine.fmt

            Chart {
                // Whisker: min → Q1
                RectangleMark(
                    xStart: .value("Start", minV),
                    xEnd: .value("End", q1),
                    yStart: .value("Lo", -0.05),
                    yEnd: .value("Hi", 0.05)
                )
                .foregroundStyle(accent.opacity(0.25))

                // Box: Q1 → Q3
                RectangleMark(
                    xStart: .value("Start", q1),
                    xEnd: .value("End", q3),
                    yStart: .value("Lo", -0.3),
                    yEnd: .value("Hi", 0.3)
                )
                .foregroundStyle(accent.opacity(0.45))
                .cornerRadius(4)

                // Whisker: Q3 → max
                RectangleMark(
                    xStart: .value("Start", q3),
                    xEnd: .value("End", maxV),
                    yStart: .value("Lo", -0.05),
                    yEnd: .value("Hi", 0.05)
                )
                .foregroundStyle(accent.opacity(0.25))

                // Median line
                RuleMark(x: .value("Median", med))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .annotation(position: .top) {
                        Text("Med \(f(med))")
                            .font(.caption2.weight(.semibold))
                    }

                // Mean dot
                PointMark(
                    x: .value("Mean", meanV),
                    y: .value("Row", 0)
                )
                .foregroundStyle(.orange)
                .symbolSize(60)
                .annotation(position: .bottom) {
                    Text("x̄ \(f(meanV))")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                // Min / Max labels
                PointMark(x: .value("Min", minV), y: .value("Row", 0))
                    .foregroundStyle(accent)
                    .symbolSize(40)
                    .annotation(position: .bottom) {
                        Text(f(minV))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                PointMark(x: .value("Max", maxV), y: .value("Row", 0))
                    .foregroundStyle(accent)
                    .symbolSize(40)
                    .annotation(position: .bottom) {
                        Text(f(maxV))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
            .chartYAxis(.hidden)
            .frame(height: 120)

            // 5-number summary below
            HStack {
                ForEach(["Min: \(f(minV))", "Q1: \(f(q1))", "Med: \(f(med))", "Q3: \(f(q3))", "Max: \(f(maxV))"], id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if label != "Max: \(f(maxV))" {
                        Spacer()
                    }
                }
            }
        }
        .chartPadding()
    }

    // MARK: - Helpers

    private func buildMarkers() -> [(label: String, value: Double, color: Color)] {
        var markers: [(label: String, value: Double, color: Color)] = [
            ("Min", vm.minVal, .blue),
            ("Max", vm.maxVal, .red),
            ("Med", vm.median, .purple),
            ("x̄", vm.mean, .orange),
        ]
        if vm.n >= 2 {
            markers.append(("Q1", vm.q1, .cyan))
            markers.append(("Q3", vm.q3, .pink))
        }
        return markers
    }
}

// MARK: - Shared padding modifier

private extension View {
    func chartPadding() -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(red: 0, green: 0.749, blue: 0.647).opacity(0.15), lineWidth: 1)
            )
    }
}
