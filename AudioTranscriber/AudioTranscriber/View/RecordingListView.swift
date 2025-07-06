//
//  RecordingListView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import SwiftData

struct RecordingListView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \RecordingSession.createdAt, order: .reverse) private var sessions: [RecordingSession]
	
    var body: some View {
		List {
			ForEach(sessions) { session in
				NavigationLink {
					RecordingDetailView(session: session)
				} label: {
					VStack(alignment: .leading, spacing: 10) {
						// Preview snippet
						Text(session.fullTranscription?.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60) ?? "No transcription available")
							.font(.body)
							.foregroundColor(.primary)
							.lineLimit(2)
						
						// Timestamp
						Text(session.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
							.font(.caption)
							.foregroundColor(.gray)
					}
					.padding(.vertical, 5)
				}
			}
			.onDelete(perform: deleteItems)
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				EditButton()
			}
		}
    }

	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			for index in offsets {
				modelContext.delete(sessions[index])
				// Explicit save required due to a known SwiftData autosave bug in iOS 18 Simulator (Xcode 16)
				do {
					try modelContext.save()
				} catch {
					print("Save failed: \(error.localizedDescription)")
				}
			}
		}
	}
}

#Preview {
	let config = ModelConfiguration(isStoredInMemoryOnly: true)
	let container = try! ModelContainer(for: RecordingSession.self, configurations: config)

	let context = container.mainContext
	let sample = RecordingSession(title: "Test Session", createdAt: Date())
	context.insert(sample)

	return RecordingListView()
		.modelContainer(container)
}
