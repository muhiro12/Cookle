import AVFoundation
import Speech
import SwiftUI

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var transcript = ""

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() throws {
        Logger(#file).info("Start recording")
        let recognizer = SFSpeechRecognizer()
        audioEngine = .init()
        request = .init()
        guard let audioEngine, let request else {
            Logger(#file).error("Failed to initialize audio engine or request")
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "unknown"
            Logger(#file).debug(
                "Appending buffer on queue: \(queueLabel), isMainThread: \(Thread.isMainThread)"
            )
            self?.request?.append(buffer)
        }

        task = recognizer?.recognitionTask(with: request) { result, error in
            if let error {
                Logger(#file).error("Speech recognition failed: \(error.localizedDescription)")
                return
            }
            guard let result else {
                Logger(#file).error("Speech recognition returned nil result")
                return
            }
            Logger(#file).debug(
                "Transcription: \(result.bestTranscription.formattedString), isFinal: \(result.isFinal)"
            )
            self.transcript = result.bestTranscription.formattedString
        }

        audioEngine.prepare()
        try audioEngine.start()
        Logger(#file).notice("Recording started")
    }

    func stop() {
        Logger(#file).info("Stop recording")
        audioEngine?.stop()
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        Logger(#file).notice("Recording stopped")
    }
}
