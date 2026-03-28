# Phase 03 — Silence Detection + Final Transcript

## Goal

Automatically detect when the user stops speaking and finalize the transcript.

---

## Current Problem

- Recording continues indefinitely
- No clear “end of speech”
- Final transcript depends on manual stop

---

## Target Behavior

User taps mic  
↓  
User speaks  
↓  
Partial transcript updates (Phase 02)  
↓  
User stops speaking  
↓  
Silence detected  
↓  
Recording stops automatically  
↓  
Final transcript generated  

---

## Scope (STRICT)

Include:
- Silence detection using audio energy
- Automatic stop recording
- Final transcript generation

Exclude:
- Wake word detection
- Multi-language handling
- Advanced NLP corrections

---

## Approach

We detect silence using audio energy (RMS or amplitude threshold).

If audio level stays below threshold for a duration → stop recording.

---

## Key Parameters

- Silence threshold (energy level)
- Silence duration (e.g., 1.5–2 seconds)

---

## Components Affected

- AudioCaptureService → compute audio energy
- ViewModel → track silence duration
- State machine → transition to completed

---

## Success Criteria

- Recording stops automatically after silence
- Final transcript displayed
- No premature stopping while speaking

---

## Logs

[VoiceInput][Silence] Energy level: X  
[VoiceInput][Silence] Silence started  
[VoiceInput][Silence] Silence threshold reached → stopping  

---

## Risks

- Stopping too early (cutting speech)
- Not stopping at all
- Background noise affecting detection

---

## Status

[ ] Not Started
