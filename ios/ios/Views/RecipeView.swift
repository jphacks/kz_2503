import SwiftUI

struct RecipeView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, Recipe!")
        }
        .padding()
    }
}

#Preview {
    RecipeView()
}
