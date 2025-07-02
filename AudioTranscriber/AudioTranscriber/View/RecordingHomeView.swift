//
//  RecordingHomeView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import SwiftData

struct RecordingHomeView: View {
	@StateObject var viewModel: RecordingHomeViewModel
	
	init(viewModel: RecordingHomeViewModel) {
		self._viewModel = StateObject(wrappedValue: viewModel)
	}
	
	var body: some View {
		NavigationStack {
			VStack {
				RecordingListView()
			}
			.safeAreaInset(edge: .bottom) {
				RecordingControlsView(viewModel: .init())
			}
		}
	}
}

#Preview {
	RecordingHomeView(viewModel: .init())
}
