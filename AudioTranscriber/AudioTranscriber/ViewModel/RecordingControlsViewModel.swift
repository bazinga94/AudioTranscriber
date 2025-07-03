//
//  RecordingControlsViewModel.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import Combine

class RecordingControlsViewModel: ObservableObject {
	enum RecordingState {
		case idle
		case recording
	}
	
	@Published var micAuthorized: Bool = false
	@Published var state: RecordingState = .idle
	
	private var audioRecorder: AudioRecorder
	private(set) var audioSegmentURLs: [URL] = []
	private var cancellables = Set<AnyCancellable>()
	
	init(audioRecorder: AudioRecorder = AudioRecorder()) {
		self.audioRecorder = audioRecorder
		self.audioRecorder.audioSegmentPublisher
			.sink(receiveValue: { [weak self] url in
				self?.audioSegmentURLs.append(url)
			})
			.store(in: &cancellables)
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
		do {
			try audioRecorder.startRecording()
		} catch {
			print("Audio save failed: \(error.localizedDescription)")
		}
	}
	
	func stopRecording() {
		audioRecorder.stopRecording()
	}
}
