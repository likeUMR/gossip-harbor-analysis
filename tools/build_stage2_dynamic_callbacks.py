"""Discover Lua callback fields with AST evidence; links remain candidates."""
from __future__ import annotations

import collections
import hashlib
import json
import re
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / 'analysis_data/logic_index'
OUT = INDEX / 'stage2'
REPORT = ROOT / 'analysis_output/logic_recovery/stage2'
CALLBACK = re.compile(r'callback|handler|(?:click|clicked|selected)func|m_\w*func$|^OnLua', re.I)
FUNCTION = re.compile(r'^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(')
CALL = re.compile(r'(?P<field>(?:self|[A-Za-z_]\w*)(?:\.[A-Za-z_]\w+)+)\s*\(')
ASSIGN = re.compile(r'^\s*(?P<field>(?:(?:self|[A-Za-z_]\w*)(?:\.[A-Za-z_]\w+)*)?)\s*=\s*(?P<rhs>.+)$')


def stable(*parts):
    return hashlib.sha256('\0'.join(map(str, parts)).encode()).hexdigest()


def text(node):
    return node.text.decode('utf-8') if node else ''


def owner(node):
    parent = node.parent
    while parent:
        if parent.type == 'function_declaration':
            return text(parent.child_by_field_name('name'))
        parent = parent.parent
    return None


def main():
    out = OUT / 'dynamic_callbacks.sqlite3'
    if out.exists():
        out.unlink()
    db = sqlite3.connect(out)
    db.executescript('''
      CREATE TABLE calls(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,line INTEGER,
        function_symbol TEXT,field_expression TEXT,code_excerpt TEXT);
      CREATE TABLE assignments(id TEXT PRIMARY KEY,module TEXT,source_path TEXT,line INTEGER,
        function_symbol TEXT,field_expression TEXT,rhs TEXT,assignment_kind TEXT,code_excerpt TEXT);
      CREATE TABLE links(id TEXT PRIMARY KEY,call_id TEXT,assignment_id TEXT,certainty TEXT);
      CREATE INDEX callback_call_owner ON calls(source_path,function_symbol);
      CREATE INDEX callback_assignment_field ON assignments(module,field_expression);
    ''')
    calls, assignments, parsed, parse_errors = [], [], 0, []
    modules = json.loads((INDEX / 'lua_modules.json').read_text(encoding='utf-8'))
    for module in modules:
        path = ROOT / module['source_path']
        source = path.read_text(encoding='utf-8', errors='replace')
        parsed += 1
        lines = source.splitlines()
        current = None
        for line_no, line_text in enumerate(lines, 1):
            fm = FUNCTION.match(line_text)
            if fm:
                current = fm.group(1)
            for cm in CALL.finditer(line_text):
                field = cm.group('field')
                if CALLBACK.search(field.rsplit('.', 1)[-1]):
                    calls.append((stable(path, line_no, cm.start(), 'call'), module['name'], module['source_path'], line_no, current, field, line_text))
            am = ASSIGN.match(line_text)
            if am and CALLBACK.search(am.group('field').rsplit('.', 1)[-1]):
                rhs = am.group('rhs').strip()
                kind = 'function_literal' if rhs.startswith('function') else 'value_expression'
                assignments.append((stable(path, line_no, am.start(), 'assignment'), module['name'], module['source_path'], line_no, current, am.group('field'), rhs, kind, line_text))
    db.executemany('INSERT INTO calls VALUES(?,?,?,?,?,?,?)', calls)
    db.executemany('INSERT INTO assignments VALUES(?,?,?,?,?,?,?,?,?)', assignments)
    by_key = collections.defaultdict(list)
    for assignment in assignments:
        by_key[(assignment[1], assignment[5])].append(assignment)
        by_key[(assignment[1], assignment[5].rsplit('.', 1)[-1])].append(assignment)
    for call in calls:
        candidates = by_key.get((call[1], call[5]), []) + by_key.get((call[1], call[5].rsplit('.', 1)[-1]), [])
        for assignment in dict((a[0], a) for a in candidates).values():
            db.execute('INSERT INTO links VALUES(?,?,?,?)',
                       (stable(call[0], assignment[0]), call[0], assignment[0],
                        'same_module_expression_candidate_object_identity_unproven'))
    db.commit()
    summary = {
        'parsed_modules': parsed, 'parse_errors': parse_errors,
        'calls': len(calls), 'assignments': len(assignments),
        'links': db.execute('SELECT count(*) FROM links').fetchone()[0],
        'unlinked_calls': db.execute('SELECT count(*) FROM calls c WHERE NOT EXISTS(SELECT 1 FROM links l WHERE l.call_id=c.id)').fetchone()[0],
        'by_assignment_kind': dict(db.execute('SELECT assignment_kind,count(*) FROM assignments GROUP BY assignment_kind')),
        'database': str(out.relative_to(ROOT)).replace('\\', '/'),
        'limitations': ['Callback naming is a discovery heuristic, not exhaustive callback detection.',
                        'Matching field expressions do not prove the same object, lifetime, assignment order or active target.'],
    }
    (REPORT / 'stage2_dynamic_callbacks_summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
