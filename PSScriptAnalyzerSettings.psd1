# PSScriptAnalyzerSettings.psd1
# PSScriptAnalyzer configuration for the DevKit repository.
#
# Rules are run at Warning and Error severity. The following rules are excluded
# because they do not apply to DevKit's script-only (non-module) codebase:
@{
    ExcludeRules = @(
        # DevKit scripts are interactive console UI tools. Write-Host is the
        # correct choice for user-facing output that must not pollute the pipeline.
        'PSAvoidUsingWriteHost',

        # DevKit functions are internal helper scripts, not public cmdlets in a
        # module. Adding SupportsShouldProcess to every helper would add noise
        # without providing the -WhatIf/-Confirm UX that users expect from cmdlets.
        'PSUseShouldProcessForStateChangingFunctions',

        # Several catch blocks intentionally swallow non-critical errors
        # (e.g., silently ignoring unavailable tools during pre-flight checks).
        # These are deliberate and documented in context.
        'PSAvoidUsingEmptyCatchBlock'
    )
}
