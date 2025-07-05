//
//  RecordingControlsViewModel.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import Combine
import AVFAudio

class RecordingControlsViewModel: ObservableObject {
	enum RecordingState {
		case idle
		case recording
		case paused
	}
	
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
			.sink { [weak self] url in
				self?.audioSegmentURLs.append(url)
			}
			.store(in: &cancellables)
		
		self.addAudioRouteChangeObserver()
		self.addInterruptionNotificationObserver()
	}
	
	func toggleRecordingState() {
		Task {
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
		currentRecordingSession = nil
		audioSegmentURLs = []
	}
	
	private func addAudioRouteChangeObserver() {
		NotificationCenter.default.addObserver(
			forName: AVAudioSession.routeChangeNotification,
			object: nil,
			queue: .main
		) { [weak self] notification in
			self?.handleAudioRouteChange(notification)
		}
	}
	
	private func handleAudioRouteChange(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
			return
		}

		let currentOutputs = AVAudioSession.sharedInstance().currentRoute.outputs
		let isExternalOutputConnected = currentOutputs.contains {
			[.headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
		}

		switch reason {
		case .oldDeviceUnavailable:
			print("Device unplugged — pausing")
			audioRecorder.pauseRecording()
			state = .paused
			
		case .newDeviceAvailable, .routeConfigurationChange:
			print("🎧 Route changed — checking if resume is needed")
			if isExternalOutputConnected {
				try? audioRecorder.resumeRecording()
				state = .recording
			} else {
				audioRecorder.pauseRecording()
				state = .paused
			}
			
		default:
			break
		}
	}
	
	private func addInterruptionNotificationObserver() {
		NotificationCenter.default.addObserver(
			forName: AVAudioSession.interruptionNotification,
			object: nil,
			queue: .main
		) { [weak self] notification in
			self?.handleAudioInterruption(notification)
		}
	}
	
	private func handleAudioInterruption(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
			return
		}

		switch type {
		case .began:
			print("Interruption began — pausing")
			audioRecorder.pauseRecording()
			state = .paused

		case .ended:
			let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt).map { AVAudioSession.InterruptionOptions(rawValue: $0) }?.contains(.shouldResume) ?? false

			if shouldResume {
				print("Interruption ended — resuming")
				try? audioRecorder.resumeRecording()
				state = .recording
			}
			
		default:
			break
		}
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
