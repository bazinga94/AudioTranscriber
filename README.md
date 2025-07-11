# AudioTranscriber

### Summary

AudioTranscriber is an iOS app built with SwiftUI and Swift Concurrency that lets users record audio, transcribe it using Apple Speech and Whisper AI, and manage sessions with SwiftData.

### Requirements

- iOS 17.6+

### API Key Setup
To use the Whisper API transcription feature, you must add your OpenAI API Key to the app’s configuration:

1. Open `Info.plist`
2. Add a API key:
  > Key: OpenAIAPIKey, 
  > Value: Your API key

### Screenshots

> <img src="https://github.com/user-attachments/assets/de852fd3-c425-45a0-9d95-719d46aebb11" width="250"/>
> <img src="https://github.com/user-attachments/assets/7c95aeb2-0f01-43f8-85bf-4cd8d66798dc" width="250"/>
> <img src="https://github.com/user-attachments/assets/2e336454-8064-454b-9d6a-7562b2c721fd" width="250"/>
> <img src="https://github.com/user-attachments/assets/fd828fb0-2622-4471-8592-da32e4cdf55d" width="250"/>
> <img src="https://github.com/user-attachments/assets/82458699-dd78-4385-b528-38ec0bc60c19" width="250"/>

### Architecture Overview

- Follows **MVVM**
- `AudioRecorder`: manages `AVAudioEngine`
- `AudioSegmentWriter`: writes segmented audio(30 second) to disk
- `RecordingControlsViewModel`: handles recording state and permission flow
- `TranscriptionQueueManager`: an `actor` responsible for concurrent transcription with retry logic
- `WhisperTranscriptionService`: handles up to 5 concurrent transcriptions via Whisper API
- `AppleTranscriptionService`: fallback if Whisper API fails, Apple Speech-to-Text
- SwiftData models: `RecordingSession` and `AudioSegment` with a cascading relationship

### Audio System Design

- Audio is saved in **30-second segments** as `.m4a` files
- Monitors:
  - `AVAudioSession.routeChangeNotification` to detect headphone/Bluetooth connection changes
  - `AVAudioSession.interruptionNotification` to handle phone calls, Siri, etc.
- Automatically **pauses/resumes recording** based on hardware or system events
- Supports **background recording** using the `audio` background mode

### Data Model Design (SwiftData)

- `RecordingSession` has a one-to-many relationship with `AudioSegment` (with `cascade` delete)
- Each `AudioSegment` stores:
  - `fileURL`
  - `createdAt`
  - `transcriptionText`
- `fullTranscription` is dynamically generated by combining all segment texts in order

### Concurrency Handling

- `TranscriptionQueueManager` is implemented as an `actor` with:
  - a task queue and a `maxConcurrentTasks` limit
  - retry and fallback logic for transcription
- Uses `TaskGroup` for concurrent transcription of segments
- Applies `@MainActor` where needed
- Uses `Sendable` to make sure values passed between tasks are safe and won’t cause race conditions

### Known Issues & Future Improvements

- **Whisper API** was not fully tested due to credit limitations. If the API key is not properly set, transcription falls back to **Speech-to-Text** after 5 retries.
- Testing was skipped due to time constraints.
