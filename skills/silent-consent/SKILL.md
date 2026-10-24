---
name: silent-consent
description: Switch the current session to silent consent. Applies to any session that asks numbered questions with recommendations (grilling, triage, a PRD interview). Unanswered questions default to the recommendation only when the user answers at least one question in the round.
disable-model-invocation: true
---

Change the answering protocol for the rest of this session. It applies to any
session that asks numbered questions with recommendations: grilling, triage, a
PRD interview, or any other. Everything else about the session (the skill
driving it, its side effects, its output) is unchanged.

**Silent consent.** From the next round on, the user replies only to questions
where they disagree with your recommended answer or want to reshape the
question. When the reply answers at least one question in the round, any
question they don't mention is settled at the recommendation you gave. When it
answers none, nothing is settled by default.

**Reminder.** Every turn that asks one or more numbered questions ends with
this line, word for word and as the last thing in the turn, including when you
ask a question again:

> 🔕 Silent consent: I'll go with the recommended option ➡️ for any question you don't answer, as long as you answer at least one.

**What counts as answered.** A question is answered only when the reply points
at it clearly: by its number, by its title, or by content that can only mean
that question. A vague comment answers nothing. A reply that only asks about a
question ("what do you mean by X in Q3?") does not answer it.

A blanket approval ("all good", "yes", "lgtm", "go with your recs") answers
every question in the round at its recommendation. Those answers are stated
by the user, not assumed: do not echo them with `✅`, and do not label them as
assumed in any doc.

**The gate.** Read the reply against the round:

- If it answers at least one question (a blanket approval counts), every
  question it doesn't mention is assumed at the recommendation. A question the
  user only asked about stays open and is not assumed. Carry on with the steps
  below.
- If it answers none (a side comment, a new topic, "let me think"), assume
  nothing, skip the steps below, and do these in order: (1) say exactly
  `Nothing assumed this turn: no question answered.`, (2) respond to what the
  user said, (3) ask every open question again in the full round format,
  ending with the reminder.

A round with a single question follows the same gate: answering it settles
it, and not answering it is a sidestep.

When a round comes back and the gate passes:

1. Echo every assumed question (not the ones the user answered or approved) as
   `✅ Q<n> — <concise version of recommended answer>` before moving on, so
   assumed answers are visible rather than silent. Compress the
   recommendation to the decision itself — one line, no restated question, no
   reasoning, no hedge. If a recommendation cannot survive that compression,
   it was too vague to be defaulted to; ask it again rather than assuming it.
2. Fold explicit and assumed answers into the tree together, recompute the
   frontier, ask the next round. Ask a question the user only asked about
   again, with the clarification included.

Because a skipped question is a real decision, your recommendation must be
strong enough to default to: pick a side, don't hedge, never recommend
"it depends".

If this session writes to `GLOSSARY.md` or ADRs, an assumed answer must be
labelled as assumed in the resulting doc, not written as though the user
stated it.
