//
//  AppleTranscriptionService.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/3/25.
//

import Foundation
import Speech

//actor AppleTranscriptionService: TranscriptionService {
//	func transcribe(fileURL: URL) async throws -> String {
//		let recognizer = SFSpeechRecognizer()
//		guard let recognizer = recognizer, recognizer.isAvailable else {
//			throw TranscriptionError.notAvailable
//		}
//
//		let request = SFSpeechURLRecognitionRequest(url: fileURL)
//		return try await withCheckedThrowingContinuation { continuation in
//			recognizer.recognitionTask(with: request) { result, error in
//				if let error = error {
//					continuation.resume(throwing: TranscriptionError.speechRecognitionFailed(error))
//				} else if let result = result, result.isFinal {
//					print(result.bestTranscription.formattedString)
//					continuation.resume(returning: result.bestTranscription.formattedString)
//				}
//			}
//		}
//	}
//}

enum AppleTranscriptionError: Error {
	case notAvailable
	case speechRecognitionFailed(Error)
}

actor AppleTranscriptionService: TranscriptionService {
	private var isProcessing = false
	private var taskQueue: [URL] = []

	func transcribe(fileURL: URL) async throws -> String {
		taskQueue.append(fileURL)
		return try await processNext()
	}

	private func processNext() async throws -> String {
		while isProcessing {
			try await Task.sleep(nanoseconds: 100_000_000) // 100ms polling
		}

		guard let fileURL = taskQueue.first else {
			throw AppleTranscriptionError.notAvailable
		}

		isProcessing = true
		defer {
			taskQueue.removeFirst()
			isProcessing = false
		}

		return try await runRecognition(fileURL: fileURL)
	}

	private func runRecognition(fileURL: URL) async throws -> String {
		let recognizer = SFSpeechRecognizer()
		guard let recognizer = recognizer, recognizer.isAvailable else {
			throw AppleTranscriptionError.notAvailable
		}

		let request = SFSpeechURLRecognitionRequest(url: fileURL)
		return try await withCheckedThrowingContinuation { continuation in
			recognizer.recognitionTask(with: request) { result, error in
				if let error = error {
					continuation.resume(throwing: AppleTranscriptionError.speechRecognitionFailed(error))
				} else if let result = result, result.isFinal {
					continuation.resume(returning: result.bestTranscription.formattedString)
				}
			}
		}
	}
}
