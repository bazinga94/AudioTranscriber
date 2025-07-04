//
//  AudioRecorder.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import AVFAudio
import Combine

class AudioRecorder {
	private var engine: AVAudioEngine
	private var segmentWriter: AudioSegmentWriter?
	private var isRecording = false
	
	private let audioSegmentSubject: PassthroughSubject<URL, Never> = .init()
	var audioSegmentPublisher: AnyPublisher<URL, Never> {
		audioSegmentSubject
			.eraseToAnyPublisher()
	}
	
	init(engine: AVAudioEngine = AVAudioEngine()) {
		self.engine = engine
	}
	
	func checkRecordPermissionNeeded(completionHandler: @escaping ((Bool) -> Void)) {
		let permission = AVAudioApplication.shared.recordPermission
		
		switch permission {
		case .undetermined:
			requestRecordPermission { granted in
				completionHandler(granted)
			}
		case .denied:
			completionHandler(false)
		case .granted:
			completionHandler(true)
		@unknown default:
			completionHandler(false)
		}
	}
	
	private func requestRecordPermission(completionHandler: @escaping ((Bool) -> Void)) {
		AVAudioApplication.requestRecordPermission(completionHandler: { granted in
			completionHandler(granted)
		})
	}

	func startRecording() throws {
		let session = AVAudioSession.sharedInstance()
		try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
		try session.setActive(true)

		let format = engine.inputNode.outputFormat(forBus: 0)
		segmentWriter = AudioSegmentWriter(format: format)
		segmentWriter?.delegate = self
		segmentWriter?.createNewFile()

		engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
			self?.segmentWriter?.write(buffer, time: time)
		}

		try engine.start()
		isRecording = true
	}

	func stopRecording() {
		engine.inputNode.removeTap(onBus: 0)
		engine.stop()
		segmentWriter?.stop()
		isRecording = false
	}
}

extension AudioRecorder: AudioSegmentWriterDelegate {
	func didCreateSegmentAt(url: URL) {
		audioSegmentSubject.send(url)
	}
}
