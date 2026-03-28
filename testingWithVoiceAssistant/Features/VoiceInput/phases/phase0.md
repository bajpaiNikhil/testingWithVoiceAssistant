# Phase 00 — Vertical Slice (Mic → Transcript)

## Goal

When user taps mic and speaks, show transcript on screen.

---

## Scope (STRICT)

Include:

- Mic button
- Permission
- Audio capture
- Whisper inference (basic)
- Show transcript

Exclude:

- RingBuffer
- Streaming optimization
- Silence detection
- Performance tuning

---

## Approach

- Record small chunks
- Send directly to Whisper
- Update UI with result

---

## Success Criteria

- Tap mic → recording starts
- Speak → text appears
- No crash

---

## Logs

[Feature:VoiceInput][Flow] Recording started  
[Feature:VoiceInput][Flow] Audio received  
[Feature:VoiceInput][Flow] Transcript updated  

---

## Status

[ ] Not Started  