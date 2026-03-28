# Phase 01 — Prompt Stabilization

---

## Goal

Force LLM to ALWAYS return valid structured JSON.

---

## Current Problem

LLM is returning natural language:

"Alarm set for 7:00 AM."

Instead of structured JSON.

---

## Target Behavior

Input:
"set alarm for 7 am"

Output:

{
"intent": "SetAlarm",
"entities": {
"time": "07:00",
"contact": null,
"message": null,
"app": null,
"destination": null
},
"response": "Setting alarm for 7 AM."
}

---

## Scope (STRICT)

Include:

* Improve prompt structure
* Add strict instructions
* Add more examples
* Add output enforcement rules

Exclude:

* JSON parsing validation
* Retry logic
* Error handling

---

## Approach

We will:

1. Strengthen system role
2. Add strict JSON rules
3. Add edge-case handling
4. Add more examples
5. Reduce model creativity

---

## Prompt Improvements

### Add Strong Constraints

* MUST return JSON
* MUST NOT return text
* MUST follow schema exactly

---

### Add Fallback Behavior

If input unclear:

{
"intent": "Unknown",
"entities": { all null },
"response": "Sorry, I didn’t understand that."
}

---

### Add More Examples

* Alarm
* Call
* Message
* Navigation
* App launch

---

## Success Criteria

* LLM returns JSON for ALL test inputs
* No plain text output
* No explanation text

---

## Logs

[Intent][Phase01] Input: {text}
[Intent][Prompt] Generated prompt
[Intent][LLM] Raw output: {output}

---

## Test Cases

1. "set alarm for 7 am"
2. "call mom"
3. "send message to Rahul"
4. "open youtube"
5. "navigate to airport"

---

## Status

[ ] Not Started
[ ] In Progress
[ ] Completed

---

## Notes

* This phase is ONLY about prompt quality
* Do NOT fix parsing yet
* Do NOT change architecture

---

