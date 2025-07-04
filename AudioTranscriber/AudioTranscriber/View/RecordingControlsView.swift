//
//  RecordingControlsView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI

struct RecordingControlsView: View {
	@Environment(\.modelContext) private var modelContext
	@StateObject var viewModel: RecordingControlsViewModel
	
	init(viewModel: RecordingControlsViewModel) {
		self._viewModel = StateObject(wrappedValue: viewModel)
	}
	
    var body: some View {
		Button {
			Task {
				switch viewModel.state {
				case .idle:
					let recordGranted = await viewModel.checkRecordPermission()
					let speechRecognitionGranted = await viewModel.checkSpeechRecognitionPermission()
					
					if recordGranted && speechRecognitionGranted {
						do {
							viewModel.state = .recording
							try viewModel.startRecording()
						} catch {
							viewModel.state = .idle
							print("Audio save failed: \(error.localizedDescription)")
						}
					}
				case .recording:
					viewModel.stopRecording()
					saveRecordingSession()
					transcribeRecordingSession()
					viewModel.state = .idle
				}
			}
			
		} label: {
			Label(
				viewModel.state == .recording ? "Stop" : "Record",
				systemImage: viewModel.state == .recording ? "stop.fill" : "mic.fill"
			)
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.contentShape(Rectangle())
		}
		.frame(height: 64)
		.buttonStyle(.plain)
		.background(
			viewModel.state == .recording
			? Color(UIColor.systemRed)
			: Color(UIColor.systemBlue)
		)
		.animation(.easeInOut, value: viewModel.state)
    }
	
	func saveRecordingSession() {
		guard let recordingSession = self.viewModel.currentRecordingSession else { return }
		let audioSegments = viewModel.audioSegmentURLs.map { AudioSegment(fileURL: $0, session: recordingSession) }
		
		recordingSession.segments = audioSegments
		modelContext.insert(recordingSession)
		// Explicit save required due to a known SwiftData autosave bug in iOS 18 Simulator (Xcode 16)
		do {
			try modelContext.save()
		} catch {
			print("Save failed: \(error.localizedDescription)")
		}
	}
	
	func transcribeRecordingSession() {
		viewModel.transcribeRecord()
	}
}

#Preview {
	RecordingControlsView(
		viewModel: .init(
			audioRecorder: .init(),
			appleTranscription: .init(),
			transcriptionQueueManager: .init(
				primaryService: AppleTranscriptionService(),	// Need change
				fallbackService: AppleTranscriptionService()
			)
		)
	)
}
