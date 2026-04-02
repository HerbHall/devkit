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
        'PSAvoidUsingEmptyCatchBlock',

        # DevKit scripts use ParameterSetName-based dispatch ($PSCmdlet.ParameterSetName)
        # instead of referencing switch parameters directly. PSScriptAnalyzer cannot
        # detect this indirect usage pattern and produces false positives.
        'PSReviewUnusedParameter',

        # Internal helper functions (Get-InstalledVSCodeExtensions, Get-LinkPairs, etc.)
        # use plural nouns that reflect their return type. They are not public cmdlets,
        # so the cmdlet naming convention does not apply.
        'PSUseSingularNouns',

        # Loop variables named $profile shadow the automatic $profile variable.
        # These are pre-existing throughout stack.ps1 where $profile means a
        # DevKit stack profile object (unrelated to PS's $profile path string).
        # Tracked for future rename in https://gitea.herbhall.net/samverk/devkit/issues
        'PSAvoidAssignmentToAutomaticVariable',

        # Start-Job ScriptBlocks that use param() + -ArgumentList pass variables
        # explicitly and do not need $using: scope. PSScriptAnalyzer cannot distinguish
        # parameterized from closure-captured variables and flags them as false positives.
        'PSUseUsingScopeModifierInNewRunspaces',

        # credentials.ps1 uses [object[]]$Credentials (not [string]) to accept
        # PSCredential objects. The rule fires on parameter name alone regardless of type.
        'PSAvoidUsingPlainTextForPassword',

        # DevKit scripts are authored cross-platform (Windows/MSYS git). Git's
        # autocrlf handling and cross-platform editors strip BOM headers. Requiring
        # BOM is impractical and does not affect script functionality.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
