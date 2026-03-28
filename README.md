# VoiceAssistant — On-Device Voice Intelligence for iOS

A fully offline, privacy-first voice assistant built in Swift. No cloud. No API keys. Everything runs on-device.

The app is being built feature-by-feature in a phased, modular architecture. The first feature — **VoiceInput** — is complete and shipped. Remaining features are in active development.

---

## What's Live Right Now

**Feature: VoiceInput** — mic-to-text transcription powered by a local Whisper model.

Tap the mic. Speak. Watch your words appear on screen in real time. Stop speaking — the app detects your silence and finalises the transcript automatically. Fully offline. No network call is ever made.

---

## Pipeline: Mic → RingBuffer → Whisper → Text

```
┌─────────────────────────────────────────────────────────────────────┐
│                  VOICE INPUT PIPELINE                               │
│                                                                     │
│  ┌─────────────┐                                                    │
│  │  User Mic   │  Air pressure → diaphragm → voltage                │
│  └──────┬──────┘                                                    │
│         │ AVAudioSession (.record, .measurement)                    │
│         ▼                                                           │
│  ┌──────────────────────────────────┐                               │
│  │        AVAudioEngine             │                               │
│  │  inputNode tap (4096 samples)    │                               │
│  │  Native format: 48kHz stereo     │                               │
│  └──────────────┬───────────────────┘                               │
│                 │                                                   │
│                 ▼                                                   │
│  ┌──────────────────────────────────┐                               │
│  │       AVAudioConverter           │                               │
│  │  → 16kHz mono float32           │  Required by Whisper.cpp       │
│  └──────────────┬───────────────────┘                               │
│                 │ [Float] @ 16kHz                                   │
│                 ▼                                                   │
│  ┌──────────────────────────────────┐                               │
│  │    AudioCaptureService           │                               │
│  │  Accumulates frames              │                               │
│  │  Fires onChunk every 48k frames  │  = 3 seconds of audio         │
│  └──────────────┬───────────────────┘                               │
│                 │ onChunk([Float]) callback                         │
│                 ▼                                                   │
│  ┌──────────────────────────────────┐                               │
│  │    RingBuffer (480k capacity)    │  = 30-second rolling window   │
│  │  append() — trims if over cap    │                               │
│  │  readNewChunk() — only new data  │  readIndex cursor             │
│  └──────────────┬───────────────────┘                               │
│                 │ New [Float] frames only                           │
│                 ▼                                                   │
│  ┌──────────────────────────────────┐                               │
│  │  TranscriptViewModel             │                               │
│  │                                  │                               │
│  │  ┌──────────────────────────┐    │                               │
│  │  │  computeEnergy() — RMS   │    │  Silence detection            │
│  │  │  < 0.01 for >= 1.5s      │    │  → finalizeTranscript()       │
│  │  └──────────────────────────┘    │                               │
│  │                                  │                               │
│  │  ┌──────────────────────────┐    │                               │
│  │  │   WhisperEngine          │    │  Local inference              │
│  │  │   whisper.base, greedy   │    │  ~200ms per chunk             │
│  │  │   English, 4 threads     │    │  No fallback, no context      │
│  │  └──────────────────────────┘    │                               │
│  │                                  │                               │
│  │  ┌──────────────────────────┐    │                               │
│  │  │  mergeTranscript()       │    │  Deduplication                │
│  │  │  Prefix match            │    │  Prevents flickering          │
│  │  │  Suffix dedup            │    │  No repeated words            │
│  │  └──────────────────────────┘    │                               │
│  └──────────────┬───────────────────┘                               │
│                 │ @Observable transcript                            │
│                 ▼                                                   │
│  ┌──────────────────────────────────┐                               │
│  │      TranscriptView (SwiftUI)    │                               │
│  │  idle → recording → processing  │                                │
│  │       → completed / error       │                                │
│  └──────────────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Architecture

This project uses a **feature-based modular architecture**.

```
testingWithVoiceAssistant/
├── Features/
│   ├── VoiceInput/              ← ✅ Shipped
│   │   ├── AudioCaptureService.swift
│   │   ├── RingBuffer.swift
│   │   ├── TranscriptViewModel.swift
│   │   ├── TranscriptView.swift
│   │   ├── claude.md
│   │   └── phases/
│   │       ├── phase0.md
│   │       ├── phase_01_streaming_partial.md
│   │       ├── phase_02_ring_buffer.md
│   │       ├── phase_03_silence_detection.md
│   │       ├── phase_04_transcript_stabilization.md
│   │       └── phase_05_audio_hardening.md
│   │
│   └── IntentUnderstanding/     ← 🔜 Coming next
│       ├── claude.md
│       └── phases/
│           ├── phase_00_intent_parsing.md
│           ├── phase_01_prompt_stabilization.md
│           └── phase_02_output_sanitization.md
│
└── WhisperEngine.swift          ← Shared inference wrapper
```

**Context hierarchy:** Root → Module → Feature

Each feature owns its logic completely. Features do not import each other — they communicate only through defined interfaces.

---

## VoiceInput — How It Was Built (Phase Log)

The feature was built in six explicit phases. Each phase compiled, ran, and was verified before the next one started.

| Phase | What Was Added | Why |
|-------|---------------|-----|
| Phase 0 | Vertical slice — mic → Whisper → text (one shot) | Prove the pipeline works end to end |
| Phase 1 | Streaming partial transcripts | Show live text while speaking, not just after stopping |
| Phase 2 | RingBuffer with readIndex cursor | Fix latency creep — prevent re-processing growing audio windows |
| Phase 3 | Silence detection via RMS energy | Auto-stop when user stops speaking (1.5s silence threshold) |
| Phase 4 | Transcript merge — prefix match + suffix dedup | Prevent flickering and word duplication between chunks |
| Phase 5 | Audio hardening | Handle interruptions, 60s timeout, AVAudioEngine restart failures |

---

## Key Technical Decisions

**16kHz mono float32 everywhere**
AVAudioEngine delivers native hardware format (typically 48kHz stereo PCM). `AVAudioConverter` normalises every buffer to 16kHz mono float32 before it touches the pipeline. Whisper.cpp requires this format — mismatching it causes silent accuracy degradation, not a crash.

**3-second chunks (48,000 frames)**
Whisper produces reliable output on inputs of ≥ 2 seconds. Below that, hallucination rate climbs sharply. At 3 seconds and `whisper.base`, inference completes in ~200ms on-device — within the 500ms end-to-end latency target.

**RingBuffer over plain array**
A plain accumulator grows indefinitely. By minute 2 of a session, inference input would be 120 seconds of audio fed through every 3 seconds. The `RingBuffer`'s `readIndex` cursor ensures `readNewChunk()` always returns exactly the delta since the last read — inference input stays a flat 3 seconds regardless of session length.

**Whisper flags tuned for streaming**

```swift
params.no_context       = true   // No cross-chunk conditioning → prevents hallucination loops
params.single_segment   = true   // One string output per call → predictable merge input
params.temperature_inc  = 0      // Disable fallback retries → caps inference at ~250ms
params.entropy_thold    = -1.0   // Disable entropy fallback
params.logprob_thold    = -1.0   // Disable logprob fallback
params.language         = .english // Skip language detection → saves ~100ms per chunk
```

**Transcript merge strategy**
Whisper re-transcribes context across chunks. Naive append produces duplicate words. Two strategies are applied in order:
1. **Prefix match** — if the new chunk is a superset of the old transcript, take the new string
2. **Suffix dedup** — find the longest word-level overlap between the tail of old and the head of new, append only the non-overlapping suffix

Both operate on normalised word arrays (lowercase, stripped punctuation) to be robust against Whisper's inconsistent capitalisation and punctuation between chunks.

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Mic capture latency | < 100ms |
| Whisper inference per chunk | < 300ms |
| UI update | < 50ms |
| End-to-end (speak → text) | < 500ms |

---

## State Machine

```
idle ──tap──▶ recording ──silence/manual stop──▶ processing ──▶ completed
                │                                                    │
                └──────────── error ◀──────────────────────────────┘
