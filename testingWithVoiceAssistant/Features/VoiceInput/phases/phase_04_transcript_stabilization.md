# Phase 04 — Transcript Stabilization + Merge Strategy

## Goal

Make partial transcripts stable and prevent flickering or duplication.

---

## Current Problem

- Partial transcripts change frequently
- Words may repeat
- UI flickers
- Poor user experience

---

## Target Behavior

User speaks  
↓  
Text appears smoothly  
↓  
Previous words remain stable  
↓  
New words append naturally  

---

## Scope (STRICT)

Include:
- Partial transcript stabilization
- Merge strategy for new text

Exclude:
- NLP corrections
- Grammar fixes
- Intent detection

---

## Approach

Instead of replacing the entire transcript:

We:
1. Keep a stable base transcript
2. Append only new confirmed words

---

## Strategy Options

### Option 1 — Simple Append (Phase 04.1)

- Append new chunk text
- Avoid replacing full transcript

---

### Option 2 — Prefix Matching (Phase 04.2)

- Compare old + new transcript
- Keep common prefix
- Append only new suffix

---

## Recommended Approach

Start with simple append → then upgrade to prefix matching

---

## Success Criteria

- No flickering text
- No repeated words
- Smooth reading experience

---

## Logs

[VoiceInput][Transcript] Old: X  
[VoiceInput][Transcript] New: Y  
[VoiceInput][Transcript] Merged: Z  

---

## Risks

- Missing words
- Duplicate words
- Incorrect merging logic

---

## Status

[ ] Not Started