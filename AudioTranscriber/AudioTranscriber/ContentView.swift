//
//  ContentView.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
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
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
			modelContext.insert(newItem)
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
                modelContext.delete(items[index])
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
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
