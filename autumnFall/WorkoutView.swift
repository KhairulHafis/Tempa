import SwiftUI

struct WorkoutView: View {
    @State private var reps: String = ""
    @State private var goToCamera = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Setup Your pull-up 🏋️‍♂️")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 12) {
                Text("Enter number of reps:")
                    .foregroundColor(.black)

                TextField("e.g. 10", text: $reps)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.4)))
                    .foregroundColor(.black)
            }

            Button {
                if let num = Int(reps), num > 0 {
                    goToCamera = true
                }
            } label: {
                Label("Let’s go!", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brown)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 0.96, green: 0.90, blue: 0.80))
        .navigationDestination(isPresented: $goToCamera) {
            CameraSetupView(reps: Int(reps) ?? 0)
        }
    }
}
