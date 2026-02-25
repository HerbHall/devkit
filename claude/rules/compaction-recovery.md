# Compaction Recovery Rules

## After Compaction: Execute, Don't Re-Analyze

When a session resumes after compaction, the summary contains everything needed.
Follow these rules to avoid wasting the new context window on redundant work.

## Rule 1: Trust the Summary

The compaction summary was written by YOU moments ago. It contains:
- What was already verified (don't verify again)
- What was already read (don't re-read)
- What the next action is (do it immediately)

**Do NOT:**
- Re-read transcript files to "refresh context" — the summary IS your context
- Re-verify directory structures already confirmed in the summary
- Re-analyze source material already synthesized in the summary
- Read transcripts in 100-line increments "just to be thorough"

**DO:**
- Read the summary's PENDING/NEXT STEP section
- Start executing the next action within your first 2-3 tool calls
- Only consult transcripts for specific missing details (targeted reads, not full scans)

## Rule 2: Budget Your Context

A session has roughly 50-80 meaningful tool calls before compaction risk.
Budget them:

| Phase | Max Tool Calls | Purpose |
|-------|---------------|---------|
| Orient | 2-3 | Read summary, check one critical file if needed |
| Execute | 40-60 | Create files, write code, do the actual work |
| Verify | 5-10 | Confirm outputs, run tests |
| Reserve | 5 | Buffer for unexpected issues |

If orientation is consuming more than 5 tool calls, STOP and start executing.

## Rule 3: Detect the Loop

You are in a compaction loop if:
- You've been compacted 2+ times on the same task
- Each session's primary activity was "reading" not "writing"
- No output files have been created across sessions

**Breaking the loop:**
1. Stop all reading/analysis immediately
2. List what you already know (it's enough)
3. Start creating output files with your current knowledge
4. Imperfect output > perfect analysis that never ships

## Rule 4: Scope Check

Before starting any task, estimate:
- Files to read: ___
- Files to create/edit: ___
- Total tool calls needed: ___

If total exceeds 50, break into sub-tasks and do ONE sub-task per session.
State the sub-task breakdown to the user before starting.

## Rule 5: Transcript Reading Protocol

If you MUST read a transcript (specific detail needed, not general refresh):
- Use targeted line ranges, not sequential full reads
- Read the END first (most recent = most relevant)
- Stop as soon as you find the specific detail
- Never read more than 200 lines of transcript per session
- Prefer grep/search over sequential reading

## Rule 6: Write Early

In any implementation session, create your FIRST output file within 10 tool calls.
Even a skeleton file with TODOs is better than a perfect plan that gets compacted away.
Files on disk survive compaction. Plans in context don't.
