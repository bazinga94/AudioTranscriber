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
	private var appleTranscription: AppleTranscriptionService
	private var transcriptionQueueManager: TranscriptionQueueManager
	
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
		
		self.audioRecorder.audioSegmentPublisher
			.sink(receiveValue: { [weak self] url in
				print("1", url)
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
			self.currentRecordingSession = RecordingSession()
			try audioRecorder.startRecording()
		} catch {
			print("Audio save failed: \(error.localizedDescription)")
		}
	}
	
	func stopRecording() {
		audioRecorder.stopRecording()
	}
	
	func checkSpeechRecognitionPermission() async -> Bool {
		return await withCheckedContinuation { continuation in
			appleTranscription.checkSpeechRecognitionPermissionNeeded { granted in
				continuation.resume(returning: granted)
			}
		}
	}
	
	func transcribeRecord() {
		Task {
			await withTaskGroup(of: Void.self) { [weak self] group in
				for segment in self?.currentRecordingSession?.segments ?? [] {
					let task = AudioTranscriptionTask(segment: segment)
					group.addTask {
						await self?.transcriptionQueueManager.add(task: task)
					}
				}
			}
			flushSavedSessionAndSegments()
		}
	}
	
	private func flushSavedSessionAndSegments() {
		self.currentRecordingSession = nil
		self.audioSegmentURLs = []
	}
}
