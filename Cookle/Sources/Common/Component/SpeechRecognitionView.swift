import SwiftUI

struct SpeechRecognitionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recognizer = SpeechRecognitionHelper()

    let completion: (String) -> Void

    var body: some View {
        VStack {
            ScrollView {
                Text(recognizer.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            HStack {
                Button("Cancel", role: .cancel) {
                    recognizer.stopRecording()
                    dismiss()
                }
                Spacer()
                Button("Done") {
                    recognizer.stopRecording()
                    completion(recognizer.transcript)
                    dismiss()
                }
            }
            .padding()
        }
        .onAppear {
            try? recognizer.startRecording()
        }
    }
}
