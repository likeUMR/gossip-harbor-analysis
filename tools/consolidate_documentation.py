"""Recover documented analysis without regenerating or discarding current pages."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import yaml

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'analysis_output/logic_recovery/stage3'
SITE = STAGE / 'mkdocs_site'
DOCS = SITE / 'docs'
AUDIT = STAGE / 'consolidation_audit'
PREFIX = DOCS.relative_to(ROOT).as_posix() + '/'

def git_text(ref, path):
    r = subprocess.run(['git', 'show', ref + ':' + path], cwd=ROOT, capture_output=True)
    return r.stdout.decode('utf-8') if r.returncode == 0 else None

def title(p):
    m = re.search(r'^#\s+(.+)', p.read_text(encoding='utf-8'), re.M)
    return m.group(1) if m else p.stem

def links(nav):
    if isinstance(nav, str):
        yield nav
    elif isinstance(nav, list):
        for v in nav: yield from links(v)
    elif isinstance(nav, dict):
        for v in nav.values(): yield from links(v)

def tree(folder, allowed):
    result = []
    index = folder / 'index.md'
    if index in allowed: result.append(index.relative_to(DOCS).as_posix())
    for p in sorted(folder.glob('*.md')):
        if p != index and p in allowed:
            result.append({title(p): p.relative_to(DOCS).as_posix()})
    for sub in sorted(p for p in folder.iterdir() if p.is_dir()):
        child = tree(sub, allowed)
        if child:
            label = title(sub/'index.md') if (sub/'index.md').exists() else sub.name
            result.append({label: child})
    return result

def main():
    AUDIT.mkdir(exist_ok=True)
    backup = AUDIT / 'before'
    if not backup.exists():
        shutil.copytree(DOCS, backup/'docs')
        shutil.copy2(SITE/'mkdocs.yml', backup/'mkdocs.yml')
    changes = []
    # Recover the expanded explanations, retaining the short current text as a note.
    for rel in ['operations/merge/index.md', 'operations/merge/normal/index.md', 'operations/merge/special/index.md']:
        old = git_text('062dc59', PREFIX+rel)
        p = DOCS/rel
        current = p.read_text(encoding='utf-8')
        if old and len(old) > len(current)*1.2:
            p.write_text(old + '\n\n## 整合前的补充说明\n\n' + '\n'.join(current.splitlines()[1:]), encoding='utf-8')
            changes.append({'path':rel, 'action':'restore expanded explanation', 'source':'git:062dc59'})
    # Keep substantive historical reductions with explicit provenance, never silently
    # replace revised rules with old wording/configuration snapshots.
    old_files = subprocess.check_output(['git','ls-tree','-r','--name-only','062dc59',PREFIX+'operations/generator'],cwd=ROOT,text=True).splitlines()
    history = DOCS/'recovered_analysis/generator'
    history.mkdir(parents=True, exist_ok=True)
    historical_nav = []
    for f in old_files:
        if not f.endswith('.md'): continue
        old = git_text('062dc59', f)
        rel = f.removeprefix(PREFIX)
        p = DOCS/rel
        current = p.read_text(encoding='utf-8') if p.exists() else ''
        if len(old) <= len(current)*1.2 or len(old)-len(current) <= 300: continue
        dest = history/(rel.removeprefix('operations/generator/').replace('/','_'))
        # Resolve links from their original page location, then rebase them.
        def rebase(m):
            target = m.group(1)
            if '://' in target or target.startswith(('#','/')): return m.group(0)
            path, sep, anchor = target.partition('#')
            return '](' + os.path.relpath(p.parent/path, dest.parent).replace('\\','/') + (sep+anchor if sep else '') + ')'
        body = re.sub(r'\]\(([^)]+)\)', rebase, old)
        warning = '> 历史分析补充，来源：Git `062dc59`。此页保存新版缩减前的分析和配置记录；与当前正文冲突时以当前核实说明为准，历史案例不是原版运行实测。\n\n'
        dest.write_text(warning + body, encoding='utf-8')
        historical_nav.append({title(dest):dest.relative_to(DOCS).as_posix()})
        changes.append({'path':rel,'action':'retain historical supplement','historical_characters':len(old),'current_characters':len(current),'source':'git:062dc59'})
    # Recover referenced source evidence from the existing indexed modules.
    modules = {m['name']:m for m in json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))}
    evidence = []
    for page in DOCS.rglob('*.md'):
        content = page.read_text(encoding='utf-8')
        for target in re.findall(r'\]\(([^)]+)\)',content):
            target = target.split('#')[0]
            if '://' in target or not target or target.startswith('/'): continue
            dest = (page.parent/target).resolve()
            if dest.exists() or not dest.is_relative_to(DOCS.resolve()): continue
            name=dest.name
            field='disassembly_path' if name.endswith('.disassembly.txt') else 'source_path'
            module=name.removesuffix('.disassembly.txt').removesuffix('.lua')
            record=modules.get(module)
            if not record or not record.get(field):continue
            src=ROOT/record[field]
            if src.exists():
                dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(src,dest)
                evidence.append(dest.relative_to(DOCS).as_posix())
    # All existing pages must be discoverable from one navigation tree.
    config=yaml.safe_load((SITE/'mkdocs.yml').read_text(encoding='utf-8'))
    nav=config['nav']; referenced=set(links(nav))
    for label, area in [('母体点击','generator'),('棋子拖拽与合成','merge'),('订单提交','orders'),('付费项目','paid')]:
        branch=next(item[label] for item in nav if label in item)
        folder=DOCS/'operations'/area
        missing={p for p in folder.rglob('*.md') if p.relative_to(DOCS).as_posix() not in referenced}
        if missing:
            branch.append({'完整机制与后续处理':tree(folder,missing)})
            changes.append({'area':area,'action':'expose previously unlisted pages','count':len(missing)})
    if not any('首页' in x for x in nav):nav.insert(0,{'首页':'index.md'})
    if historical_nav and not any('历史分析补充' in x for x in nav):nav.append({'历史分析补充':historical_nav})
    references=[p for d in ['reference','verification'] for p in (DOCS/d).glob('*.md')]
    if not any('配置与验证' in x for x in nav):nav.append({'配置与验证':[{title(p):p.relative_to(DOCS).as_posix()} for p in references]})
    config['nav']=nav
    (SITE/'mkdocs.yml').write_text(yaml.safe_dump(config,allow_unicode=True,sort_keys=False,width=120),encoding='utf-8')
    report={'changes':changes,'recovered_evidence_files':evidence,'canonical_pages':len(list((DOCS/'operations').rglob('*.md'))),'source_backup':str(backup)}
    (AUDIT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'changes':changes,'recovered_evidence_count':len(evidence),'canonical_pages':report['canonical_pages']},ensure_ascii=False,indent=2))

if __name__ == '__main__':main()
