//
//  RecordingControlsView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI

struct RecordingControlsView: View {
	@StateObject var viewModel: RecordingControlsViewModel
	
	init(viewModel: RecordingControlsViewModel) {
		self._viewModel = StateObject(wrappedValue: viewModel)
	}
	
    var body: some View {
		Button {
			Task {
				switch viewModel.state {
				case .idle:
					viewModel.state = .recording
					
					let granted = await viewModel.checkRecordPermission()
					
					if granted {
						do {
							try viewModel.startRecording()
						} catch {
							print("Audio save failed: \(error.localizedDescription)")
						}
					}
				case .recording:
					viewModel.state = .idle
					
					viewModel.stopRecording()
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
}

#Preview {
	RecordingControlsView(viewModel: .init(, modelContext: <#ModelContext#>))
}
