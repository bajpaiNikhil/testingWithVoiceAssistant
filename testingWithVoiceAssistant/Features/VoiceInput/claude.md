# Feature: Voice Input (WhisperFlow)

---

## Feature Scope

This module is responsible ONLY for:

* Capturing microphone input
* Streaming audio to Whisper
* Generating partial + final transcripts
* Displaying transcripts on screen

⚠️ Strict Boundary (Non-Negotiable):

This feature DOES NOT handle:

* Intent detection
* TTS (Text-to-Speech)
* Assistant logic
* Wake word detection
* Multilingual switching (future feature)

---

# Final User Outcome

User taps mic → speaks → sees live transcript → gets final text

---

# System Pipeline

AudioEngine
↓
RingBuffer
↓
WhisperEngine
↓
Partial Transcript
↓
Final Transcript
↓
UI Update

---

# Architecture Components

## AudioEngine

* Configures AVAudioSession
* Captures microphone input
* Produces audio buffers

## RingBuffer

* Stores streaming audio
* Maintains rolling window
* Prevents duplication

## WhisperEngine

* Loads Whisper model (`whisper.base`)
* Performs inference
* Generates partial + final transcripts

## TranscriptViewModel

* Controls state
* Coordinates pipeline
* Updates UI

## TranscriptView

* Mic button
* Transcript display

---

# Development Strategy (Phase-Based Execution)

Each phase MUST:

* Compile successfully
* Be independently testable
* Include logs
* Not break previous phases

---

## Phase 1 — UI: Microphone Button

### Goal

Display a tappable mic button

### Success Criteria

* Button visible
* Tap toggles state

---

## Phase 2 — Permissions

### Goal

Handle microphone permission

### Success Criteria

* Permission popup shown
* Proper handling of granted/denied

---

## Phase 3 — AudioEngine Setup

### Goal

Capture audio buffers

### Success Criteria

* Buffers received continuously

---

## Phase 4 — Audio Format Normalization

### Goal

Convert audio to:

* 16 kHz
* mono
* float32

### Success Criteria

* Correct format verified

---

## Phase 5 — RingBuffer

### Goal

Maintain streaming audio window

### Success Criteria

* No memory leaks
* No duplicated audio

---

## Phase 6 — Whisper Initialization

### Goal

Load model once

### Success Criteria

* Model loads without crash

---

## Phase 7 — Streaming Inference

### Goal

Run Whisper continuously

### Success Criteria

* Partial transcripts generated

---

## Phase 8 — Partial Transcript

### Goal

Show live transcription

### Success Criteria

* Text updates while speaking

---

## Phase 9 — Silence Detection

### Goal

Detect speech end

### Success Criteria

* Recording stops automatically

---

## Phase 10 — Final Transcript

### Goal

Generate final output

### Success Criteria

* Final transcript displayed

---

## Phase 11 — UI Integration

### Goal

Bind everything together

### Success Criteria

* Smooth UI updates
* No flickering

---

# 🔐 Guard Rails

## 1. Feature Isolation

* All logic must stay inside `VoiceInputFeature`
* No dependency on other features
* Communication only via defined interfaces

---

## 2. Phase Discipline

* Work on ONLY one phase at a time
* Do NOT skip phases
* Do NOT refactor unrelated code

---

## 3. Context Persistence

* Each phase must have its own file in `/phases`
* All decisions must be written in those files
* Claude must NOT rely on chat memory

---

## 4. Logging Requirement

All components MUST log using format:

[Feature][Component] message

Examples:

* [AudioEngine] Started
* [RingBuffer] Size updated
* [Whisper] Inference completed

---

## 5. Code Safety

* Do not break existing functionality
* Keep changes minimal and reversible
* Avoid large refactors

---

## 6. Definition of Completion (Per Phase)

A phase is complete ONLY if:

* Code compiles
* Logs are present
* Tests pass
* Behavior is verifiable

---

# 🧪 Testing Strategy

---

## 1. Testing Levels

### Unit Testing

Test components independently:

* RingBuffer read/write
* Audio format conversion
* Silence detection logic

---

### Integration Testing

Test flow between components:

* AudioEngine → RingBuffer
* RingBuffer → Whisper
* Whisper → ViewModel

---

### End-to-End Testing

Full user flow:

Tap mic → speak → transcript appears → final output shown

---

## 2. Manual Testing Checklist

For EVERY phase:

* Works on a real device
* Logs visible and correct
* No crashes
* Handles expected user behavior

---

## 3. Edge Case Testing

Must handle:

* Microphone permission denied
* Silent input
* Background/foreground transitions
* Long speech input
* Rapid start/stop tapping

---

## 4. Performance Testing

Measure:

* Mic latency < 100ms
* Partial transcript < 300ms
* UI update < 50ms

Target total latency: < 500ms

---

## 5. Regression Testing

Before moving to the next phase:

* Re-test all previous phases
* Ensure no functionality breaks

---

## 6. Debugging Strategy

If failure occurs:

1. Check logs first
2. Identify failing layer:

   * AudioEngine
   * RingBuffer
   * WhisperEngine
3. Fix without breaking the pipeline

---

# State Management

States:

* Idle
* RequestingPermission
* Recording
* Processing
* Completed
* Error

---

# Failure Handling

Must handle:

* Permission denied
* AudioEngine failure
* Model load failure
* No speech detected
* App backgrounding

---

# Recovery Strategy

On restart or crash:

* Reinitialize model
* Reset buffers
* Return UI to Idle

---

# Performance Targets

* Mic capture < 100 ms
* Whisper inference < 300 ms
* UI update < 50 ms

End-to-end: < 500 ms

---

# Future Extensions (Out of Scope)

* Wake word detection
* Intent recognition
* Sarvam / multilingual support
* TTS response

---

# Definition of Done

✔ Tap mic → recording starts
✔ Speak → partial transcript visible
✔ Stop speaking → final transcript shown
✔ Works offline
✔ No crashes
✔ Logs available
✔ All tests pass

---
