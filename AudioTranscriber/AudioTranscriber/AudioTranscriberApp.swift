//
//  AudioTranscriberApp.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import SwiftUI
import SwiftData

@main
struct AudioTranscriberApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
			RecordingSession.self,
			AudioSegment.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
			RecordingHomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
