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

	@Relationship(deleteRule: .cascade) var segments: [AudioSegment]

	init(id: UUID = UUID(), title: String? = nil, createdAt: Date = .now) {
		self.id = id
		self.title = title
		self.createdAt = createdAt
		self.segments = []
	}
}
