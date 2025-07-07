//
//  TranscriptionQueueManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Foundation

struct AudioTranscriptionTask: @unchecked Sendable {
	var segment: AudioSegment
	var retryCount: Int
	
	init(segment: AudioSegment) {
		self.segment = segment
		self.retryCount = 0
	}
}

actor TranscriptionQueueManager {
	private var queue: [AudioTranscriptionTask]
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
	
	func add(task: AudioTranscriptionTask) async {
		queue.append(task)
		await processTaskIfPossible()
	}
	
	private func processTaskIfPossible() async {
		while currentRunning < maxConcurrentTasks && !queue.isEmpty {
			let next = queue.removeFirst()
			currentRunning += 1
			
			Task {
				await process(task: next)
			}
		}
	}
	
	private func process(task: AudioTranscriptionTask) async {
		var task = task
		
		defer {
			Task {
				await self.taskFinished()
			}
		}
		
		do {
			let fileURL = task.segment.fileURL
			let service: TranscriptionService = task.retryCount >= maxRetryCount ? fallbackService : primaryService
			let result = try await service.transcribe(fileURL: fileURL)
			
			task.segment.transcriptionText = result
			task.segment.session.generateFullTranscription()
			try task.segment.modelContext?.save()
			
		} catch {
			switch error {
			case AppleTranscriptionError.notAvailable:
				print("Transcription service not available.")
				
			case AppleTranscriptionError.speechRecognitionFailed(let underlyingError):
				print("Speech recognition failed: \(underlyingError)")
				
			default:
				print("Unknown error: \(error)")
				task.retryCount += 1
				print("Retry count: \(task.retryCount)")
				Task {
					try? await Task.sleep(nanoseconds: 3_000_000_000)	// 3 second safety delay
					await self.add(task: task)
				}
			}
		}
	}
	
	private func taskFinished() async {
		currentRunning -= 1
		await processTaskIfPossible()
	}
}
