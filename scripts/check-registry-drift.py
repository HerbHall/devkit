#!/usr/bin/env python3
"""check-registry-drift.py -- Verify rendered project-templates/ match src/ + registry.

Reads tool-registry.json, builds a token→value map, renders each file in
project-templates/src/, and compares the rendered output against the
corresponding file in project-templates/.

Exits with code 1 if any drift is detected, 0 if all files match.

Usage:
    python3 scripts/check-registry-drift.py

GitHub Actions error annotation format is used for drift lines so errors
appear inline in the CI summary.
"""

import json
import os
import sys


def main() -> int:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)

    registry_path = os.path.join(repo_root, 'tool-registry.json')
    src_dir = os.path.join(repo_root, 'project-templates', 'src')
    templates_dir = os.path.join(repo_root, 'project-templates')

    # --- Load registry ---

    if not os.path.isfile(registry_path):
        print(f'::error::tool-registry.json not found at {registry_path}', flush=True)
        return 1

    with open(registry_path, encoding='utf-8') as f:
        registry = json.load(f)

    # Build token → value map
    token_map: dict[str, str] = {}
    for tool_id, tool in registry.get('tools', {}).items():
        token = tool.get('token')
        current = tool.get('current')
        if token and current is not None:
            token_map[f'{{{{{token}}}}}'] = str(current)

    if not token_map:
        print('::warning::Registry has no tools with token+current entries', flush=True)

    # --- Scan src/ ---

    if not os.path.isdir(src_dir):
        print(f'::error::src/ directory not found: {src_dir}', flush=True)
        return 1

    src_files = [
        f for f in os.listdir(src_dir)
        if os.path.isfile(os.path.join(src_dir, f))
    ]

    if not src_files:
        print('::warning::No files found in src/ — nothing to check', flush=True)
        return 0

    drift_files: list[str] = []
    missing_files: list[str] = []
    ok_files: list[str] = []

    for filename in sorted(src_files):
        src_path = os.path.join(src_dir, filename)
        rendered_path = os.path.join(templates_dir, filename)

        # Read source
        with open(src_path, encoding='utf-8') as f:
            src_content = f.read()

        # Apply token substitutions
        rendered = src_content
        for token, value in token_map.items():
            rendered = rendered.replace(token, value)

        # Check destination exists
        if not os.path.isfile(rendered_path):
            missing_files.append(filename)
            rel_src = os.path.relpath(src_path, repo_root)
            rel_dest = os.path.relpath(rendered_path, repo_root)
            print(
                f'::error file={rel_dest}::MISSING: {filename} exists in src/ but '
                f'not in project-templates/ — run Invoke-VersionUpdate.ps1 -Mode Render',
                flush=True,
            )
            continue

        # Read destination
        with open(rendered_path, encoding='utf-8') as f:
            dest_content = f.read()

        # Normalize line endings for comparison
        rendered_norm = rendered.replace('\r\n', '\n').rstrip('\n')
        dest_norm = dest_content.replace('\r\n', '\n').rstrip('\n')

        if rendered_norm != dest_norm:
            drift_files.append(filename)
            rel_dest = os.path.relpath(rendered_path, repo_root)
            print(
                f'::error file={rel_dest}::DRIFT: {filename} in project-templates/ '
                f'does not match src/{filename} rendered with current registry values. '
                f'Run Invoke-VersionUpdate.ps1 -Mode Render to fix.',
                flush=True,
            )

            # Print a diff-style summary for the first 20 differing lines
            src_lines = rendered_norm.splitlines()
            dest_lines = dest_norm.splitlines()
            max_lines = max(len(src_lines), len(dest_lines))
            diff_count = 0
            for i in range(max_lines):
                sl = src_lines[i] if i < len(src_lines) else '<missing>'
                dl = dest_lines[i] if i < len(dest_lines) else '<missing>'
                if sl != dl:
                    if diff_count < 5:
                        print(f'  Line {i + 1}:', flush=True)
                        print(f'    expected: {sl!r}', flush=True)
                        print(f'    actual:   {dl!r}', flush=True)
                    diff_count += 1
            if diff_count > 5:
                print(f'  ... and {diff_count - 5} more differing line(s)', flush=True)
        else:
            ok_files.append(filename)

    # --- Summary ---

    total = len(src_files)
    n_ok = len(ok_files)
    n_drift = len(drift_files)
    n_missing = len(missing_files)

    print('', flush=True)
    print('Registry Drift Check Summary', flush=True)
    print(f'  Total src/ files checked : {total}', flush=True)
    print(f'  OK (no drift)            : {n_ok}', flush=True)
    print(f'  Missing in project-templates/: {n_missing}', flush=True)
    print(f'  Drift detected           : {n_drift}', flush=True)

    if n_drift > 0 or n_missing > 0:
        print('', flush=True)
        if drift_files:
            print('Files with drift:', flush=True)
            for name in drift_files:
                print(f'  - {name}', flush=True)
        if missing_files:
            print('Files missing from project-templates/:', flush=True)
            for name in missing_files:
                print(f'  - {name}', flush=True)
        print('', flush=True)
        print(
            'Fix: run  pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Render',
            flush=True,
        )
        return 1

    print('  All files match rendered output.', flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
