//
//  AppleTranscriptionService.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/3/25.
//

import Foundation
import Speech

class AppleTranscriptionService {
	
	func checkSpeechRecognitionPermissionNeeded(completionHandler: @escaping ((Bool) -> Void)) {
		
		let status = SFSpeechRecognizer.authorizationStatus()
		
		switch status {
		case .notDetermined:
			requestSpeechRecognitionPermission { granted in
				completionHandler(granted)
			}
		case .denied, .restricted:
			completionHandler(false)
		case .authorized:
			completionHandler(true)
		@unknown default:
			completionHandler(false)
		}
	}
	
	private func requestSpeechRecognitionPermission(completionHandler: @escaping ((Bool) -> Void)) {
		SFSpeechRecognizer.requestAuthorization { status in
			switch status {
			case .authorized:
				completionHandler(true)
			case .denied, .restricted, .notDetermined:
				completionHandler(false)
			@unknown default:
				completionHandler(false)
			}
		}
	}
	
	func transcribe(fileURL: URL) async throws -> String {
		let recognizer = SFSpeechRecognizer()
		guard let recognizer = recognizer, recognizer.isAvailable else {
			throw TranscriptionError.notAvailable
		}

		let request = SFSpeechURLRecognitionRequest(url: fileURL)
		return try await withCheckedThrowingContinuation { continuation in
			recognizer.recognitionTask(with: request) { result, error in
				if let error = error {
					continuation.resume(throwing: error)
				} else if let result = result, result.isFinal {
					continuation.resume(returning: result.bestTranscription.formattedString)
				}
			}
		}
	}
	
	enum TranscriptionError: Error {
		case notAvailable
	}
}
