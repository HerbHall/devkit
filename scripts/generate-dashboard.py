#!/usr/bin/env python3
"""Generate DevKit Effectiveness Dashboard as a standalone HTML file.

Reads metrics from ~/databases/claude.db and produces dashboard.html
with embedded Chart.js visualizations.

Usage:
    python scripts/generate-dashboard.py [--db PATH] [--output PATH]

Defaults:
    --db      ~/databases/claude.db
    --output  metrics/dashboard.html
"""

import argparse
import json
import os
import sqlite3
import sys
from datetime import datetime, timedelta
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def query(conn, sql):
    """Execute SQL and return list of dicts."""
    cur = conn.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def get_rework_by_project(conn, days=30):
    return query(conn, f"""
        SELECT repo,
            COUNT(*) as prs,
            ROUND(AVG(push_count), 1) as avg_pushes,
            ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct,
            SUM(fix_push_cycles) as fix_cycles
        FROM pr_metrics
        WHERE merged_at >= date('now', '-{days} days')
        GROUP BY repo ORDER BY first_pass_pct DESC
    """)


def get_rework_trend(conn):
    """Monthly rework trend for the last 6 months."""
    return query(conn, """
        SELECT strftime('%Y-%m', merged_at) as month,
            COUNT(*) as prs,
            ROUND(AVG(push_count), 1) as avg_pushes,
            ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct
        FROM pr_metrics
        WHERE merged_at >= date('now', '-180 days')
        GROUP BY month ORDER BY month
    """)


def get_pattern_events(conn, days=30):
    return query(conn, f"""
        SELECT entry_id, entry_title,
            COALESCE(source, 'rules-file') as source,
            COUNT(*) as total,
            SUM(CASE WHEN event_type = 'applied' THEN 1 ELSE 0 END) as applied,
            SUM(CASE WHEN event_type = 'prevented' THEN 1 ELSE 0 END) as prevented,
            SUM(CASE WHEN event_type = 'caught' THEN 1 ELSE 0 END) as caught,
            MAX(session_date) as last_used
        FROM pattern_events
        WHERE session_date >= date('now', '-{days} days')
        GROUP BY entry_id ORDER BY total DESC LIMIT 20
    """)


def get_pattern_source_breakdown(conn, days=30):
    return query(conn, f"""
        SELECT COALESCE(source, 'rules-file') as source, COUNT(*) as count
        FROM pattern_events
        WHERE session_date >= date('now', '-{days} days')
        GROUP BY source
    """)


def get_skill_usage(conn, days=30):
    return query(conn, f"""
        SELECT skill_name, COUNT(*) as invocations,
            ROUND(100.0 * SUM(completed) / COUNT(*), 0) as completion_pct
        FROM skill_usage
        WHERE invoked_at >= date('now', '-{days} days')
        GROUP BY skill_name ORDER BY invocations DESC
    """)


def get_conformance(conn):
    return query(conn, """
        SELECT repo, audit_date, score_pct, passed, failed
        FROM conformance_scores c1
        WHERE audit_date = (
            SELECT MAX(audit_date) FROM conformance_scores c2
            WHERE c2.repo = c1.repo
        ) ORDER BY repo
    """)


def get_autolearn_pipeline(conn, days=30):
    return query(conn, f"""
        SELECT event_type, COUNT(*) as count
        FROM autolearn_events
        WHERE event_date >= date('now', '-{days} days')
        GROUP BY event_type
        ORDER BY CASE event_type
            WHEN 'discovered' THEN 1 WHEN 'issue_created' THEN 2
            WHEN 'ingested' THEN 3 WHEN 'applied' THEN 4 ELSE 5
        END
    """)


