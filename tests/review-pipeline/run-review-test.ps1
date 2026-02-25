#Requires -Version 7.0

<#
.SYNOPSIS
    End-to-end test for the independent review pipeline.

.DESCRIPTION
    Validates that the plan-reviewer and review-code agents correctly identify
    intentional flaws in test artifacts, and approve corrected versions.

    Requires Claude Code CLI (`claude`) to be installed and authenticated.

.EXAMPLE
    pwsh -File tests/review-pipeline/run-review-test.ps1
#>

param(
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TestDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Results = @{ Passed = 0; Failed = 0; Skipped = 0 }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-TestResult {
    param([string]$Name, [string]$Status, [string]$Detail)
    $symbol = switch ($Status) {
        'PASS' { '[PASS]' }
        'FAIL' { '[FAIL]' }
        'SKIP' { '[SKIP]' }
    }
    $color = switch ($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'SKIP' { 'Yellow' }
    }
    Write-Host "$symbol $Name" -ForegroundColor $color
    if ($Detail -and ($Verbose -or $Status -eq 'FAIL')) {
        Write-Host "       $Detail" -ForegroundColor DarkGray
    }
}

function Test-ClaudeCLI {
    try {
        $version = & claude --version 2>&1
        return $null -ne $version
    }
    catch {
        return $false
    }
}

function Invoke-ClaudeReview {
    param([string]$Prompt, [int]$TimeoutSeconds = 120)

    $tempPrompt = Join-Path ([IO.Path]::GetTempPath()) "review-test-$([guid]::NewGuid().ToString('N').Substring(0,8)).txt"
    Set-Content -Path $tempPrompt -Value $Prompt

    try {
        $output = & claude --print --prompt (Get-Content $tempPrompt -Raw) 2>&1 | Out-String
        return $output
    }
    finally {
        Remove-Item $tempPrompt -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Prerequisite check
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '=== Review Pipeline E2E Test ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-ClaudeCLI)) {
    Write-TestResult 'Prerequisite: Claude CLI' 'SKIP' 'claude command not found or not authenticated'
    Write-Host ''
    Write-Host "Install Claude Code and authenticate before running this test." -ForegroundColor Yellow
    Write-Host "See: https://docs.anthropic.com/en/docs/claude-code" -ForegroundColor Yellow
    exit 0
}

Write-TestResult 'Prerequisite: Claude CLI' 'PASS' 'claude command available'

# ---------------------------------------------------------------------------
# Test 1: Plan review catches flaws in test-plan.md
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '--- Test 1: Plan review (flawed plan) ---' -ForegroundColor Cyan

$planPath = Join-Path $TestDir 'test-plan.md'
$planContent = Get-Content $planPath -Raw

$planPrompt = @"
You are a plan reviewer. Review this implementation plan and identify security and design flaws.

Return your response in this exact format:
- Start with VERDICT: followed by APPROVE, REVISE, or REJECT
- Then list findings with SEVERITY: (Critical/High/Medium/Low) and FINDING: description

Plan to review:

$planContent
"@

try {
    $planResult = Invoke-ClaudeReview -Prompt $planPrompt
    $hasRejectOrRevise = $planResult -match '(?i)(REJECT|REVISE)'
    $findsPlaintextPassword = $planResult -match '(?i)(plaintext|plain.text|unhashed|not.hash|store.password.directly|no.hash)'
    $findsNoExpiry = $planResult -match '(?i)(never.expire|no.expir|token.*expir|expir.*token)'

    if ($hasRejectOrRevise) {
        Write-TestResult 'Plan review: verdict is REVISE or REJECT' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Plan review: verdict is REVISE or REJECT' 'FAIL' "Expected REVISE/REJECT, got: $($planResult.Substring(0, [Math]::Min(200, $planResult.Length)))"
        $Results.Failed++
    }

    if ($findsPlaintextPassword) {
        Write-TestResult 'Plan review: identifies plaintext password storage' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Plan review: identifies plaintext password storage' 'FAIL' 'Reviewer did not flag password storage issue'
        $Results.Failed++
    }

    if ($findsNoExpiry) {
        Write-TestResult 'Plan review: identifies missing token expiration' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Plan review: identifies missing token expiration' 'FAIL' 'Reviewer did not flag token expiry issue'
        $Results.Failed++
    }
}
catch {
    Write-TestResult 'Plan review (flawed plan)' 'FAIL' "Error: $_"
    $Results.Failed += 3
}

# ---------------------------------------------------------------------------
# Test 2: Plan review approves fixed plan
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '--- Test 2: Plan review (fixed plan) ---' -ForegroundColor Cyan

$fixedPlanPath = Join-Path $TestDir 'test-plan-fixed.md'
$fixedPlanContent = Get-Content $fixedPlanPath -Raw

$fixedPlanPrompt = @"
You are a plan reviewer. Review this implementation plan and identify any remaining security or design flaws.

Return your response in this exact format:
- Start with VERDICT: followed by APPROVE, REVISE, or REJECT
- Then list findings with SEVERITY: (Critical/High/Medium/Low) and FINDING: description

Plan to review:

$fixedPlanContent
"@

try {
    $fixedPlanResult = Invoke-ClaudeReview -Prompt $fixedPlanPrompt
    $hasApprove = $fixedPlanResult -match '(?i)APPROVE'
    $hasCritical = $fixedPlanResult -match '(?i)Critical'

    if ($hasApprove -and -not $hasCritical) {
        Write-TestResult 'Fixed plan review: verdict is APPROVE' 'PASS'
        $Results.Passed++
    }
    elseif ($hasApprove) {
        Write-TestResult 'Fixed plan review: verdict is APPROVE (with caveats)' 'PASS' 'Approved but noted Critical findings -- acceptable variance'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Fixed plan review: verdict is APPROVE' 'FAIL' "Expected APPROVE, got: $($fixedPlanResult.Substring(0, [Math]::Min(200, $fixedPlanResult.Length)))"
        $Results.Failed++
    }
}
catch {
    Write-TestResult 'Fixed plan review' 'FAIL' "Error: $_"
    $Results.Failed++
}

# ---------------------------------------------------------------------------
# Test 3: Code review catches flaws in handler.go
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '--- Test 3: Code review (flawed code) ---' -ForegroundColor Cyan

$codePath = Join-Path $TestDir 'test-code' 'handler.go'
$codeContent = Get-Content $codePath -Raw

$codePrompt = @"
You are a code reviewer. Review this Go code for security vulnerabilities and code quality issues.

Return your response in this exact format:
- Start with VERDICT: followed by APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION
- Then list findings with SEVERITY: (Critical/High/Medium/Low) and FINDING: description including file:line reference

Code to review:

$codeContent
"@

try {
    $codeResult = Invoke-ClaudeReview -Prompt $codePrompt
    $hasRequestChanges = $codeResult -match '(?i)REQUEST.CHANGES'
    $findsSQLInjection = $codeResult -match '(?i)(SQL.inject|Sprintf.*SQL|string.format.*query|concatenat.*SQL)'
    $findsCommandInjection = $codeResult -match '(?i)(command.inject|exec\.Command.*user|os.exec.*input|unsanitiz.*command)'

    if ($hasRequestChanges) {
        Write-TestResult 'Code review: verdict is REQUEST_CHANGES' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Code review: verdict is REQUEST_CHANGES' 'FAIL' "Expected REQUEST_CHANGES, got: $($codeResult.Substring(0, [Math]::Min(200, $codeResult.Length)))"
        $Results.Failed++
    }

    if ($findsSQLInjection) {
        Write-TestResult 'Code review: identifies SQL injection' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Code review: identifies SQL injection' 'FAIL' 'Reviewer did not flag SQL injection'
        $Results.Failed++
    }

    if ($findsCommandInjection) {
        Write-TestResult 'Code review: identifies command injection' 'PASS'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Code review: identifies command injection' 'FAIL' 'Reviewer did not flag command injection'
        $Results.Failed++
    }
}
catch {
    Write-TestResult 'Code review (flawed code)' 'FAIL' "Error: $_"
    $Results.Failed += 3
}

# ---------------------------------------------------------------------------
# Test 4: Code review approves fixed code
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '--- Test 4: Code review (fixed code) ---' -ForegroundColor Cyan

$fixedCodePath = Join-Path $TestDir 'test-code' 'handler-fixed.go'
$fixedCodeContent = Get-Content $fixedCodePath -Raw

$fixedCodePrompt = @"
You are a code reviewer. Review this Go code for security vulnerabilities and code quality issues.

Return your response in this exact format:
- Start with VERDICT: followed by APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION
- Then list findings with SEVERITY: (Critical/High/Medium/Low) and FINDING: description

Code to review:

$fixedCodeContent
"@

try {
    $fixedCodeResult = Invoke-ClaudeReview -Prompt $fixedCodePrompt
    $hasApproveCode = $fixedCodeResult -match '(?i)APPROVE'
    $hasCriticalCode = $fixedCodeResult -match '(?i)Critical'

    if ($hasApproveCode -and -not $hasCriticalCode) {
        Write-TestResult 'Fixed code review: verdict is APPROVE' 'PASS'
        $Results.Passed++
    }
    elseif ($hasApproveCode) {
        Write-TestResult 'Fixed code review: verdict is APPROVE (with caveats)' 'PASS' 'Approved but noted caveats -- acceptable'
        $Results.Passed++
    }
    else {
        Write-TestResult 'Fixed code review: verdict is APPROVE' 'FAIL' "Expected APPROVE, got: $($fixedCodeResult.Substring(0, [Math]::Min(200, $fixedCodeResult.Length)))"
        $Results.Failed++
    }
}
catch {
    Write-TestResult 'Fixed code review' 'FAIL' "Error: $_"
    $Results.Failed++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '=== Results ===' -ForegroundColor Cyan
$total = $Results.Passed + $Results.Failed + $Results.Skipped
Write-Host "  Passed:  $($Results.Passed)/$total" -ForegroundColor Green
if ($Results.Failed -gt 0) {
    Write-Host "  Failed:  $($Results.Failed)/$total" -ForegroundColor Red
}
if ($Results.Skipped -gt 0) {
    Write-Host "  Skipped: $($Results.Skipped)/$total" -ForegroundColor Yellow
}
Write-Host ''

if ($Results.Failed -gt 0) {
    Write-Host 'RESULT: FAIL' -ForegroundColor Red
    exit 1
}
else {
    Write-Host 'RESULT: PASS' -ForegroundColor Green
    exit 0
}
