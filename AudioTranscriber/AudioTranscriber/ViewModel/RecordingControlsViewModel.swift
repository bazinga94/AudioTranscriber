//
//  RecordingControlsViewModel.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import Combine
import AVFAudio

class RecordingControlsViewModel: ObservableObject, @unchecked Sendable {
	enum RecordingState {
		case idle
		case recording
		case paused
	}
	
	@Published var state: RecordingState = .idle
	
	private var audioRecorder: AudioRecorder
	private var appleTranscription: AppleTranscriptionService
	private var transcriptionQueueManager: TranscriptionQueueManager
	private let audioSessionManager: AudioSessionManager
	
	private(set) var currentRecordingSession: RecordingSession?
	private(set) var audioSegmentURLs: [URL] = []
	private var cancellables = Set<AnyCancellable>()
	
	init(
		audioRecorder: AudioRecorder,
		appleTranscription: AppleTranscriptionService,
		transcriptionQueueManager: TranscriptionQueueManager
	) {
		self.audioRecorder = audioRecorder
		self.appleTranscription = appleTranscription
		self.transcriptionQueueManager = transcriptionQueueManager
		self.audioSessionManager = AudioSessionManager()
		self.audioSessionManager.delegate = self
		
		self.audioRecorder.audioSegmentPublisher
			.sink { [weak self] url in
				self?.audioSegmentURLs.append(url)
			}
			.store(in: &cancellables)
	}
	
	func toggleRecordingState() async {
		switch state {
		case .idle:
			let recordGranted = await checkRecordPermission()
			let speechGranted = await checkSpeechRecognitionPermission()
			
			guard recordGranted && speechGranted else { return }
			
			do {
				currentRecordingSession = RecordingSession()
				try audioRecorder.startRecording()
				state = .recording
			} catch {
				print("Recording start failed: \(error)")
				state = .idle
			}
			
		case .recording:
			audioRecorder.pauseRecording()
			state = .paused
			
		case .paused:
			do {
				try audioRecorder.resumeRecording()
				state = .recording
			} catch {
				print("Resume failed: \(error)")
				state = .paused
			}
		}
	}
	
	func stopRecordingAndSave() {
		audioRecorder.stopRecording()
		state = .idle
	}
	
	func checkRecordPermission() async -> Bool {
		await withCheckedContinuation { continuation in
			AudioRecordingPermissionManager.check { granted in
				continuation.resume(returning: granted)
			}
		}
	}
	
	func checkSpeechRecognitionPermission() async -> Bool {
		await withCheckedContinuation { continuation in
			AppleSpeechRecognitionPermissionManager.check { granted in
				continuation.resume(returning: granted)
			}
		}
	}
	
	func transcribeRecord() {
		Task.detached {
			await withTaskGroup(of: Void.self) { group in
				for segment in self.currentRecordingSession?.segments ?? [] {
					let task = AudioTranscriptionTask(segment: segment)
					group.addTask {
						await self.transcriptionQueueManager.add(task: task)
					}
				}
			}
			self.flushSavedSessionAndSegments()
		}
	}
	
	private func flushSavedSessionAndSegments() {
		currentRecordingSession = nil
		audioSegmentURLs = []
	}
}

extension RecordingControlsViewModel {
	var toggleButtonLabel: String {
		switch state {
		case .idle:
			return "Record"
		case .recording:
			return "Pause"
		case .paused:
			return "Resume"
		}
	}

	var toggleButtonIcon: String {
		switch state {
		case .idle:
			return "mic.fill"
		case .recording:
			return "pause.fill"
		case .paused:
			return "play.fill"
		}
	}

	var toggleButtonColor: Color {
		switch state {
		case .idle:
			return .blue
		case .recording:
			return .orange
		case .paused:
			return .green
		}
	}
}

extension RecordingControlsViewModel: AudioSessionManagerDelegate {
	func audioShouldPause() {
		audioRecorder.pauseRecording()
		state = .paused
	}
	
	func audioShouldResume() {
		try? audioRecorder.resumeRecording()
		state = .recording
	}
}