def get_totals(conn):
    row = query(conn, "SELECT COUNT(*) as total FROM pr_metrics")
    pr_total = row[0]["total"] if row else 0
    row = query(conn, "SELECT COUNT(*) as total FROM pattern_events")
    pattern_total = row[0]["total"] if row else 0
    row = query(conn, "SELECT COUNT(*) as total FROM skill_usage")
    skill_total = row[0]["total"] if row else 0
    row = query(conn, """
        SELECT COUNT(DISTINCT repo) as repos FROM pr_metrics
    """)
    repo_count = row[0]["repos"] if row else 0
    return {
        "prs": pr_total, "patterns": pattern_total,
        "skills": skill_total, "repos": repo_count
    }


def generate_html(data):
    rework = data["rework"]
    trend = data["trend"]
    patterns = data["patterns"]
    source_breakdown = data["source_breakdown"]
    skills = data["skills"]
    conformance = data["conformance"]
    pipeline = data["pipeline"]
    totals = data["totals"]
    generated = data["generated"]

    # Prepare chart data
    trend_labels = json.dumps([t["month"] for t in trend])
    trend_pct = json.dumps([t["first_pass_pct"] for t in trend])
    trend_pushes = json.dumps([t["avg_pushes"] for t in trend])

    rework_labels = json.dumps([r["repo"].split("/")[-1] for r in rework])
    rework_pct = json.dumps([r["first_pass_pct"] for r in rework])
    rework_cycles = json.dumps([r["fix_cycles"] for r in rework])

    source_labels = json.dumps([s["source"] for s in source_breakdown])
    source_counts = json.dumps([s["count"] for s in source_breakdown])

    skill_labels = json.dumps([s["skill_name"] for s in skills])
    skill_counts = json.dumps([s["invocations"] for s in skills])

    # Build tables
    rework_rows = ""
    for r in rework:
        name = r["repo"].split("/")[-1]
        pct_class = "good" if r["first_pass_pct"] >= 80 else "warn" if r["first_pass_pct"] >= 50 else "bad"
        rework_rows += f"""<tr>
            <td>{name}</td><td>{r['prs']}</td>
            <td>{r['avg_pushes']}</td>
            <td class="{pct_class}">{r['first_pass_pct']}%</td>
            <td>{r['fix_cycles']}</td>
        </tr>"""

    pattern_rows = ""
    for p in patterns:
        pattern_rows += f"""<tr>
            <td>{p['entry_id']}</td>
            <td title="{p.get('entry_title', '')}">{(p.get('entry_title', '') or '')[:40]}</td>
            <td>{p['source']}</td>
            <td>{p['applied']}</td><td>{p['prevented']}</td>
            <td>{p['caught']}</td><td>{p['last_used']}</td>
        </tr>"""

    conformance_rows = ""
    for c in conformance:
        name = c["repo"].split("/")[-1]
        pct_class = "good" if c["score_pct"] >= 80 else "warn" if c["score_pct"] >= 50 else "bad"
        conformance_rows += f"""<tr>
            <td>{name}</td>
            <td class="{pct_class}">{c['score_pct']}%</td>
            <td>{c['passed']}</td><td>{c['failed']}</td>
            <td>{c['audit_date'][:10]}</td>
        </tr>"""

    pipeline_rows = ""
    for p in pipeline:
        pipeline_rows += f"<tr><td>{p['event_type']}</td><td>{p['count']}</td></tr>"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DevKit Effectiveness Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
<style>
  :root {{ --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #e6edf3;
           --muted: #8b949e; --good: #3fb950; --warn: #d29922; --bad: #f85149;
           --accent: #58a6ff; }}
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          background: var(--bg); color: var(--text); padding: 24px; }}
  h1 {{ font-size: 1.5rem; margin-bottom: 8px; }}
  .subtitle {{ color: var(--muted); margin-bottom: 24px; font-size: 0.85rem; }}
  .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
            gap: 16px; margin-bottom: 24px; }}
  .stat {{ background: var(--card); border: 1px solid var(--border); border-radius: 8px;
           padding: 16px; text-align: center; }}
  .stat-value {{ font-size: 2rem; font-weight: 700; color: var(--accent); }}
  .stat-label {{ color: var(--muted); font-size: 0.8rem; margin-top: 4px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(480px, 1fr));
           gap: 16px; margin-bottom: 24px; }}
  .card {{ background: var(--card); border: 1px solid var(--border); border-radius: 8px;
           padding: 16px; }}
  .card h2 {{ font-size: 1rem; margin-bottom: 12px; color: var(--accent); }}
  table {{ width: 100%; border-collapse: collapse; font-size: 0.85rem; }}
  th {{ text-align: left; padding: 8px; border-bottom: 1px solid var(--border);
       color: var(--muted); font-weight: 600; }}
  td {{ padding: 8px; border-bottom: 1px solid var(--border); }}
  .good {{ color: var(--good); font-weight: 600; }}
  .warn {{ color: var(--warn); font-weight: 600; }}
  .bad {{ color: var(--bad); font-weight: 600; }}
  canvas {{ max-height: 250px; }}
  .empty {{ color: var(--muted); font-style: italic; padding: 16px; }}
