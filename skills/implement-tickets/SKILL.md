---
name: implement-tickets
description: Work through every open ticket unattended, one subagent per ticket running Matt Pocock's /implement, committing each and logging decisions for review.
disable-model-invocation: true
---

Requires Matt Pocock's skills (`mattpocock/skills`): `implement`, `tdd` and `code-review`, and the issue-tracker docs that `setup-matt-pocock-skills` writes to `docs/agents/`.

The user is away. Drain the ticket **frontier** one ticket at a time: each ticket goes to its own fresh subagent, you verify and commit-check its work, then recompute the frontier, since finishing a ticket can unblock the next. Run until the frontier is empty, then leave one review-notes file they read when they are back.

Arguments, if given, scope the run to a feature slug or a list of tickets. Otherwise take every open ticket in the repo.

## The decision rule

Applies to you and every subagent. On a blocker or ambiguity, take your own recommendation and log it. **Hard stop** on anything that risks the user's data, is irreversible, or acts outside the repo: any write to an external service, deploys, remote shells, pushes, deleting anything outside git. For a hard stop, read-only lookups are fine; write the exact proposed change (and a numbered click-list where a human must do it) into the ticket's comments and leave that part for the user.

## Steps

1. **Sync before work.** Run `git fetch origin`, then `git pull --ff-only` on the current branch. Then check `origin/main` for work finished elsewhere: `git log HEAD..origin/main`, plus each ticket file as it stands there (`git show origin/main:<path>`). A ticket resolved on main counts as resolved. If main holds commits the branch lacks, merge `origin/main` into the branch. If the pull is not a fast-forward or the merge conflicts, run `git merge --abort` if a merge is in progress, keep the branch as it was, log it under **Needs your call**, and leave tickets resolved on main (and their dependents) out of the run. Done when the branch matches its remote and you can name every ticket already resolved on main.

2. **Map the tickets.** Read the repo's `AGENTS.md` and `docs/agents/issue-tracker.md` to learn where tickets live and how status and blocking are recorded. List every ticket with its status and blockers. Done when you can name the frontier: tickets that are `ready-for-agent` with every blocker resolved, ordered by ticket number.

3. **Check usage.** Skip this step if the environment variable `USAGE_GATE_CMD` is unset or empty. Otherwise run it in a shell before every dispatch, the first included. Exit 0 means continue. Any other exit, or a command that cannot run, means stop: do not dispatch, go to step 7, record "stopped by usage gate" with the command's output, and end the run. Never interrupt a ticket already in flight; the check happens only between tickets. Done when the command exited 0 or the run has gone to step 7.

4. **Dispatch the next frontier ticket.** Spawn one subagent with `model: "sonnet"` (the default; use another model if the user asked for one), in the foreground, with the brief below filled in. Wait for its hand-back before anything else.

5. **Verify the hand-back.** The report is a claim. Check it yourself: the working tree is clean, the commit exists, the full test suite passes when you run it, and any checkable acceptance box (a search that must come back empty, a file that must be gone) holds. Fix small gaps yourself or send them back to the same subagent with `SendMessage`. Done when every claim you can check is confirmed.

6. **Recompute the frontier** and return to step 3. A ticket left `ready-for-human` by a hard stop blocks its dependents only as far as they need the stopped part: if the dependency's repo side is done and going ahead is reversible, proceed and log the call for the user. Done when the frontier is empty.

7. **Write the review notes** to `review-notes.md` in the feature's ticket folder (or the repo's equivalent), and commit them. Sections, each kept to what applies:
   - **Stopped early**: only when the usage gate closed. "Stopped by usage gate", the command's output, and the frontier tickets left undone.
   - **Needs your call**: hard stops awaiting the user's yes, and calls you made that they may want to overturn.
   - **Decisions taken without you (reversible)**: one line each, gathered from every hand-back.
   - **Unverified**: what only a real system run can prove.
   - **To deploy**: numbered steps for the user.
   - **Commits** and final test counts.

8. **Report in chat**: one table of ticket, commit, state; then the user's calls, the unverified items, and the deploy steps, each pointing at the review notes. If the usage gate stopped the run, say so first.

## Subagent brief

Fill in the bracketed parts. The subagent starts cold, so the brief carries everything.

```
Implement one ticket in the repo at [repo path], on branch [branch]; stay on it.
The user is away. Work autonomously.

Ticket: [ticket path]. Spec: [spec path]. Read both fully, plus AGENTS.md,
the glossary or domain docs, docs/agents/*.md, and the code the ticket touches.
[Context from earlier tickets: commits, new helpers, anything already removed,
and any call you made on a blocker this ticket depends on.]

Follow ~/.claude/skills/implement/SKILL.md, and the tdd and code-review skills it
names (read their SKILL.md files under ~/.claude/skills if the Skill tool cannot
reach them). Review the diff since [last commit].

Decision rule: [paste "The decision rule" section verbatim].
[Ticket-specific hard stops, e.g. "the shared doc needs the user's yes: read it,
propose the change in the ticket comments, write nothing".]

When done:
- Tick the acceptance boxes you completed. Set the status to resolved only if
  every box is done, otherwise ready-for-human.
- Append a dated hand-back under ## Comments in the ticket.
- Commit: "Resolve ticket NN: <what>", or "Ticket NN: <what>" if anything is left.
- Rebuild any uploadable artifact the repo's conventions call for.

Report back, concise:
1. Commit hash and files changed
2. Acceptance boxes done vs left, and why
3. Every decision you made on your own, one line each
4. Test results, pass and fail counts per suite
5. Anything the user must do to deploy or verify
```
