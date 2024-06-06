import SwiftUI

struct AddMultipleTextsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var texts: [String]
    
    @State private var text = ""
    
    init(texts: Binding<[String]>) {
        self._texts = texts
    }    
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            text = ""
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            texts.insert(
                                contentsOf: text.split(separator: "\n").map {
                                    String($0)
                                },
                                at: texts.lastIndex(of: "") ?? .zero
                            )
                            text = ""
                            dismiss()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 8))
                .padding()
                .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    AddMultipleTextsView(texts: .constant([]))
}
