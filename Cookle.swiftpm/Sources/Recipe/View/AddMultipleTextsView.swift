import SwiftUI

struct AddMultipleTextsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var texts: [String]
    
    @State private var text: String
    
    init(texts: Binding<[String]>) {
        self._texts = texts
        self.text = texts.wrappedValue.joined(separator: "\n")
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
                            texts = text.split(separator: "\n", omittingEmptySubsequences: false).map {
                                String($0)
                            }
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
