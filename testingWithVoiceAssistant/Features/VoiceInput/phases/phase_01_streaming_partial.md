# Phase 01 — Streaming + Partial Transcripts

## Goal

Show transcript WHILE user is speaking (real-time)

---

## Current Limitation

- Transcription only happens AFTER recording stops
- No live feedback

---

## Target Behavior

User taps mic  
↓  
User speaks  
↓  
Transcript updates continuously  
↓  
User sees words appearing live  

---

## Scope (STRICT)

Include:
- Continuous audio processing
- Partial transcript updates

Exclude:
- Silence detection
- Final transcript optimization
- Performance tuning

---

## Approach

Replace:

Batch recording → Whisper once

With:

Streaming loop:
Audio chunks → Whisper → Partial transcript

---

## Required Changes

### Audio Layer
- Instead of accumulating full `[Float]`
- Emit small chunks (e.g. 1 sec)

---

### Whisper Layer
- Accept incremental audio
- Avoid reprocessing entire audio each time

---

### ViewModel
- Update `transcript` continuously

---

## Success Criteria

- Transcript updates while speaking
- No UI freeze
- No crash

---

## Logs

[VoiceInput][Streaming] Chunk received  
[VoiceInput][Streaming] Partial transcript updated  

---

## Risks

- Reprocessing same audio repeatedly
- UI flickering
- High CPU usage

---

## Status

[ ] Not Started
