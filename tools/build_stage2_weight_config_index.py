"""Extract literal weight configuration values and compute their probabilities."""
from __future__ import annotations
import bisect, hashlib, json, re, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA_ROOT = ROOT / "analysis_data" / "logic_index" / "lua" / "decoded"
JSON_ROOT = ROOT / "analysis_data" / "json"
OUT = ROOT / "analysis_data" / "logic_index" / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"
ASSIGN_RE = re.compile(r"(?P<field>[A-Za-z_]\w*(?:Weight|_Weight|WeightType|_WeightType))\s*=\s*(?P<value>-?\d+(?:\.\d+)?)")
TABLE_START_RE = re.compile(r"(?P<field>[A-Za-z_]\w*(?:Weight|_Weight))\s*=\s*\{")
CALL_RE = re.compile(r"Table\.ListWeightSelectOne\s*\(")
NONCODE_RE = re.compile(r"--\[(=*)\[.*?\]\1\]|--[^\r\n]*|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|\[(=*)\[.*?\]\2\]", re.S)

def mask(s): return NONCODE_RE.sub(lambda m: "".join("\n" if c == "\n" else " " for c in m.group()), s)
def stable(*x): return hashlib.sha256("\0".join(map(str,x)).encode()).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True); REPORT.mkdir(parents=True, exist_ok=True)
    path = OUT / "weight_config.sqlite3"
    if path.exists(): path.unlink()
    db = sqlite3.connect(path)
    db.executescript("""
      CREATE TABLE assignments (
        id TEXT PRIMARY KEY, source_kind TEXT NOT NULL, source_path TEXT NOT NULL,
        module TEXT, line INTEGER NOT NULL, field_name TEXT NOT NULL,
        numeric_value REAL NOT NULL, context TEXT NOT NULL, code_excerpt TEXT NOT NULL
      );
      CREATE TABLE selections (
        id TEXT PRIMARY KEY, source_path TEXT NOT NULL, module TEXT, line INTEGER NOT NULL,
        candidate_expression TEXT NOT NULL, weight_key_expression TEXT, code_excerpt TEXT NOT NULL
      );
      CREATE TABLE groups (
        id TEXT PRIMARY KEY, source_path TEXT NOT NULL, field_name TEXT NOT NULL,
        assignment_count INTEGER NOT NULL, weight_sum REAL NOT NULL, zero_count INTEGER NOT NULL,
        negative_count INTEGER NOT NULL, values_json TEXT NOT NULL
      );
    """)
    assignments = []
    for src in sorted(LUA_ROOT.glob("*/decompiled.lua")):
        text = src.read_text(encoding="utf-8", errors="replace"); masked = mask(text)
        lines = text.splitlines(); starts=[0]
        for m in re.finditer("\n", text): starts.append(m.end())
        for m in ASSIGN_RE.finditer(masked):
            line = bisect.bisect_right(starts, m.start()); val=float(m.group("value"))
            assignments.append(("lua",str(src),src.parent.name,line,m.group("field"),val,"literal_assignment",lines[line-1] if line<=len(lines) else ""))
        for m in CALL_RE.finditer(masked):
            # Balanced extraction is unnecessary for this index; preserve the call line and first argument.
            line=bisect.bisect_right(starts,m.start()); tail=text[m.end():text.find(")",m.end()) if text.find(")",m.end())>=0 else len(text)]
            args=tail.strip().split(",",1)
            db.execute("INSERT INTO selections VALUES(?,?,?,?,?,?,?)", (stable(src,m.start()),str(src),src.parent.name,line,args[0].strip(),args[1].strip() if len(args)>1 else None,lines[line-1] if line<=len(lines) else ""))
    for src in sorted(JSON_ROOT.glob("*.json")):
        try: data=json.loads(src.read_text(encoding="utf-8"))
        except Exception: continue
        def walk(obj, path_parts="root"):
            if isinstance(obj,dict):
                for k,v in obj.items():
                    if isinstance(v,(int,float)) and re.search(r"(?:weight|rate|chance|probability)",k,re.I):
                        assignments.append(("json",str(src),None,0,k,float(v),path_parts, f"{k}: {v}"))
                    walk(v, path_parts+"."+str(k))
            elif isinstance(obj,list):
                for i,v in enumerate(obj): walk(v,path_parts+f"[{i}]")
        walk(data)
    db.executemany("INSERT INTO assignments VALUES(?,?,?,?,?,?,?,?,?)", [(stable(*a),*a) for a in assignments])
    for field in sorted(set(a[4] for a in assignments)):
        vals=[a[5] for a in assignments if a[4]==field]
        if not vals: continue
        db.execute("INSERT INTO groups VALUES(?,?,?,?,?,?,?,?)", (stable("group",field), "multiple", field, len(vals), sum(vals), sum(v==0 for v in vals), sum(v<0 for v in vals), json.dumps(vals)))
    db.execute("CREATE INDEX idx_weight_field ON assignments(field_name)")
    db.execute("CREATE INDEX idx_weight_source ON assignments(source_path)")
    db.commit()
    summary={"assignments":db.execute("SELECT count(*) FROM assignments").fetchone()[0],"selections":db.execute("SELECT count(*) FROM selections").fetchone()[0],"groups":db.execute("SELECT count(*) FROM groups").fetchone()[0],"lua_assignments":db.execute("SELECT count(*) FROM assignments WHERE source_kind='lua'").fetchone()[0],"json_assignments":db.execute("SELECT count(*) FROM assignments WHERE source_kind='json'").fetchone()[0],"zero_values":db.execute("SELECT count(*) FROM assignments WHERE numeric_value=0").fetchone()[0],"negative_values":db.execute("SELECT count(*) FROM assignments WHERE numeric_value<0").fetchone()[0]}
    (REPORT/"stage2_weight_config_summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
    lines=["# 权重配置索引","",f"配置数值记录：{summary['assignments']}",f"权重选择调用：{summary['selections']}",f"字段分组：{summary['groups']}",f"零值：{summary['zero_values']}",f"负值：{summary['negative_values']}","","数值仅代表当前包内可见的字面配置；运行时服务器下发或动态计算的权重仍需沿配置读取链继续追踪。"]
    (REPORT/"STAGE2_WEIGHT_CONFIG.md").write_text("\n".join(lines)+"\n",encoding="utf-8")
    db.close(); print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
