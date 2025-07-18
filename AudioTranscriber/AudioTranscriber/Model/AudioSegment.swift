//
//  AudioSegment.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/3/25.
//

import Foundation
import SwiftData

@Model
class AudioSegment {
	@Attribute(.unique) var id: UUID
	var fileURL: URL
	var transcriptionText: String?
	var createdAt: Date

	@Relationship var session: RecordingSession

	init(fileURL: URL, createdAt: Date = .now, session: RecordingSession) {
		self.id = UUID()
		self.fileURL = fileURL
		self.createdAt = createdAt
		self.session = session
	}
}
