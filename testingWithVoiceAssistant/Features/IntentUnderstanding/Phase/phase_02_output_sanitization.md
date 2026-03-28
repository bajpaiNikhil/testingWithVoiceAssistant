# Phase 02 — Output Sanitization + Normalization

---

## Goal

Convert raw LLM output into clean, valid, structured JSON.

---

## Current Issues

* Prefix tokens: <|assistant|>
* Extra explanation text after JSON
* Partial / inconsistent JSON structure

---

## Target Output

{
"intent": "SetAlarm",
"entities": {
"time": "07:00",
"contact": null,
"message": null,
"app": null,
"destination": null
},
"response": "Setting an alarm for 7 AM."
}

---

## Scope (STRICT)

Include:

* Remove special tokens (<|assistant|>)
* Extract valid JSON block
* Fill missing fields
* Normalize intent values

Exclude:

* Retry logic
* Prompt changes
* Model changes

---

## Step 1 — Clean Raw Output

Remove:

* <|assistant|>
* leading/trailing noise

---

## Step 2 — Extract JSON

* Find first `{`
* Find matching `}`
* Extract substring

---

## Step 3 — Fix Missing Fields

Ensure entities always contain:

* time
* contact
* message
* app
* destination

Missing → null

---

## Step 4 — Normalize Intent

Map:

Call → CallContact
Alarm → SetAlarm

---

## Step 5 — Normalize Values

* "mom" → "Mom"
* Trim spaces
* Ensure formatting

---

## Success Criteria

* Always valid JSON
* No extra text
* Schema always complete

---

## Logs

[Intent][Phase02] Raw output
[Intent][Phase02] Cleaned output
[Intent][Phase02] Extracted JSON
[Intent][Phase02] Final normalized JSON

---

## Status

[ ] Not Started
[ ] In Progress
[ ] Completed

---
