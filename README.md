# mattpocock-skills-addons

Skills that extend [Matt Pocock's skills](https://github.com/mattpocock/skills). Each one calls one of his skills, or changes how one of his skills runs, so install his first.

## Install

Install Matt's skills first:

```bash
npx skills add mattpocock/skills
```

Then the add-ons:

```bash
npx skills add stevenrabulan/mattpocock-skills-addons
```

| What | Command |
| --- | --- |
| Preview without installing | `npx skills add stevenrabulan/mattpocock-skills-addons --list` |
| One skill | `npx skills add stevenrabulan/mattpocock-skills-addons --skill silent-consent` |
| Everything, no prompts | `npx skills add stevenrabulan/mattpocock-skills-addons --all` |
| For every project (user level) | `npx skills add stevenrabulan/mattpocock-skills-addons -g` |
| For one agent only | `npx skills add stevenrabulan/mattpocock-skills-addons -a claude-code -y` |
| Update | `npx skills update` |
| Remove | `npx skills remove implement-tickets silent-consent` |

## Skills

| Skill | What it does | Needs from Matt's skills |
| --- | --- | --- |
| `implement-tickets` | Works through every open `ready-for-agent` ticket unattended: one subagent per ticket runs `/implement`, then the work is checked and committed. Decisions are logged to one review-notes file. An optional `USAGE_GATE_CMD` can stop the run between tickets. | `implement`, `tdd`, `code-review`, and the `docs/agents/` issue-tracker docs from `setup-matt-pocock-skills` |
| `silent-consent` | Switches a numbered-question session (`grilling`, `triage`, a spec interview) to silent consent: a question you don't answer is settled at the agent's recommendation, as long as you answer at least one in the round. Every round ends with a reminder, and every assumed answer is echoed. | `grilling`, or any skill that asks numbered questions with recommendations |

`silent-consent` deliberately overrides `grilling`'s default, where a skipped question stays open.

Both skills set `disable-model-invocation: true`, so they run only when you type them.

## Scope

A skill belongs here only if it calls one of Matt's skills or changes how one of them runs. Standalone skills go elsewhere. Matt's skills are never copied or vendored here: they are declared as prerequisites.

## Developing

Edit skills in this checkout, then link them into your personal skills folder so your own copy stays live rather than frozen at install time:

```bash
./link.sh
```

It links `~/.claude/skills/<skill>` to each folder under `skills/`. It is safe to re-run, and it refuses to replace anything that is not already a symlink.

Before publishing, run the checker and the tests:

```bash
bash scripts/check.sh "Your Name" your-username   # or list terms in .check-terms (gitignored)
bash scripts/check.test.sh
```

`check.sh` fails on any of these:

- a skill folder without a `SKILL.md`
- a missing `name` or `description`
- a `name` that differs from its folder
- a skill missing from the table above
- any of your personal terms in a file git would publish (`LICENSE` is skipped)

## License

MIT