</style>
</head>
<body>
<h1>DevKit Effectiveness Dashboard</h1>
<p class="subtitle">Generated {generated} | Data from ~/databases/claude.db</p>

<div class="stats">
  <div class="stat"><div class="stat-value">{totals['repos']}</div><div class="stat-label">Repos Tracked</div></div>
  <div class="stat"><div class="stat-value">{totals['prs']}</div><div class="stat-label">PRs Collected</div></div>
  <div class="stat"><div class="stat-value">{totals['patterns']}</div><div class="stat-label">Pattern Events</div></div>
  <div class="stat"><div class="stat-value">{totals['skills']}</div><div class="stat-label">Skill Invocations</div></div>
</div>

<div class="grid">
  <div class="card">
    <h2>CI First-Pass Rate Trend</h2>
    {"<canvas id='trendChart'></canvas>" if trend else "<p class='empty'>No trend data yet</p>"}
  </div>
  <div class="card">
    <h2>First-Pass Rate by Project (Last 30 Days)</h2>
    {"<canvas id='projectChart'></canvas>" if rework else "<p class='empty'>Run /metrics collect first</p>"}
  </div>
</div>

<div class="grid">
  <div class="card">
    <h2>Rework Rate (Last 30 Days)</h2>
    {"<table><thead><tr><th>Project</th><th>PRs</th><th>Avg Pushes</th><th>1st Pass</th><th>Fix Cycles</th></tr></thead><tbody>" + rework_rows + "</tbody></table>" if rework else "<p class='empty'>No data</p>"}
  </div>
  <div class="card">
    <h2>Pattern Impact (Last 30 Days)</h2>
    {"<table><thead><tr><th>Entry</th><th>Title</th><th>Source</th><th>Applied</th><th>Prevented</th><th>Caught</th><th>Last Used</th></tr></thead><tbody>" + pattern_rows + "</tbody></table>" if patterns else "<p class='empty'>No pattern events recorded yet</p>"}
  </div>
</div>

<div class="grid">
  <div class="card">
    <h2>Pattern Source Breakdown</h2>
    {"<canvas id='sourceChart'></canvas>" if source_breakdown else "<p class='empty'>No data</p>"}
  </div>
  <div class="card">
    <h2>Skill Usage (Last 30 Days)</h2>
    {"<canvas id='skillChart'></canvas>" if skills else "<p class='empty'>No skill usage recorded yet</p>"}
  </div>
</div>

<div class="grid">
  <div class="card">
    <h2>Conformance Scores (Latest)</h2>
    {"<table><thead><tr><th>Project</th><th>Score</th><th>Passed</th><th>Failed</th><th>Date</th></tr></thead><tbody>" + conformance_rows + "</tbody></table>" if conformance else "<p class='empty'>Run /conformance-audit first</p>"}
  </div>
  <div class="card">
    <h2>Autolearn Pipeline (Last 30 Days)</h2>
    {"<table><thead><tr><th>Stage</th><th>Count</th></tr></thead><tbody>" + pipeline_rows + "</tbody></table>" if pipeline else "<p class='empty'>No autolearn events yet</p>"}
  </div>
</div>

