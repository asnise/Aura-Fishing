---
name: aura-fishing-qa
description: How an AI agent working on the Aura Fishing repo reports finished work to the QA team (docs/TASKS.md -> qa/ site), reads QA failures and tickets, and posts ideas or summary reports to the Ideas forum. Use at the start and end of every work session, whenever a feature is finished or changed, and whenever you want to propose something.
---

# Aura Fishing QA system: agent guide

The QA team (humans) tests the game from a web page (GitHub Pages). **You never test for them and never mark anything as passed.** Your job is to make sure that what you built shows up there with correct test steps, that you read what they report, and that decisions go through the Ideas forum.

## 1. The map (what lives where)

| Thing | Where | Who writes it |
|---|---|---|
| Task list, test steps, update log | `docs/TASKS.md` (source of truth) | **You** |
| Site data built from it | `qa/data/qadata.json` | `node qa/tools/build.mjs` (never by hand) |
| Systems summary (stage, system list) | `qa/data/project.json` | You, when a system's status changes |
| "Dev fixed ticket X" notes | `qa/data/fixes.json` | `node qa/tools/fix.mjs` (never by hand) |
| QA results (pass / fail + comment) | Firestore `qa/state` | **QA team only** |
| Tickets (bugs) | Firestore `qa/tickets` | QA team creates and closes; you only read and answer via `fix.mjs` |
| Ideas forum (proposals, reports) | Firestore `qa/ideas` | Humans and you (`post.mjs`); **humans decide status** |
| Published site | git branch `gh-pages` (folder `qa/`) | `git subtree push --prefix qa origin gh-pages` |

All commands run from the repo root `D:\Roblox Project\Aura Fishing`.

## 2. When must you report? (decision table)

| What just happened | What you must do |
|---|---|
| Started a session | `node qa/tools/pull.mjs` (failed tasks, open tickets, ideas waiting, approved ideas). Read it before choosing work. |
| Finished or changed a feature | Update `docs/TASKS.md` (section 3), then build + commit (section 4). |
| Fixed a bug a ticket described | `node qa/tools/fix.mjs T-XXXX "what you changed and where"`, then also update TASKS.md if behavior changed. |
| A task QA marked failed is now fixed | Update its note + test steps in TASKS.md and build. The site flags it "changed since QA" so QA retests. |
| Have an idea, design question, risk, or want a decision | Post it to the forum (section 6). Do not just build it. |
| Finished a big batch / end of session | Post a short summary report to the forum (section 6) and run the publish step. |
| Implemented an approved idea | Comment on the idea (`--comment`) with what was built, add the task to TASKS.md. A human sets the status to "done". |

If none of these apply (pure refactor with no behavior change, docs typo), you do **not** need to report. When unsure whether a change is visible to a player or tester, report it.

## 3. Updating `docs/TASKS.md` (exact format, the parser is strict)

### 3.1 Overview checklist line (top of the file)

```
- [ ] C26 — จุดฟองปลา (Hotspot): เหวี่ยงลงวงฟองได้ Luck +50%  `โค้ดเสร็จ รอทดสอบใน Play`
```
- ID, then ` — ` (em dash), title, **two spaces**, note in backticks.
- `[ ]` vs `[x]`: **`[x]` means a human tested it and it passed. Never tick it yourself.** Leave `[ ]`.
- The note decides the status shown on the site:

| Note contains | Status shown |
|---|---|
| `ยังไม่เริ่ม` or `เลื่อนไปทีหลัง` | not started |
| `โค้ดเสร็จ`, `รอทดสอบ`, `ครบทุกส่วนในเกม`, `ทดสอบผ่าน Studio Bridge` | ready for QA |
| anything else | in progress |

- Code finished and ready to test: write `โค้ดเสร็จ รอทดสอบ` plus one clause of what is notable.
- New task: take the next free ID in its group (A prototype, B UI, C game systems).

### 3.2 Task section with the QA test steps

