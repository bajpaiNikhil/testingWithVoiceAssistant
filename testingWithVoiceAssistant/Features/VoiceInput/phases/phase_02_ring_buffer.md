# Phase 02 — RingBuffer + True Streaming

## Goal

Process ONLY new audio instead of reprocessing entire audio stream

---

## Current Problem

- Same audio is processed repeatedly
- Latency increases over time
- High CPU usage

---

## Target Behavior

Audio stream  
↓  
RingBuffer stores rolling window  
↓  
Whisper processes only NEW audio  
↓  
Transcript updates efficiently  

---

## Scope (STRICT)

Include:
- RingBuffer implementation
- Incremental audio consumption

Exclude:
- Silence detection
- Advanced optimization
- Multi-language

---

## Architecture Change

Before:

Audio → accumulate → Whisper(full)

After:

Audio → RingBuffer → Whisper(incremental)

---

## RingBuffer Responsibilities

- Append incoming audio frames
- Maintain rolling window (e.g. last 30 sec)
- Track read index
- Provide ONLY new audio chunks

---

## ViewModel Changes

- Stop sending full audio
- Request only new chunk from RingBuffer

---

## Success Criteria

- No repeated audio processing
- Stable latency over time
- Smooth transcript updates

---

## Logs

[VoiceInput][RingBuffer] Appended frames: X  
[VoiceInput][RingBuffer] Read new chunk: Y  

---

## Risks

- Audio duplication
- Missing audio segments
- Sync issues between buffer and Whisper

---

## Status

[ ] Not Started