<script>
const chartDefaults = {{
    color: '#e6edf3',
    borderColor: '#30363d',
    font: {{ family: '-apple-system, sans-serif' }}
}};
Chart.defaults.color = '#8b949e';
Chart.defaults.borderColor = '#30363d';

{'// Trend chart' if trend else ''}
{f"""
new Chart(document.getElementById('trendChart'), {{
    type: 'line',
    data: {{
        labels: {trend_labels},
        datasets: [{{
            label: 'First-Pass CI %',
            data: {trend_pct},
            borderColor: '#3fb950',
            backgroundColor: 'rgba(63,185,80,0.1)',
            fill: true, tension: 0.3
        }}, {{
            label: 'Avg Pushes/PR',
            data: {trend_pushes},
            borderColor: '#58a6ff',
            yAxisID: 'y1',
            tension: 0.3
        }}]
    }},
    options: {{
        responsive: true,
        scales: {{
            y: {{ beginAtZero: true, max: 100, title: {{ display: true, text: '%' }} }},
            y1: {{ position: 'right', beginAtZero: true, title: {{ display: true, text: 'Pushes' }}, grid: {{ drawOnChartArea: false }} }}
        }}
    }}
}});
""" if trend else ''}

{f"""
new Chart(document.getElementById('projectChart'), {{
    type: 'bar',
    data: {{
        labels: {rework_labels},
        datasets: [{{
            label: 'First-Pass %',
            data: {rework_pct},
            backgroundColor: {rework_pct}.map(v => v >= 80 ? '#3fb950' : v >= 50 ? '#d29922' : '#f85149')
        }}]
    }},
    options: {{
        responsive: true,
        scales: {{ y: {{ beginAtZero: true, max: 100 }} }},
        plugins: {{ legend: {{ display: false }} }}
    }}
}});
""" if rework else ''}

{f"""
new Chart(document.getElementById('sourceChart'), {{
    type: 'doughnut',
    data: {{
        labels: {source_labels},
        datasets: [{{ data: {source_counts}, backgroundColor: ['#58a6ff', '#3fb950', '#d29922'] }}]
    }},
    options: {{ responsive: true }}
}});
""" if source_breakdown else ''}

{f"""
new Chart(document.getElementById('skillChart'), {{
    type: 'bar',
    data: {{
        labels: {skill_labels},
        datasets: [{{ label: 'Invocations', data: {skill_counts}, backgroundColor: '#58a6ff' }}]
    }},
    options: {{
        responsive: true, indexAxis: 'y',
        plugins: {{ legend: {{ display: false }} }}
    }}
}});
""" if skills else ''}
</script>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Generate DevKit dashboard")
    home = os.path.expanduser("~")
    parser.add_argument("--db", default=os.path.join(home, "databases", "claude.db"))
    parser.add_argument("--output", default="metrics/dashboard.html")
    args = parser.parse_args()

    db_path = args.db
    # Handle MSYS path
    if db_path.startswith("/c/"):
        db_path = "C:/" + db_path[3:]

    if not os.path.exists(db_path):
        print(f"Database not found: {db_path}", file=sys.stderr)
        print("Run '/metrics collect' first.", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)

    data = {
        "rework": get_rework_by_project(conn),
        "trend": get_rework_trend(conn),
        "patterns": get_pattern_events(conn),
        "source_breakdown": get_pattern_source_breakdown(conn),
        "skills": get_skill_usage(conn),
        "conformance": get_conformance(conn),
        "pipeline": get_autolearn_pipeline(conn),
        "totals": get_totals(conn),
        "generated": datetime.now().strftime("%Y-%m-%d %H:%M"),
    }

    conn.close()

    html = generate_html(data)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html, encoding="utf-8")
    print(f"Dashboard generated: {output}")
    print(f"  PRs: {data['totals']['prs']} | Repos: {data['totals']['repos']} | "
          f"Pattern events: {data['totals']['patterns']} | Skill invocations: {data['totals']['skills']}")


if __name__ == "__main__":
    main()