```

The `TranscriptViewModel` owns all state transitions. The view is purely reactive — it derives all display logic from `state` and `transcript`.

---

## Logging

All logs follow the format `[VoiceInput][Component] message` for easy filtering in the Xcode console.

```
[VoiceInput][AudioCaptureService] Recording started — input format: ...
[VoiceInput][RingBuffer] Appended 4096 frames — total: 48312, readIndex: 0
[VoiceInput][RingBuffer] Read new chunk: 48312 frames — readIndex now: 48312
[VoiceInput][WhisperEngine] Inference started — 48312 frames
[VoiceInput][WhisperEngine] Inference completed — result: "Hello world"
[VoiceInput][Silence] Energy: 0.003
[VoiceInput][Silence] Silence threshold reached → stopping
[VoiceInput][Transcript] Merged: "Hello world how are you"
[VoiceInput][Safety] Timeout triggered
```

---

## Roadmap

Features are built and pushed one at a time as each reaches production quality.

| Feature | Status | Description |
|---------|--------|-------------|
| VoiceInput | ✅ Shipped | Mic → Whisper → real-time transcript |
| IntentUnderstanding | 🔜 In development | Transcript → local LLM (Phi / Qwen) → structured intent JSON |
| ActionExecution | 📋 Planned | Execute intents (send message, set timer, open app) |
| TTSResponse | 📋 Planned | LLM response → on-device TTS → spoken reply |
| WakeWord | 📋 Planned | Always-on wake word detection without draining battery |

The planned full pipeline once all features ship:

```
Mic → [VoiceInput] → Transcript
                         ↓
              [IntentUnderstanding] → Intent JSON
                         ↓
              [ActionExecution] → Result
                         ↓
              [TTSResponse] → Spoken reply
```

---

## Requirements

- Xcode 15+
- iOS 17+
- Physical device required for microphone (simulator has no mic input)
- `whisper.base.bin` model file in the app bundle (not committed to this repo — see setup below)

## Setup

1. Clone the repo
2. Download `whisper.base.bin` from the [whisper.cpp releases](https://github.com/ggerganov/whisper.cpp) and add it to the Xcode project target
3. Add `NSMicrophoneUsageDescription` to `Info.plist` if not already present
4. Build and run on a physical device

---

