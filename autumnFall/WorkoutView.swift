// Uses shared Theme and Model abstractions
import SwiftUI
//import WorkoutSessionStore

struct WorkoutView: View {
    @State private var reps: String = ""
    @State private var goToCamera = false
    
    @EnvironmentObject var sessionStore: WorkoutSessionStore

    var body: some View {
        VStack(spacing: 30) {
            Text("Setup Your pull-up 🏋️‍♂️")
                .font(AppTheme.Fonts.title)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Enter number of reps:")
                    .foregroundColor(AppTheme.Colors.textPrimary)

                TextField("e.g. 10", text: $reps)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(AppTheme.Colors.background)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.Colors.textPrimary.opacity(0.4)))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            Button {
                if let num = Int(reps), num > 0 {
                    goToCamera = true
                }
            } label: {
                Label("Let’s go!", systemImage: "arrow.right.circle.fill")
                    .font(AppTheme.Fonts.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.primary)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.background)
        .navigationDestination(isPresented: $goToCamera) {
            CameraSetupView(reps: Int(reps) ?? 0)
        }
    }
}

