import AVFoundation
import Speech
import SwiftUI

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    enum SpeechRecognizerError: LocalizedError {
        case recognizerUnavailable
        case authorizationDenied
        case initializationFailed

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is not available."
            case .authorizationDenied:
                return "Speech recognition permission was denied."
            case .initializationFailed:
                return "Failed to initialize audio engine or recognition request."
            }
        }
    }

    func start() throws {
        Logger(#file).info("Start recording")

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            Logger(#file).error("Speech recognition not authorized")
            throw SpeechRecognizerError.authorizationDenied
        }

        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            Logger(#file).error("Speech recognizer is not available")
            throw SpeechRecognizerError.recognizerUnavailable
        }

        audioEngine = .init()
        let recognitionRequest: SFSpeechAudioBufferRecognitionRequest = .init()
        request = recognitionRequest
        guard let audioEngine else {
            Logger(#file).error("Failed to initialize audio engine or request")
            throw SpeechRecognizerError.initializationFailed
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Logger(#file).error("Failed to configure audio session: \(error.localizedDescription)")
            throw error
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 1_024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        task = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error {
                Logger(#file).error("Speech recognition failed: \(error.localizedDescription)")
                self?.errorMessage = error.localizedDescription
                return
            }
            guard let result else {
                Logger(#file).error("Speech recognition returned nil result")
                self?.errorMessage = SpeechRecognizerError.initializationFailed.localizedDescription
                return
            }
            Logger(#file).debug(
                "Transcription: \(result.bestTranscription.formattedString), isFinal: \(result.isFinal)"
            )
            DispatchQueue.main.async {
                self?.transcript = result.bestTranscription.formattedString
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            Logger(#file).error("Failed to start audio engine: \(error.localizedDescription)")
            throw error
        }
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
