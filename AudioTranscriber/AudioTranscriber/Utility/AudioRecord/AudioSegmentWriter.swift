//
//  AudioSegmentWriter.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import AVFoundation

protocol AudioSegmentWriterDelegate: AnyObject {
	func didCreateAudio(audioMeta: AudioMeta)
}

class AudioSegmentWriter {
	private let format: AVAudioFormat
	private let directory: URL
	private var currentFile: AVAudioFile?
	
	private let segmentDuration: TimeInterval = 30
	private var recordingStartTime: AVAudioTime?
	
	weak var delegate: AudioSegmentWriterDelegate?

	init(format: AVAudioFormat, directory: URL = FileManager.default.temporaryDirectory) {
		self.format = format
		self.directory = directory
	}

	func write(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
		if recordingStartTime == nil {
			self.recordingStartTime = time
		}
		
		if let start = self.recordingStartTime,
		   let elapsedSeconds = time.seconds(since: start),
		   elapsedSeconds >= segmentDuration {

			self.recordingStartTime = time
			createNewFile()
		}

		try? currentFile?.write(from: buffer)

	}
	
	func stop() {
		currentFile = nil
		recordingStartTime = nil
	}

	func createNewFile() {
		let url = directory.appendingPathComponent("recording_segment_\(UUID().uuidString).m4a")
		currentFile = try? AVAudioFile(forWriting: url, settings: format.settings)
		delegate?.didCreateAudio(audioMeta: AudioMeta(url: url, createdAt: Date()))
	}
}

extension AVAudioTime {
	func seconds(since other: AVAudioTime) -> Double? {
		let samplesElapsed = self.sampleTime - other.sampleTime
		return Double(samplesElapsed) / self.sampleRate
	}
}
