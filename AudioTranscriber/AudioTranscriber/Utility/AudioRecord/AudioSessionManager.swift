//
//  AudioSessionManager.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/5/25.
//

import AVFAudio

protocol AudioSessionManagerDelegate: AnyObject {
	func audioShouldPause()
	func audioShouldResume()
}

final class AudioSessionManager {
	weak var delegate: AudioSessionManagerDelegate?
	private let session = AVAudioSession.sharedInstance()

	init() {
		addObservers()
	}

	deinit {
		removeObservers()
	}

	private func addObservers() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleRouteChange(_:)),
			name: AVAudioSession.routeChangeNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleInterruption(_:)),
			name: AVAudioSession.interruptionNotification,
			object: nil
		)
	}

	private func removeObservers() {
		NotificationCenter.default.removeObserver(self)
	}

	@objc private func handleRouteChange(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
			return
		}

		let currentOutputs = session.currentRoute.outputs
		let isExternal = currentOutputs.contains {
			[.headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
		}

		switch reason {
		case .oldDeviceUnavailable, .routeConfigurationChange:
			print("Route changed — pause")
			delegate?.audioShouldPause()
		case .newDeviceAvailable:
			if isExternal {
				print("External device connected — resume")
				delegate?.audioShouldResume()
			}
		default:
			break
		}
	}

	@objc private func handleInterruption(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
			return
		}

		switch type {
		case .began:
			print("Interruption began — pause")
			delegate?.audioShouldPause()

		case .ended:
			let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt).map { AVAudioSession.InterruptionOptions(rawValue: $0) }?.contains(.shouldResume) ?? false

			if shouldResume {
				print("Interruption ended — resume")
				delegate?.audioShouldResume()
			}

		default:
			break
		}
	}
}
