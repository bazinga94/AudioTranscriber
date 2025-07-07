//
//  WhisperTranscriptionService.swift
//  AudioTranscriber
//
//  Created by Jongho Lee on 7/4/25.
//

import Foundation

struct WhisperResponse: Decodable {
	let text: String
}

enum WhisperTranscriptionError: Error {
	case invalidResponse
	case decodingError
	case networkError(Error)
	case fileLoadFailed
}

final class WhisperTranscriptionService: TranscriptionService {
	private let apiKey: String

	init() {
		guard let apiKey = Bundle.main.infoDictionary?["OpenAIAPIKey"] as? String else {
			fatalError("OpenAIAPIKey is missing in Info.plist.")
		}
		self.apiKey = apiKey
	}

	func transcribe(fileURL: URL) async throws -> String {
		guard let audioData = try? Data(contentsOf: fileURL) else {
			throw WhisperTranscriptionError.fileLoadFailed
		}

		var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
		request.httpMethod = "POST"
		request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

		let boundary = UUID().uuidString
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

		let body = try createMultipartBody(boundary: boundary, fileData: audioData, fileName: fileURL.lastPathComponent)
		request.httpBody = body

		let (data, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			print("OpenAI Error Response: ")
			if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				print(errorResponse)
			}
			throw WhisperTranscriptionError.invalidResponse
		}

		do {
			let decoded = try JSONDecoder().decode(WhisperResponse.self, from: data)
			return decoded.text
		} catch {
			throw WhisperTranscriptionError.decodingError
		}
	}

	private func createMultipartBody(boundary: String, fileData: Data, fileName: String) throws -> Data {
		var body = Data()
		let lineBreak = "\r\n"

		body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
		body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!)
		body.append("Content-Type: audio/m4a\(lineBreak + lineBreak)".data(using: .utf8)!)
		body.append(fileData)
		body.append(lineBreak.data(using: .utf8)!)

		body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
		body.append("Content-Disposition: form-data; name=\"model\"\(lineBreak + lineBreak)".data(using: .utf8)!)
		body.append("whisper-1\(lineBreak)".data(using: .utf8)!)

		body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
		body.append("Content-Disposition: form-data; name=\"language\"\(lineBreak + lineBreak)".data(using: .utf8)!)
		body.append("en\(lineBreak)".data(using: .utf8)!)

		body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

		return body
	}
}
