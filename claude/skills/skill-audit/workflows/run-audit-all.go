// run-audit-all.go
// Standalone Go script to audit all skills in claude/skills/ for best practices compliance.
// Outputs a per-skill report as described in audit-all.md.

package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

type AuditResult struct {
	Name     string
	Dir      string
	Findings []string
	Warnings []string
	Pass     bool
}

func main() {
	skillsRoot := "claude/skills"
	if len(os.Args) > 1 {
		skillsRoot = os.Args[1]
	}
	dirs, err := os.ReadDir(skillsRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to list skills: %v\n", err)
		os.Exit(1)
	}
	var results []AuditResult
	for _, d := range dirs {
		if !d.IsDir() {
			continue
		}
		skillDir := filepath.Join(skillsRoot, d.Name())
		skillFile := filepath.Join(skillDir, "SKILL.md")
		// ...existing code...
		res := auditSkill(skillFile, skillDir)
		results = append(results, res)
	}
	// Output per-skill report
	pass, warn, fail := 0, 0, 0
	for _, r := range results {
		fmt.Printf("## Skill: %s (%s)\n", r.Name, r.Dir)
		for _, f := range r.Findings {
			fmt.Println("- [FAIL]", f)
		}
		for _, w := range r.Warnings {
			fmt.Println("- [WARN]", w)
		}
		if r.Pass && len(r.Warnings) == 0 {
			fmt.Println("- [PASS] All checks passed")
			pass++
		} else if len(r.Findings) > 0 {
			fail++
		} else {
			warn++
		}
		fmt.Println()
	}
	fmt.Printf("%d skills audited: %d pass, %d warnings, %d failing\n", len(results), pass, warn, fail)
}

func auditSkill(skillFile, skillDir string) AuditResult {
	res := AuditResult{Dir: skillDir, Pass: true}
	f, err := os.Open(skillFile)
	if err != nil {
		res.Findings = append(res.Findings, "Missing SKILL.md")
		res.Pass = false
		return res
	}
	defer f.Close()
	// Read file
	scanner := bufio.NewScanner(f)
	lines := []string{}
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	// Check YAML frontmatter
	name, desc, userInv := false, false, false
	inYaml := false
	for _, l := range lines {
		if strings.TrimSpace(l) == "---" {
			inYaml = !inYaml
			continue
		}
		if inYaml {
			if strings.HasPrefix(l, "name:") && len(strings.TrimSpace(l[5:])) > 0 {
				name = true
			}
			if strings.HasPrefix(l, "description:") && len(strings.TrimSpace(l[12:])) > 0 {
				desc = true
			}
			if strings.HasPrefix(l, "user_invocable:") {
				userInv = true
			}
		}
	}
	if !name {
		res.Findings = append(res.Findings, "Missing or empty 'name' in frontmatter")
		res.Pass = false
	}
	if !desc {
		res.Findings = append(res.Findings, "Missing or empty 'description' in frontmatter")
		res.Pass = false
	}
	if !userInv {
		res.Findings = append(res.Findings, "Missing 'user_invocable' in frontmatter")
		res.Pass = false
	}
	// Check for <intake> and skip/dismiss
	intakeIdx := -1
	for i, l := range lines {
		if strings.Contains(l, "<intake>") {
			intakeIdx = i
			break
		}
	}
	if intakeIdx != -1 {
		skipMention := false
		for _, l := range lines[intakeIdx:] {
			if strings.Contains(strings.ToLower(l), "skip") || strings.Contains(strings.ToLower(l), "dismiss") {
				skipMention = true
				break
			}
		}
		if skipMention {
			// Check <routing> for skip/dismiss
			routingIdx := -1
			for i, l := range lines {
				if strings.Contains(l, "<routing>") {
					routingIdx = i
					break
				}
			}
			cancelFound := false
			if routingIdx != -1 {
				for _, l := range lines[routingIdx:] {
					if strings.Contains(strings.ToLower(l), "skip") || strings.Contains(strings.ToLower(l), "dismiss") {
						cancelFound = true
						break
					}
				}
			}
			if !cancelFound {
				res.Findings = append(res.Findings, "Missing skip/dismiss routing — intake mentions but routing has no cancel handler")
				res.Pass = false
			}
		}
	}
	// Check workflow references in <routing>
	workflowRef := regexp.MustCompile(`workflows/([\w\-]+\.md)`)
	for _, l := range lines {
		matches := workflowRef.FindAllStringSubmatch(l, -1)
		for _, m := range matches {
			wf := filepath.Join(skillDir, "workflows", m[1])
			if _, err := os.Stat(wf); os.IsNotExist(err) {
				res.Findings = append(res.Findings, fmt.Sprintf("Missing workflow file: %s", m[1]))
				res.Pass = false
			}
		}
	}
	// Check description breadth
	descLine := ""
	for _, l := range lines {
		if strings.HasPrefix(l, "description:") {
			descLine = strings.TrimSpace(l[12:])
			break
		}
	}
	if descLine != "" {
		generic := []string{"code", "fix", "help", "debug", "test"}
		for _, g := range generic {
			if descLine == g {
				res.Warnings = append(res.Warnings, "Description is too generic: '"+g+"'")
			}
		}
	}
	// Set name
	for _, l := range lines {
		if strings.HasPrefix(l, "name:") {
			res.Name = strings.TrimSpace(l[5:])
			break
		}
	}
	return res
}
