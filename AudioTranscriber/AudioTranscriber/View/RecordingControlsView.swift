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
		HStack(spacing: 16) {
			// Toggle button (Record / Pause / Resume)
			Button {
				viewModel.toggleRecordingState()
			} label: {
				Label(
					viewModel.toggleButtonLabel,
					systemImage: viewModel.toggleButtonIcon
				)
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding()
				.background(viewModel.toggleButtonColor)
				.clipShape(Capsule())
			}

			// Stop button (only visible when not idle)
			if viewModel.state != .idle {
				Button {
					viewModel.stopRecordingAndSave()
					saveRecordingSession()
					viewModel.transcribeRecord()
				} label: {
					Label("Stop", systemImage: "stop.fill")
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(Color.red)
						.clipShape(Capsule())
				}
			}
		}
		.padding()
//		.animation(.easeInOut, value: viewModel.state)
	}

	private func saveRecordingSession() {
		guard let recordingSession = viewModel.currentRecordingSession else { return }

		let segments = viewModel.audioSegmentURLs.map {
			AudioSegment(fileURL: $0, session: recordingSession)
		}
		recordingSession.segments = segments
		modelContext.insert(recordingSession)

		do {
			try modelContext.save()
		} catch {
			print("Save failed: \(error)")
		}
	}
}


#Preview {
	RecordingControlsView(
		viewModel: .init(
			audioRecorder: .init(),
			appleTranscription: .init(),
			transcriptionQueueManager: .init(
				primaryService: WhisperTranscriptionService(),
				fallbackService: AppleTranscriptionService()
			)
		)
	)
}
