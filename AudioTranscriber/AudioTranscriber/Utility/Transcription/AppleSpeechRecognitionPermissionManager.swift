//
//  AppleSpeechRecognitionPermissionManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Speech

enum AppleSpeechRecognitionPermissionManager {
	static func check(completion: @escaping (Bool) -> Void) {
		switch SFSpeechRecognizer.authorizationStatus() {
		case .notDetermined:
			requestPermission(completion: completion)
		case .denied, .restricted:
			completion(false)
		case .authorized:
			completion(true)
		@unknown default:
			completion(false)
		}
	}

	private static func requestPermission(completion: @escaping (Bool) -> Void) {
		SFSpeechRecognizer.requestAuthorization { status in
			switch status {
			case .authorized:
				completion(true)
			case .denied, .restricted, .notDetermined:
				completion(false)
			@unknown default:
				completion(false)
			}
		}
	}
}
