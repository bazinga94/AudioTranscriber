//
//  TranscriptionQueueManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Foundation

protocol TranscriptionTask {
	var segment: any AudioTranscribable { get set }
	var retryCount: Int { get set }
}

struct AudioTranscriptionTask: TranscriptionTask {
	var segment: any AudioTranscribable
	var retryCount: Int
	
	init(segment: any AudioTranscribable) {
		self.segment = segment
		self.retryCount = 0
	}
}

actor TranscriptionQueueManager {
	private var queue: [TranscriptionTask]
	private let primaryService: TranscriptionService
	private let fallbackService: TranscriptionService
	
	private let maxConcurrentTasks: Int = 5
	private let maxRetryCount: Int = 1
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
	
	func add(task: TranscriptionTask) {
		queue.append(task)
		processTaskIfPossible()
	}
	
	private func processTaskIfPossible() {
		if currentRunning >= maxConcurrentTasks || queue.isEmpty {
			return
		}
		
		var next = queue.removeFirst()
		currentRunning += 1
		
		Task {
			defer {
				taskFinished()
			}
			
			do {
				if next.retryCount >= maxRetryCount {
					let result = try await fallbackService.transcribe(fileURL: next.segment.fileURL)
					next.segment.transcriptionText = result
				} else {
					let result = try await primaryService.transcribe(fileURL: next.segment.fileURL)
					next.segment.transcriptionText = result
				}
				try next.segment.modelContext?.save()
			} catch {
				switch error {
				case TranscriptionError.notAvailable:
					print("Transcription service not available.")
					
				case TranscriptionError.speechRecognitionFailed(let underlyingError):
					print("Speech recognition failed: \(underlyingError)")
					
				default:
					print("Unknown error: \(error)")
					next.retryCount += 1
					queue.append(next)
				}
			}
		}
	}
	
	private func taskFinished() {
		currentRunning -= 1
		processTaskIfPossible()
	}
}
