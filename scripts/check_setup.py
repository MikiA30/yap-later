#!/usr/bin/env python3
"""Validate this planning starter, not application behavior or iOS support."""
from pathlib import Path
import json, re, sys

root = Path(__file__).resolve().parents[1]
errors = []
required = ['AGENTS.md','CLAUDE.md','README.md','START_HERE.md',
    'ideation/PROJECT_BRIEF.md','ideation/EVENT.md','.plans/yap-later-spec.md',
    'docs/PLAN.md','docs/ARCHITECTURE.md','docs/CONTRACTS.md','docs/FEASIBILITY.md',
    'docs/TICKETS.md','docs/DECISIONS.md','docs/COMMANDS.md','docs/DEMO.md',
    'docs/PREPARATION.md','docs/SOURCES.md','.claude/skills/interview/SKILL.md',
    '.claude/skills/interview/LICENSE','contracts/money-proposal.schema.json',
    'eval/requests.json','scripts/worktree.sh','scripts/create_issues.py',
    '.claude/skills/swiftui-motion/SKILL.md']
for name in required:
    if not (root/name).is_file(): errors.append('Missing '+name)
for name,prompt in {'kickoff':'KICKOFF','tickets':'TICKETS','skeleton':'SKELETON',
                    'task':'TASK','sync':'SYNC','team-status':'STATUS'}.items():
    cmd=root/'.claude/commands'/f'{name}.md'
    if not cmd.is_file(): errors.append('Missing command '+name); continue
    if f'prompts/{prompt}.md' not in cmd.read_text(): errors.append('Wrong prompt in '+name)
    if not (root/'prompts'/f'{prompt}.md').is_file(): errors.append('Missing prompt '+prompt)
if (root/'.claude/commands/interview.md').exists(): errors.append('Duplicate interview command')
if not (root/'CLAUDE.md').read_text().startswith('@AGENTS.md'): errors.append('Missing shared instructions import')
for p in root.rglob('*.md'):
    if '.git' in p.parts: continue
    text=p.read_text()
    for stale in ['.plans/ket-lite-spec.md','ketlite_engine','KetLite.xcodeproj']:
        if stale in text: errors.append(f'Stale active reference {stale} in {p.relative_to(root)}')

text=(root/'docs/TICKETS.md').read_text()
matches=list(re.finditer(r'^### \[(T\d{3})\] (.+)$',text,re.M))
graph={}
for i,m in enumerate(matches):
    key=m.group(1)
    block=text[m.end():matches[i+1].start() if i+1<len(matches) else len(text)]
    if key in graph: errors.append('Duplicate ticket '+key)
    dep=re.search(r'^Depends on: (.+)$',block,re.M)
    if not dep: errors.append('Missing dependencies '+key); continue
    graph[key]=[] if dep.group(1)=='none' else [x.strip() for x in dep.group(1).split(',')]
    for field in ['Status:','Owner/session:','Allowed files:','Done when:']:
        if field not in block: errors.append('Missing '+field+' in '+key)
if not graph: errors.append('No tickets parsed')
for key,deps in graph.items():
    for dep in deps:
        if dep not in graph: errors.append(f'{key} depends on missing {dep}')
visiting=set(); done=set()
def visit(key):
    if key in visiting: errors.append('Dependency cycle at '+key); return
    if key in done or key not in graph: return
    visiting.add(key)
    for dep in graph[key]: visit(dep)
    visiting.remove(key); done.add(key)
for key in graph: visit(key)
for p in (root/'contracts').rglob('*.json'):
    try: json.loads(p.read_text())
    except Exception as e: errors.append(f'{p.name}: {e}')
corpus=json.loads((root/'eval/requests.json').read_text())
ids=[x['id'] for x in corpus['cases']]
if len(ids)!=len(set(ids)): errors.append('Duplicate evaluation case ID')
if errors:
    print('SETUP CHECK FAILED:'); print('\n'.join(errors)); sys.exit(1)
print(f'Setup consistent: {len(graph)} tickets, acyclic dependencies, 7 Claude entry points, {len(ids)} evaluation cases.')
print('This check does not validate schema semantics, compile an app, or prove on-device/offline behavior.')
