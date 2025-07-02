//
//  AudioRecorder.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/2/25.
//

import AVFAudio

class AudioRecorder {
	private var engine = AVAudioEngine()
	private var file: AVAudioFile?
	private var isRecording = false
	
	func requestRecordPermission(completionHandler: @escaping ((Bool) -> Void)) {
		AVAudioApplication.requestRecordPermission(completionHandler: { granted in
			completionHandler(granted)
		})
	}

	func startRecording(to url: URL) throws {
		let session = AVAudioSession.sharedInstance()
		try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
		try session.setActive(true)

		let format = engine.inputNode.outputFormat(forBus: 0)
		file = try AVAudioFile(forWriting: url, settings: format.settings)

		engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
			try? self?.file?.write(from: buffer)
		}

		try engine.start()
		isRecording = true
	}

	func stopRecording() {
		engine.inputNode.removeTap(onBus: 0)
		engine.stop()
		isRecording = false
	}
}
