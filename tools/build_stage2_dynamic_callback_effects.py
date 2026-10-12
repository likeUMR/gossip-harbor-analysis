"""Extract likely effects from callback function-value definitions and link by field name."""
from __future__ import annotations
import hashlib, json, re, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / 'analysis_data/logic_index/lua/decoded'
OUT = ROOT / 'analysis_data/logic_index/stage2'
REP = ROOT / 'analysis_output/logic_recovery/stage2'
DEF = re.compile(r'^\s*(?:function\s+)?(?P<field>(?:[A-Za-z_]\w*\.)?(?:OnClickedFunc|OnClick|clickCallback|callback|OnLuaPointerDown|OnLuaPointerUp|OnLuaDrag|m_\w*Callback|m_\w*Func))\s*(?:\([^)]*\))?\s*=\s*function\s*|^\s*function\s+(?P<method>(?:[A-Za-z_]\w*\.)?(?:OnClickedFunc|OnClick|clickCallback|callback|OnLuaPointerDown|OnLuaPointerUp|OnLuaDrag|m_\w*Callback|m_\w*Func))\s*\(')
ASSIGN_EFFECT = re.compile(r'\bself\.[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*=')
EVENT_EFFECT = re.compile(r'\bEventDispatcher\s*\.\s*(?:DispatchEvent|PostEvent)\s*\(')
UI_EFFECT = re.compile(r'\bGM\s*\.\s*UIManager\s*[:.]')
NET_EFFECT = re.compile(r'\b(?:ApiMessage|Api|Network)\s*[:.]')

def stable(*parts):
    return hashlib.sha256('\0'.join(map(str, parts)).encode()).hexdigest()

def main():
    out = OUT / 'dynamic_callback_effects.sqlite3'
    if out.exists(): out.unlink()
    db = sqlite3.connect(out)
    db.executescript('''
      CREATE TABLE definitions(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,line INTEGER,
        field_name TEXT,body_text TEXT,body_end_line INTEGER);
      CREATE TABLE effects(id TEXT PRIMARY KEY,definition_id TEXT,effect_kind TEXT,line INTEGER,expression TEXT);
      CREATE TABLE links(id TEXT PRIMARY KEY,call_id TEXT,definition_id TEXT,certainty TEXT);
    ''')
    definitions, effects = [], []
    for src in sorted(LUA.glob('*/decompiled.lua')):
        lines = src.read_text(encoding='utf-8', errors='replace').splitlines()
        for i, line in enumerate(lines):
            match = DEF.match(line)
            if not match: continue
            field = (match.group('field') or match.group('method') or '').rsplit('.', 1)[-1]
            depth, end = 0, i
            for j in range(i, len(lines)):
                code = lines[j].strip()
                depth += len(re.findall(r'\bfunction\b|\bif\b|\bfor\b|\bwhile\b|\bdo\b', code))
                depth -= len(re.findall(r'\bend\b', code))
                if j > i and depth <= 0:
                    end = j; break
            body = '\n'.join(lines[i:end + 1])
            ident = stable(src, i, field)
            definitions.append((ident, src.parent.name, str(src), i + 1, field, body, end + 1))
            for kind, pattern in [('state_mutation', ASSIGN_EFFECT), ('event_dispatch', EVENT_EFFECT), ('ui_effect', UI_EFFECT), ('network_call', NET_EFFECT)]:
                for found in pattern.finditer(body):
                    effects.append((stable(ident, kind, found.start()), ident, kind,
                                    i + 1 + body[:found.start()].count('\n'), found.group(0)[:180]))
    db.executemany('INSERT INTO definitions VALUES(?,?,?,?,?,?,?)', definitions)
    db.executemany('INSERT INTO effects VALUES(?,?,?,?,?)', effects)
    calls_db = sqlite3.connect(OUT / 'dynamic_callbacks.sqlite3')
    by_field = {}
    for row in definitions: by_field.setdefault(row[4], []).append(row)
    for call_id, expression in calls_db.execute('SELECT id,field_expression FROM calls'):
        for definition in by_field.get(expression.rsplit('.', 1)[-1], []):
            db.execute('INSERT INTO links VALUES(?,?,?,?)', (stable(call_id, definition[0]), call_id, definition[0], 'field_name_candidate'))
    db.commit()
    summary = {'definitions': len(definitions), 'effects': len(effects), 'links': db.execute('SELECT count(*) FROM links').fetchone()[0], 'by_effect': dict(db.execute('SELECT effect_kind,count(*) FROM effects GROUP BY effect_kind')), 'database': str(out.relative_to(ROOT)).replace('\\', '/')}
    (REP / 'stage2_dynamic_callback_effects_summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    calls_db.close(); db.close(); print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == '__main__': main()
