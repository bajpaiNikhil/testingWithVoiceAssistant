# Phase 03 — Retry + Fallback

---

## Goal

Ensure system NEVER fails even if LLM output is invalid.

---

## Current Problem

* Sometimes no JSON is returned
* Sometimes parsing fails

---

## Target Behavior

If LLM fails:

1. Retry once with stricter prompt
2. If still fails → return fallback JSON

---

## Fallback Output

{
"intent": "Unknown",
"entities": {
"time": null,
"contact": null,
"message": null,
"app": null,
"destination": null
},
"response": "Sorry, I didn’t understand that."
}

---

## Scope

Include:

* Retry mechanism (1 retry only)
* Fallback response

Exclude:

* Changing prompt structure
* Changing model

---

## Logic

1. Run LLM
2. Try extract JSON
3. If fails:
   → retry once
4. If still fails:
   → return fallback

---

## Logs

[Intent][Retry] Attempt 1 failed
[Intent][Retry] Retrying
[Intent][Fallback] Returning default response

---

## Success Criteria

* No crashes ever
* Always returns valid JSON
* Handles bad inputs gracefully

---

## Status

[ ] Not Started
