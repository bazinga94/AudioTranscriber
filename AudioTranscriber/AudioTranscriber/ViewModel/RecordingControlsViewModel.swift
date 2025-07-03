//
//  RecordingControlsViewModel.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import AVFAudio
import SwiftData

class RecordingControlsViewModel: ObservableObject {
	enum RecordingState {
		case idle
		case recording
	}
	
	@Published var micAuthorized: Bool = false
	@Published var state: RecordingState = .idle
	private var audioRecorder: AudioRecorder
	private let modelContext: ModelContext
	
	init(audioRecorder: AudioRecorder = AudioRecorder(), modelContext: ModelContext) {
		self.audioRecorder = audioRecorder
		self.modelContext = modelContext
	}
	
	func checkRecordPermission() async -> Bool {
		return await withCheckedContinuation { continuation in
			audioRecorder.checkRecordPermissionNeeded { granted in
				DispatchQueue.main.async {
					self.micAuthorized = granted
				}
				continuation.resume(returning: granted)
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
