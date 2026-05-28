import SwiftUI

/// Model describing a home module card
struct ModuleItem: Identifiable, Equatable {
    let id = UUID()
    let mode: FeatureMode
    let title: String
    let subtitle: String
    let icon: String? // SF Symbol name (optional if using textIcon)
    let textIcon: String? // Optional text-based icon like "f(x)"
    let color: Color
}

/// Main home screen with navigation to all feature modes
struct HomeView: View {
    @State private var selectedMode: FeatureMode?
    
    // Data-driven module order (top to bottom, left to right)
    // Row 1: Solve | Scan
    // Row 2: Statistics | Physics
    // Row 3: Graph | Calculus
    // Row 4: Homework | Speed
    // Row 5: Debug | Battle
    // Row 6: Leaderboard | (empty)
    private let modules: [ModuleItem] = [
        ModuleItem(mode: .solver,      title: "Solve",       subtitle: "Step-by-step",         icon: "equal.square.fill", textIcon: nil,       color: .blue),
        ModuleItem(mode: .camera,      title: "Scan",        subtitle: "Camera OCR",           icon: "camera.fill",       textIcon: nil,       color: .orange),
        ModuleItem(mode: .statistics,  title: "Statistics",  subtitle: "Data analysis",        icon: "chart.bar.fill",    textIcon: nil,       color: .teal),
        ModuleItem(mode: .physics,     title: "Physics",     subtitle: "Formulas & solvers",   icon: "atom",              textIcon: nil,       color: .red),
        ModuleItem(mode: .graph,       title: "Graph",       subtitle: "Visualize",            icon: "chart.xyaxis.line", textIcon: nil,       color: .purple),
        ModuleItem(mode: .calculus,    title: "Calculus",    subtitle: "Limits & derivatives", icon: "function",          textIcon: nil,       color: .indigo),
        ModuleItem(mode: .homework,    title: "Homework",    subtitle: "Hints & help",         icon: "book.fill",         textIcon: nil,       color: .green),
        ModuleItem(mode: .speed,       title: "Speed",       subtitle: "Timed practice",       icon: "hare.fill",         textIcon: nil,       color: .yellow),
        ModuleItem(mode: .debugger,    title: "Debug",       subtitle: "Find errors",          icon: "checkmark.circle.badge.xmark", textIcon: nil, color: .brown),
        ModuleItem(mode: .battle,      title: "Battle",      subtitle: "Defeat enemies",       icon: "gamecontroller.fill", textIcon: nil,     color: .pink),
        ModuleItem(mode: .leaderboard, title: "Leaderboard", subtitle: "Top scores",            icon: "crown.fill",        textIcon: nil,       color: .cyan)
    ]
    
    // Grid definition
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 32) {
                        headerBanner
                            .padding()
                        
                        // Feature grid driven by data
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(modules.indices, id: \.self) { index in
                                let item = modules[index]
                                let isLastAndOdd = (index == modules.count - 1) && (modules.count % 2 == 1)
                                ModuleCard(item: item) {
                                    selectedMode = item.mode
                                }
                                .frame(minHeight: 140)
                                .gridCellColumns(isLastAndOdd ? 2 : 1)
                                .navigationDestination(isPresented: navigationBinding(item.mode)) {
                                    destinationView(for: item.mode)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Info section removed per FIX 6
                    }
                    .padding(.bottom, 80) // spacing for floating tab bar if present
                }
                
                // Optional floating tab bar background fix (if a local tab bar exists here)
                // This ensures any overlay bar uses material and a subtle separator stroke.
                // If the app uses a different tab bar elsewhere, this overlay remains inert.
                Color.clear
                    .frame(height: 0)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
            .navigationTitle("MathSolver Pro")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header Banner (FIX 1)
    private var headerBanner: some View {
        ZStack {
            // Subtle blue tinted background
            Color(.systemBlue).opacity(0.06)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Decorative math pattern using Canvas
            Canvas { context, size in
                let symbols: [String] = ["∑", "∫", "π", "√", "Δ", "f(x)", "±"]
                let color = Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.06)
                let spacing: CGFloat = 56
                let fontSize: CGFloat = 18
                let font = Font.system(size: fontSize, weight: .semibold, design: .rounded)
                
                var y: CGFloat = 12
                var row = 0
                while y < size.height {
                    var x: CGFloat = 12 + (row % 2 == 0 ? 0 : spacing / 2)
                    while x < size.width {
                        let symbol = symbols[(Int(x + y) / Int(spacing)) % symbols.count]
                        let resolved = context.resolve(Text(symbol).font(font).foregroundColor(color))
                        context.draw(resolved, at: CGPoint(x: x, y: y))
                        x += spacing
                    }
                    y += spacing
                    row += 1
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Foreground content
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MathSolver Pro")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Master equations with step-by-step solutions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "function")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.2))
            }
            .padding(20)
        }
        .frame(minHeight: 100)
    }
    
    // MARK: - Destination factory (keeps navigation intact)
    @ViewBuilder
    private func destinationView(for mode: FeatureMode) -> some View {
        switch mode {
        case .solver: SolverTabView()
        case .camera: CameraScanView()
        case .debugger: DebuggerView()
        case .graph: GraphView()
        case .homework: HomeworkHelperView()
        case .speed: SpeedTrainerView()
        case .battle: BattleGameView()
        case .leaderboard: LeaderboardView()
        case .physics: PhysicsView()
        case .statistics: StatisticsView()
        case .calculus: CalculusView()
        }
    }
    
    private func navigationBinding(_ mode: FeatureMode) -> Binding<Bool> {
        Binding(
            get: { selectedMode == mode },
            set: { if !$0 { selectedMode = nil } }
        )
    }
}

// MARK: - Feature Mode Enum (unchanged)

enum FeatureMode: Equatable {
    case solver
    case camera
    case debugger
    case graph
    case homework
    case speed
    case battle
    case leaderboard
    case physics
    case statistics
    case calculus
}

// MARK: - Module Card

struct ModuleCard: View {
    let item: ModuleItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                iconView
                
                VStack(spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [item.color, item.color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(item.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = item.icon {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
        } else if let textIcon = item.textIcon {
            Text(textIcon)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        } else {
            Color.clear.frame(height: 32)
        }
    }
}

#Preview {
    HomeView()
}
