import SwiftUI

/// Redirect — the solver UI now lives in PhysicsSolverView.
/// HomeView navigates to PhysicsView(), which renders PhysicsSolverView.
struct PhysicsView: View {
    var body: some View {
        PhysicsSolverView()
    }
}

#Preview {
    PhysicsView()
}
