//
//  TranscriptionQueueManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Foundation

protocol TranscriptionTask {
	var segment: AudioSegment { get set }
	var retryCount: Int { get set }
}

struct AudioTranscriptionTask: TranscriptionTask, @unchecked Sendable {
	var segment: AudioSegment
	var retryCount: Int
	
	init(segment: AudioSegment) {
		self.segment = segment
		self.retryCount = 0
	}
}

actor TranscriptionQueueManager {
	private var queue: [TranscriptionTask]
	private let primaryService: TranscriptionService
	private let fallbackService: TranscriptionService
	
	private let maxConcurrentTasks: Int = 5
	private let maxRetryCount: Int = 5
	private var currentRunning: Int
	
	init(
		primaryService: TranscriptionService,
		fallbackService: TranscriptionService
	) {
		self.queue = []
		self.primaryService = primaryService
		self.fallbackService = fallbackService
		self.currentRunning = 0
	}
	
	func add(task: TranscriptionTask) async {
		queue.append(task)
		await processTaskIfPossible()
	}
	
	private func processTaskIfPossible() async {
		if currentRunning >= maxConcurrentTasks || queue.isEmpty {
			return
		}
		
		var next = queue.removeFirst()
		currentRunning += 1
		
		defer {
			Task {
				await taskFinished()
			}
		}
		
		do {
			let fileURL = next.segment.fileURL
			let service: TranscriptionService = next.retryCount >= maxRetryCount ? fallbackService : primaryService
			let result = try await service.transcribe(fileURL: fileURL)

			next.segment.transcriptionText = result
			next.segment.session.generateFullTranscription()
			try next.segment.modelContext?.save()
		} catch {
			switch error {
			case AppleTranscriptionError.notAvailable:
				print("Transcription service not available.")
				
			case AppleTranscriptionError.speechRecognitionFailed(let underlyingError):
				print("Speech recognition failed: \(underlyingError)")
				
			default:
				print("Unknown error: \(error)")
				next.retryCount += 1
				queue.append(next)
			}
		}
		
//		try await Task.sleep(nanoseconds: 3_000_000_000) // 3 second delay
	}
	
	private func taskFinished() async {
		currentRunning -= 1
		await processTaskIfPossible()
	}
}
