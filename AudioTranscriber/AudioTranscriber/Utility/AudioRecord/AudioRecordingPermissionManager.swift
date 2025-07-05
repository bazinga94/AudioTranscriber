//
//  AudioRecordingPermissionManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import AVFoundation

enum AudioRecordingPermissionManager {
	static func check(completionHandler: @escaping ((Bool) -> Void)) {
		let permission = AVAudioApplication.shared.recordPermission
		
		switch permission {
		case .undetermined:
			requestRecordPermission { granted in
				completionHandler(granted)
			}
		case .denied:
			completionHandler(false)
		case .granted:
			completionHandler(true)
		@unknown default:
			completionHandler(false)
		}
	}
	
	private static func requestRecordPermission(completionHandler: @escaping ((Bool) -> Void)) {
		AVAudioApplication.requestRecordPermission(completionHandler: { granted in
			completionHandler(granted)
		})
	}
}
