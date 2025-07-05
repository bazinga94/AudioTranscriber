//
//  RecordingHomeView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import SwiftData

struct RecordingHomeView: View {
	var body: some View {
		NavigationStack {
			VStack {
				RecordingListView()
			}
			.safeAreaInset(edge: .bottom) {
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
		}
	}
}

#Preview {
	RecordingHomeView()
}
