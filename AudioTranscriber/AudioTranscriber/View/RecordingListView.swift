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
					Text("Session recorded on \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
				} label: {
					VStack(alignment: .leading) {
						Text(session.title ?? "Untitled")
						Text(session.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
					}
				}
			}
			.onDelete(perform: deleteItems)
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				EditButton()
			}
			ToolbarItem {
				Button(action: addItem) {
					Label("Add Item", systemImage: "plus")
				}
			}
		}
    }
	
	private func addItem() {
		withAnimation {
			let session = RecordingSession(title: "New Session", createdAt: Date())
			modelContext.insert(session)
			// Explicit save required due to a known SwiftData autosave bug in iOS 18 Simulator (Xcode 16)
			do {
				try modelContext.save()
			} catch {
				print("Save failed: \(error.localizedDescription)")
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