```
### C26. จุดฟองปลา (Hotspot) — 2026-11-20  `โค้ดเสร็จ รอทดสอบ`
- Done when: เหวี่ยงลงวงฟองแล้วได้ Luck +50% และวงหายหลังใช้ครบ 2 ครั้ง
- ทดสอบ (คุณ):
  - [ ] 1. Ctrl+S → Play → ยืนริมน้ำรอไม่เกิน ~10 วินาที: มีวงทองฟองผุดในน้ำใกล้ ๆ
  - [ ] 2. กดค้างเล็งเข้าวง ปล่อย: ขึ้น "HOTSPOT! +50% luck" การ์ดปลามีป้าย HOTSPOT
  - [ ] 3. เหวี่ยงลงวงเดิมอีกครั้ง: วงหายไป
```
- Heading must be `### <ID>. title` (ID followed by a period). Several IDs: `### B15 + B6 + B9. title`.
- The line `- ทดสอบ:` (or `- ทดสอบ (คุณ):`) followed by indented `  - [ ] N. ...` items becomes the checklist the tester sees. If it is missing the tester sees "no steps", which blocks QA.
- Write each step as **action then expected result**: "do X: you should see Y". Include where to click, numbers to expect, and what is NOT supposed to happen. Thai is fine and preferred.
- Steps must be doable by someone who did not read the code. Mention how to spawn items (`!` chat commands, F2 dev panel) if needed.
- If you change behavior of an already-tested task, update its note and steps. The site compares a fingerprint of (status note + steps) and shows the badge "changed since QA" so QA retests.

### 3.3 Update log line (bottom, under `## บันทึกการอัปเดต`)

```
- 2026-11-22T19:30:00+07:00 — เพิ่มจุดฟองปลา (C26) ทดสอบเรื่อง ... ผลที่ต้องดู ...
```
Newest first. ISO timestamp with `+07:00`, then ` — ` (em dash), one or two sentences: what changed, which task IDs. This feeds the "history" page.

## 4. Build, commit, publish

```powershell
node qa/tools/build.mjs
```
Expect: `qadata.json: N tasks (M with test steps) ...`. If it throws, your TASKS.md format is wrong (section 3). Then:

```powershell
git add docs/TASKS.md qa/data
git commit -m "<what you did>"
git push origin main
git subtree push --prefix qa origin gh-pages
```
Rules:
- Commit `qa/data/qadata.json` together with the TASKS.md change, always. A stale file makes the site show old tasks.
- Push/publish only if your operator allows pushing in this session. If not, stop after the commit and say in your final message: "built and committed, needs `git subtree push --prefix qa origin gh-pages`".
- Never edit `qa/data/qadata.json` by hand. Never edit anything under `qa/` other than `qa/data/project.json` unless your task is the QA site itself.

## 5. Reading what QA reported

```powershell
node qa/tools/pull.mjs
```
Output sections:
- `FAILED tasks`: QA tested and it failed; read their comment, reproduce, fix.
- `OPEN tickets without a dev fix`: bugs to fix. Each has steps, expected, actual.
- `IDEAS waiting for a decision`: do **not** implement these; humans are still deciding. You may comment with technical input (cost, risk, effort).
- `IDEAS approved, not built yet`: green light. Plan it, build it, add a TASKS.md task, then comment on the idea.

After fixing a ticket:
```powershell
node qa/tools/fix.mjs T-XXXX "Fixed hotspot ring not clearing, see HotspotService.luau"
```
The site then shows "dev fixed, please retest". **Only QA closes tickets.** You never mark a ticket or task as passed.

`pull.mjs` reads Firestore (free tier has a daily quota): run it once at session start and once before your final report. Never in a loop.

## 6. Ideas forum: proposals and reports

```powershell
node qa/tools/post.mjs --title "Short title" --category system --body "Why, how it works, impact, cost"
node qa/tools/post.mjs --title "Session summary 2026-11-22" --category other --body-file report.md
node qa/tools/post.mjs --comment I-ABC123 --body "Implemented in X, see task C30"
```
- Categories: `system`, `balance`, `content`, `ui`, `monetize`, `other`.
- Needs a service-account key file: `qa/.agent-key.json` (gitignored) or the path in `QA_AGENT_KEY_FILE`. **Never print, log, commit, or paste its contents.** If it is missing, say so and give the human the command to run instead.
- A good post has: a title that says what is proposed; body with (1) the problem or opportunity, (2) the proposal, (3) effects on balance / players / other systems, (4) rough effort, (5) the question humans should answer. A report has: what was done, what changed for players, what QA should test first, known risks, what is next.
- One post per idea. Search `pull.mjs` output first so you do not duplicate. Do not spam: batch small notes into one summary.
- Posts always start as `proposed`. Status (`discussing`, `approved`, `rejected`, `done`) is decided by humans on the website.

## 7. Definition of done for any task that touches the game

