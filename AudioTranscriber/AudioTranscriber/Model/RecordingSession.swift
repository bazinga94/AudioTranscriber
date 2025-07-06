//
//  RecordingSession.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/3/25.
//

import Foundation
import SwiftData

@Model
class RecordingSession {
	@Attribute(.unique) var id: UUID
	var createdAt: Date
	var title: String?
	var fullTranscription: String? = nil

	@Relationship(deleteRule: .cascade) var segments: [AudioSegment]

	init(id: UUID = UUID(), title: String? = nil, createdAt: Date = .now) {
		self.id = id
		self.title = title
		self.createdAt = createdAt
		self.segments = []
	}
}

extension RecordingSession {
	func generateFullTranscription() {
		self.fullTranscription = segments.sorted(by: { $0.createdAt < $1.createdAt })
			.compactMap { $0.transcriptionText?.trimmingCharacters(in: .whitespacesAndNewlines) }
			.joined(separator: " ")
	}
}
