//
//  RecordingDetailView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/5/25.
//

import SwiftUI

struct RecordingDetailView: View {
	let session: RecordingSession
	
    var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Text("📅 Recorded on \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
					.font(.headline)
					.padding(.bottom, 8)

				// Individual Transcribed Segments
				ForEach(session.segments.sorted(by: { $0.createdAt < $1.createdAt })) { segment in
					VStack(alignment: .leading, spacing: 4) {
						Text(segment.createdAt.formatted(date: .omitted, time: .shortened))
							.font(.caption)
							.foregroundColor(.gray)

						Text(segment.transcriptionText ?? "[No recording]")
							.font(.body)
							.padding(8)
							.background(Color(.systemGray6))
							.cornerRadius(8)
					}
					.padding(.vertical, 0)
				}

				Divider()
					.padding(.vertical)

				// Full Transcription
				if let full = session.fullTranscription, !full.isEmpty {
					VStack(alignment: .leading, spacing: 8) {
						Text("📝 Full Transcription")
							.font(.title3)
							.bold()

						Text(full)
							.font(.body)
							.padding(8)
							.background(Color(.secondarySystemBackground))
							.cornerRadius(10)
					}
				}

				Spacer()
			}
			.padding()
		}
		.navigationTitle(session.title ?? "Session")
		.navigationBarTitleDisplayMode(.inline)

    }
}

#Preview {
	RecordingDetailView(session: .init())
}
