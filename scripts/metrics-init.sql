-- DevKit Effectiveness Metrics Schema
-- Storage: ~/databases/claude.db (SQLite MCP)
-- See: docs/ADR-0017-effectiveness-measurement.md

-- PR-level metrics: one row per PR across all DevKit-managed projects
CREATE TABLE IF NOT EXISTS pr_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    repo TEXT NOT NULL,
    pr_number INTEGER NOT NULL,
    branch TEXT,
    created_at TEXT,
    merged_at TEXT,
    push_count INTEGER DEFAULT 1,
    ci_first_pass INTEGER,
    ci_total_runs INTEGER DEFAULT 1,
    ci_green_runs INTEGER DEFAULT 0,
    fix_push_cycles INTEGER DEFAULT 0,
    labels TEXT,
    collected_at TEXT NOT NULL,
    UNIQUE(repo, pr_number)
);

CREATE INDEX IF NOT EXISTS idx_pr_metrics_repo ON pr_metrics(repo);
CREATE INDEX IF NOT EXISTS idx_pr_metrics_merged ON pr_metrics(merged_at);

-- Conformance scores: one row per project per audit run
CREATE TABLE IF NOT EXISTS conformance_scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    repo TEXT NOT NULL,
    audit_date TEXT NOT NULL,
    total_checks INTEGER,
    passed INTEGER,
    failed INTEGER,
    skipped INTEGER,
    score_pct REAL,
    details TEXT
);

CREATE INDEX IF NOT EXISTS idx_conformance_repo ON conformance_scores(repo);
CREATE INDEX IF NOT EXISTS idx_conformance_date ON conformance_scores(audit_date);

-- Pattern application events: when a KG/AP/SYN entry prevented or caught an issue
CREATE TABLE IF NOT EXISTS pattern_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id TEXT NOT NULL,
    entry_title TEXT,
    event_type TEXT NOT NULL,
    project TEXT,
    session_date TEXT NOT NULL,
    description TEXT,
    source TEXT DEFAULT 'rules-file'
);

CREATE INDEX IF NOT EXISTS idx_pattern_entry ON pattern_events(entry_id);
CREATE INDEX IF NOT EXISTS idx_pattern_date ON pattern_events(session_date);

-- Skill usage tracking
CREATE TABLE IF NOT EXISTS skill_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    skill_name TEXT NOT NULL,
    invoked_at TEXT NOT NULL,
    project TEXT,
    workflow_used TEXT,
    completed INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_skill_name ON skill_usage(skill_name);
CREATE INDEX IF NOT EXISTS idx_skill_date ON skill_usage(invoked_at);

-- Autolearn velocity: pattern lifecycle tracking
CREATE TABLE IF NOT EXISTS autolearn_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    entry_id TEXT,
    source_project TEXT,
    event_date TEXT NOT NULL,
    issue_number INTEGER,
    description TEXT
);

CREATE INDEX IF NOT EXISTS idx_autolearn_type ON autolearn_events(event_type);
CREATE INDEX IF NOT EXISTS idx_autolearn_date ON autolearn_events(event_date);
