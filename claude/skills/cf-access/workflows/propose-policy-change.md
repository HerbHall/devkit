# Propose Access Policy Change

Use this workflow to propose adding, removing, or modifying a Cloudflare Access policy. You will produce a structured proposal and file it as an `agent:human` issue. You will NOT execute any changes.

## Step 1: Define the Change

Determine:

- **Which Access Application?** (e.g., samverk.herbhall.net, synapset.herbhall.net)
- **What type of change?** Add a new policy, remove an existing policy, or modify policy rules
- **Why is this needed?** What problem does this solve? What breaks without it?

## Step 2: Assess Impact

Before proposing, evaluate:

- **Who is currently protected?** List all policies on the target application
- **What breaks if this policy is removed?** (If removing)
- **What new access is granted?** (If adding)
- **Does this widen the attack surface?** Any change that allows broader access must justify why

## Step 3: Write the Proposal

Use this template:

```markdown
## CF Access Policy Change Proposal

**Application:** [hostname]
**Change type:** [add / remove / modify]
**Priority:** [critical / high / normal]

### Current State

[Describe the current policies on this application]

### Proposed Change

[Exactly what should change -- be specific about policy name, action, include/exclude rules]

### Justification

[Why this change is needed. Reference the triggering incident or requirement.]

### Impact Assessment

- **Access widened:** [yes/no -- if yes, explain what new access is granted]
- **Access narrowed:** [yes/no -- if yes, explain what access is removed]
- **Affected users/services:** [who is impacted]

### Rollback Procedure

To revert this change:
1. [Step-by-step reversal instructions]
2. [Verify reversal with specific curl command]

### Verification

After applying, verify with:
1. [Specific curl command to confirm the change works]
2. [Specific curl command to confirm nothing else broke]
```

## Step 4: File the Issue

File an `agent:human` issue in the appropriate project repo with:

- Title: `cf-access: [add/remove/modify] [policy name] on [application]`
- Label: `agent:human`, `priority:[level]`
- Body: The proposal from Step 3

## STOP

Do NOT execute the change. Do NOT call the Cloudflare API. Your job is the proposal only.
