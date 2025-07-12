import AVFoundation
import Speech
import SwiftUI

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var transcript = ""

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() throws {
        let recognizer = SFSpeechRecognizer()
        audioEngine = .init()
        request = .init()
        guard let audioEngine, let request else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }

        task = recognizer?.recognitionTask(with: request) { result, _ in
            guard let result else {
                return
            }
            self.transcript = result.bestTranscription.formattedString
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        audioEngine?.stop()
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
    }
}
