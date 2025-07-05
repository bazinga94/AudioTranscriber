//
//  AudioRecorder.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import AVFAudio
import Combine

class AudioRecorder {
	enum RecordingStatus {
		case idle
		case recording
		case paused
	}
	
	private var engine: AVAudioEngine
	private var segmentWriter: AudioSegmentWriter?
	private let audioSegmentSubject: PassthroughSubject<URL, Never> = .init()
	
	var audioSegmentPublisher: AnyPublisher<URL, Never> {
		audioSegmentSubject
			.eraseToAnyPublisher()
	}
	
	private(set) var status: RecordingStatus = .idle
	
	init(engine: AVAudioEngine = AVAudioEngine()) {
		self.engine = engine
	}

	func startRecording() throws {
		let session = AVAudioSession.sharedInstance()
		try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
		try session.setActive(true)

		let format = engine.inputNode.outputFormat(forBus: 0)
		segmentWriter = AudioSegmentWriter(format: format)
		segmentWriter?.delegate = self
		segmentWriter?.createNewFile()

		engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
			self?.segmentWriter?.write(buffer, time: time)
		}

		try engine.start()
		status = .recording
	}

	func pauseRecording() {
		guard status == .recording else { return }
		engine.pause()
		status = .paused
	}

	func resumeRecording() throws {
		guard status == .paused else { return }
		try engine.start()
		status = .recording
	}

	func stopRecording() {
		engine.inputNode.removeTap(onBus: 0)
		engine.stop()
		segmentWriter?.stop()
		status = .idle
	}
}

extension AudioRecorder: AudioSegmentWriterDelegate {
	func didCreateSegmentAt(url: URL) {
		audioSegmentSubject.send(url)
	}
}
