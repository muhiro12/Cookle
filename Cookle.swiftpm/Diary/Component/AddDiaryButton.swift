import SwiftUI

struct AddDiaryButton: View {    
    @State private var isPresented = false
    
    var body: some View {
        Button("Add Diary", systemImage: "book") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        AddDiaryButton()
    }
}
