# Phase 00 — Basic Intent Parsing

---

## Goal

Convert transcript string into structured intent JSON using LLM.

---

## Input

* Transcript string from Whisper

Example:
"set alarm for 7 am"

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

## Scope (STRICT)

Include:

* Sending transcript to LLM
* Applying prompt
* Receiving raw output
* Logging response

Exclude:

* JSON parsing validation
* Error handling
* Retry logic
* Execution of intent

---

## Architecture

Transcript
↓
Prompt Builder
↓
LLMService
↓
Raw Output (string)

---

## Components

### LLMService

* Loads model
* Sends prompt
* Returns raw string

---

### PromptBuilder

* Injects transcript into system prompt
* Returns final prompt string

---

## Success Criteria

* LLM returns output for given input
* Output is visible in logs
* No crash during inference

---

## Logs

[Intent][Phase00] Input: {transcript}
[Intent][LLM] Prompt sent
[Intent][LLM] Raw output: {output}

---

## Test Cases

1. "set alarm for 7 am"
2. "call mom"
3. "what time is it"

---

## Status

[ ] Not Started
[ ] In Progress
[ ] Completed

---

## Notes

* Do NOT validate JSON yet
* Do NOT fix output issues yet
* This phase is ONLY to verify LLM pipeline works

---

