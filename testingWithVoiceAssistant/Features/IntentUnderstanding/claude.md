# Feature: Intent Understanding (LLM Brain)

---

## Feature Scope

This feature converts user transcript into structured intent JSON using a local LLM.

---

## Input

* Transcript (string from Whisper)

---

## Output

Structured JSON:

{
"intent": string,
"entities": {
"time": string | null,
"contact": string | null,
"message": string | null,
"app": string | null,
"destination": string | null
},
"response": string
}

---

## Strict Responsibility

This feature ONLY:

* Parses intent
* Extracts entities
* Generates structured response

---

## Non-Goals

* No execution (no API calls)
* No UI updates
* No speech output

---

## Architecture

Transcript (Whisper)
↓
LLMService
↓
Prompt Engine
↓
LLM (Phi / Qwen)
↓
JSON Output
↓
Intent Model

---

## Development Strategy

We build this feature in phases:

---

### Phase 00 — Basic Intent Parsing

* Send transcript to LLM
* Receive JSON output

---

### Phase 01 — Prompt Stabilization

* Improve prompt reliability
* Reduce hallucinations
* Enforce strict JSON

---

### Phase 02 — Error Handling

* Handle invalid JSON
* Retry strategy
* Fallback responses

---

## Guard Rails

* LLM must NEVER return plain text
* Output must ALWAYS be valid JSON
* Unknown values → null
* No hallucinated intents

---

## Logging

[Intent][LLM] Prompt sent
[Intent][LLM] Raw output
[Intent][Parser] Parsed JSON
[Intent][Error] Invalid JSON

---

## Definition of Done

✔ Always returns valid JSON
✔ No crashes on malformed output
✔ Handles unknown input gracefully

---

