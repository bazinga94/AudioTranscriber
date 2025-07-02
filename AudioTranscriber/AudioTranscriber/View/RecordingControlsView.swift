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
			do {
				try viewModel.startRecording()
			} catch {
				print("Audio save failed: \(error.localizedDescription)")
			}
		} label: {
			Label("Record", systemImage: "mic.fill")
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding()
		}
		.buttonStyle(.plain)
		.background(Color(UIColor.systemBlue))
    }
}

#Preview {
	RecordingControlsView(viewModel: .init())
}
