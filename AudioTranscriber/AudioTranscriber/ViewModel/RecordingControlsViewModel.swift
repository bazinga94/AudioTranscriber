//
//  RecordingControlsViewModel.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import AVFAudio

class RecordingControlsViewModel: ObservableObject {
	@Published var micAuthorized: Bool = false
	private var audioRecorder: AudioRecorder = AudioRecorder()
	
	func requestRecordPermission() {
		audioRecorder.requestRecordPermission { granted in
			DispatchQueue.main.async {
				self.micAuthorized = granted
			}
		}
	}
	
	func startRecording() throws {
		let directory = FileManager.default.temporaryDirectory
		let stringFileURL = "recording_\(UUID().uuidString).caf"
		let fileURL = directory.appendingPathComponent(stringFileURL)
		
		do {
			try audioRecorder.startRecording(to: fileURL)
		} catch {
			print("Audio save failed: \(error.localizedDescription)")
		}
	}
	
	func stopRecording() {
		audioRecorder.stopRecording()
	}
}
