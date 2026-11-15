#!/usr/bin/env python3
"""Publish docs/TICKETS.md to GitHub issues in this repo's origin.

Creates labels and the submission milestone if missing, creates an issue for
every ticket whose `GitHub issue:` is `pending` (in key order), writes the
issue number back into docs/TICKETS.md, then refreshes every mapped issue's
body so dependencies show both local keys and issue numbers.

Safe to rerun: mapped tickets are never recreated. Requires the `gh` CLI.
Usage: python3 scripts/create_issues.py [--dry-run]
"""
from pathlib import Path
import json, re, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
TICKETS = ROOT / 'docs/TICKETS.md'
MILESTONE = 'Hackathon submission'
MILESTONE_DUE = '2026-11-15T17:00:00Z'  # 12:00 EST, last known cutoff (unconfirmed; see T015)
DRY = '--dry-run' in sys.argv

LABELS = {
    'status:queued': ('d4c5f9', 'Reviewed; waiting on dependencies'),
    'status:ready': ('0e8a16', 'Dependencies integrated; can be claimed'),
    'status:in-progress': ('fbca04', 'Claimed by a session'),
    'status:review': ('1d76db', 'PR open'),
    'status:blocked': ('b60205', 'Real dependency or device problem'),
    'priority:must-have': ('b60205', 'Required for the submitted demo'),
    'priority:should-have': ('fbca04', 'Wanted; cut after optional work'),
    'priority:optional': ('c5def5', 'After submission unless ahead'),
    'priority:stretch': ('bfdadc', 'Only after the core demo is done'),
    'device-gate': ('5319e7', 'Needs evidence from the real iPhone'),
}


def gh(*args, input=None):
    if DRY:
        print('DRY gh', ' '.join(args)); return ''
    r = subprocess.run(['gh', *args], cwd=ROOT, input=input, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f'gh {" ".join(args)} failed:\n{r.stderr}')
    return r.stdout.strip()


def parse():
    text = TICKETS.read_text()
    targets = {m.group(1): m.group(2).strip() for m in
               re.finditer(r'^\| (T\d{3}) \|[^|]+\|[^|]+\|[^|]+\| ([^|]+) \|$', text, re.M)}
    heads = list(re.finditer(r'^### \[(T\d{3})\] (.+)$', text, re.M))
    tickets = []
    for i, m in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else text.index('## State discipline')
        block = text[m.end():end]
        field = lambda name: (re.search(rf'^{name}: (.+)$', block, re.M) or [None, ''])[1].strip()
        what = re.search(r'^What:\n(.*?)\n\nDone when:\n(.*)$', block, re.S | re.M)
        tickets.append({
            'key': m.group(1), 'title': m.group(2).strip(),
            'area': field('Area'), 'priority': field('Priority').split(' ')[0],
            'status': field('Status').split(' ')[0], 'owner': field('Owner/session'),
            'timebox': field('Timebox'), 'deps': [] if field('Depends on') == 'none'
            else [d.strip() for d in field('Depends on').split(',')],
            'files': field('Allowed files'), 'contract': field('Relevant contract'),
            'issue': field('GitHub issue'), 'target': targets.get(m.group(1), ''),
            'what': what.group(1).strip() if what else '', 'done': what.group(2).strip() if what else '',
        })
    return tickets


def body(t, mapping):
    deps = ', '.join(f'{d} ({mapping.get(d, "unmapped")})' for d in t['deps']) or 'none'
    return f"""**Local key:** {t['key']} · **Target:** {t["target"] + (" EST" if t["target"][:1].isdigit() else "")} · **Timebox:** {t['timebox']}
**Depends on:** {deps}
**Allowed files:** {t['files']}
**Contract:** {t['contract']}
**Owner/session:** {t['owner']}

## What

{t['what']}

## Done when

{t['done']}

---
Source of truth: [`docs/TICKETS.md`](../blob/main/docs/TICKETS.md). Claim by switching the label to `status:in-progress`; close through a PR with `Closes #<this issue>`. Device-gated work needs real iPhone evidence, not simulator or mock results.
"""


def labels_for(t):
    out = [f"status:{t['status']}", f"priority:{t['priority']}", f"area:{t['area']}"]
    if t['key'] in {'T001', 'T002', 'T003', 'T009', 'T011', 'T012', 'T016', 'T019', 'T020'}:
        out.append('device-gate')
    return out


def main():
    tickets = parse()
    for t in tickets:
        if t['priority'] not in {'must-have', 'should-have', 'optional', 'stretch'}:
            sys.exit(f"{t['key']}: unknown priority {t['priority']}")
    for name, (color, desc) in LABELS.items():
        gh('label', 'create', name, '--color', color, '--description', desc, '--force')
    for area in sorted({t['area'] for t in tickets}):
        gh('label', 'create', f'area:{area}', '--color', 'ededed', '--force')
    repo = gh('repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner') or 'OWNER/REPO'
    existing = gh('api', f'repos/{repo}/milestones?state=all', '-q', '.[].title')
    if MILESTONE not in (existing or '').splitlines():
        gh('api', f'repos/{repo}/milestones', '-f', f'title={MILESTONE}', '-f', f'due_on={MILESTONE_DUE}',
           '-f', 'description=Everything needed for the submitted demo. Due date is the last known cutoff; T015 confirms it.')

    mapping = {t['key']: t['issue'] for t in tickets if t['issue'].startswith('#')}
    text = TICKETS.read_text()
    for t in sorted(tickets, key=lambda t: t['key']):
        if t['key'] in mapping:
            continue
        url = gh('issue', 'create', '--title', f"[{t['key']}] {t['title']}", '--body', body(t, mapping),
                 '--milestone', MILESTONE, *sum((['--label', l] for l in labels_for(t)), []))
        num = '#' + (url.rsplit('/', 1)[-1] if url else '?')
        mapping[t['key']] = num
        print(f"{t['key']} -> {num} {url}")
        pat = re.compile(rf'(^### \[{t["key"]}\] .+?^GitHub issue: )pending$', re.S | re.M)
        text, n = pat.subn(rf'\g<1>{num}', text, count=1)
        if n != 1:
            sys.exit(f"Could not record mapping for {t['key']}")
        if not DRY:
            TICKETS.write_text(text)

    for t in tickets:  # refresh bodies so dependency numbers are complete
        t['issue'] = mapping.get(t['key'], t['issue'])
        if t['issue'].startswith('#'):
            num = t['issue'][1:]
            want = set(labels_for(t))
            have = set((gh('issue', 'view', num, '--json', 'labels', '-q', '.labels[].name') or '').splitlines())
            managed = {l for l in have if l.split(':')[0] in {'status', 'priority', 'area'} or l == 'device-gate'}
            args = ['issue', 'edit', num, '--title', f"[{t['key']}] {t['title']}", '--body', body(t, mapping)]
            if 'status:in-progress' in have or 'status:review' in have:
                want = {l for l in want if not l.startswith('status:')} | {l for l in have if l.startswith('status:')}
            for l in sorted(want - have): args += ['--add-label', l]
            for l in sorted(managed - want): args += ['--remove-label', l]
            gh(*args)
    print(json.dumps(mapping, indent=1))


if __name__ == '__main__':
    main()
