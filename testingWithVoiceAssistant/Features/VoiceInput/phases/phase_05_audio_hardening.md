# Phase 05 — Audio Hardening

## Goal

Make the audio system robust and production-safe.

---

## Problems to Solve

- App goes to background → crash?
- User taps mic rapidly → race condition?
- Long speech → memory growth?
- No speech → hangs?

---

## Scope

Include:
- Safe start/stop handling
- Interruption handling
- Timeout for recording
- Memory safety

---

## Success Criteria

- No crashes in edge cases
- Stable behavior under stress
- Clean state transitions

---

## Logs

[VoiceInput][Safety] Recording interrupted  
[VoiceInput][Safety] Restart handled  
[VoiceInput][Safety] Timeout triggered  
