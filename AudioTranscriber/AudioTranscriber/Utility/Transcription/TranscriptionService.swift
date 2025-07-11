//
//  TranscriptionService.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Foundation

protocol TranscriptionService: Sendable {
	func transcribe(fileURL: URL) async throws -> String
}