1. Code works and `node tools/check.mjs` passes (project rule).
2. `docs/TASKS.md`: checklist note, section with Done when + `ทดสอบ` steps, update-log line.
3. `node qa/tools/build.mjs` ran without error and `qa/data/qadata.json` is committed.
4. Tickets you fixed have a `fix.mjs` note.
5. Published (or you told the operator the exact publish command).
6. Final message to the operator says: which task IDs changed, what QA should test, anything blocked.

## 8. Do not

- Do not tick `[x]` in TASKS.md, mark QA results, or close tickets.
- Do not write to Firestore except through `post.mjs`. Do not change security rules or Firebase config.
- Do not edit `qadata.json` or `fixes.json` by hand.
- Do not commit `qa/.agent-key.json` (it is in `.gitignore`; do not remove that).
- Do not implement ideas that are not `approved`.
- Do not claim "reported to QA" unless build, commit, and (if allowed) publish actually succeeded. Report failures as they are.

## 9. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `build.mjs` says no tasks found | Overview checklist lines not in the exact format (section 3.1) |
| Task shows "no test steps" on the site | Missing `### <ID>.` heading or `- ทดสอบ:` block (section 3.2) |
| `pull.mjs` prints "qa/ideas is not readable yet" | Firestore rules not published with `ideas`; ask the human to publish `qa/firestore.rules` |
| `post.mjs` "No agent key at ..." | Key file missing; human must create it (see `qa/README.md`) |
| `post.mjs` "Agent key rejected" | Key deleted or malformed; human creates a new key |
| `post.mjs` "Note: key is from project X" then 403 | Key is from another Google project: grant its service-account email **Cloud Datastore User** in the site project (IAM), and enable the Cloud Firestore API in the key's own project |
| `post.mjs` "Firestore commit failed: 403" | The service account lacks the role **Cloud Datastore User** (IAM), or Firestore API disabled |
| Site shows old data | Forgot to commit `qadata.json` or to run the publish command; browsers cache, hard refresh with Ctrl+F5 |

---

# Prompts to give each agent

Paste one of these at the start of the agent's instructions. The first block is for everyone; add the role block that matches.

## A. For every agent (paste always)

```
You work on the Aura Fishing repo. A QA team tests it through a website. Follow qa/SKILL.md exactly.
- At the start of the session run `node qa/tools/pull.mjs` and read it before choosing work.
- When you finish or change anything a player or tester can notice: update docs/TASKS.md (checklist note, "Done when", numbered "ทดสอบ" steps that say action then expected result, and a timestamped line under "บันทึกการอัปเดต"), run `node qa/tools/build.mjs`, and commit qa/data/qadata.json with it.
- Publish with `git subtree push --prefix qa origin gh-pages` only if pushing is allowed in this session; otherwise tell the operator the exact command.
- Never tick [x] in TASKS.md, never mark QA results, never close tickets: only the QA team does. After fixing a ticket run `node qa/tools/fix.mjs <id> "what changed"`.
- Never implement an idea that is not approved. Post proposals and summary reports with `node qa/tools/post.mjs`. Never print or commit the agent key file (qa/.agent-key.json).
- Your final message must list the task IDs you changed, what QA should test, and anything blocked. Do not say "reported" unless build, commit and publish really succeeded.
```

## B. Developer agent (builds features, fixes bugs)

```
Role: developer. Priority order: (1) failed tasks and open tickets from pull.mjs, (2) approved ideas, (3) the task the operator gave you. For each ticket: reproduce, fix, run node tools/check.mjs, update the task's note and test steps, run fix.mjs, then build.mjs. Write test steps so a person who never saw the code can follow them. If a request conflicts with an idea still being discussed, stop and comment on the idea instead of building.
```

## C. Planner / designer agent (proposes, does not build)

```
Role: planner. Do not change game code. Read the repo and pull.mjs, then post proposals to the Ideas forum with post.mjs: title, problem, proposal, effects on balance and other systems, rough effort, and the decision you need from humans. Comment technical input on ideas under discussion. At the end post one summary report. Never change TASKS.md statuses.
```

## D. Reviewer / read-only agent

```
Role: reviewer. Read only. Run pull.mjs and summarize in your reply: failed tasks, open tickets, ideas waiting for a decision, approved ideas not built. Do not edit files, do not post, do not commit.
```

## E. Reporter agent (end-of-session summary)

```
Role: reporter. Compare git log since the last summary with docs/TASKS.md. Post one report with post.mjs (category other, title "Summary <date>"): what changed for players, which tasks are ready for QA and what to test first, known risks, what is next. Do not post per-commit notes.
```
