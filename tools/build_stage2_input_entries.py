"""Index likely player input entry points and their source locations."""
from __future__ import annotations
import collections, hashlib, json, re, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
INDEX=ROOT/"analysis_data"/"logic_index"
OUT=INDEX/"stage2"
REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
FUNCTION_RE=re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(",re.M)
INPUT_NAME_RE=re.compile(r"(?:^|[:.])(OnClicked|OnClick|OnPressed|OnReleased|OnLuaPointerDown|OnLuaPointerUp|OnLuaDrag|OnDrag|OnDrop|OnLongPress|OnDoubleClick|OnTouch|OnSubmit|OnSelected|OnToggle|OnSliderChanged)$")
INLINE_RE=re.compile(r"\b(OnClickedFunc|OnClick|onClick|clickCallback|callback|OnLuaPointerDown|OnLuaPointerUp|OnLuaDrag)\s*=\s*function\s*\(",re.M)
REG_RE=re.compile(r"\b(AddClickListener|SetClickCallback|SetOnClick|RegisterClick|AddListener|SetCallback)\s*\(",re.M)

def stable_id(*parts): return hashlib.sha256("\0".join(map(str,parts)).encode()).hexdigest()
def mask(source):
    out=list(source); i=0; n=len(source); state="code"
    while i<n:
        if state=="code":
            if source.startswith("--[[",i):
                j=source.find("]]",i+4); j=n if j<0 else j+2
                for k in range(i,j):
                    if out[k] not in "\r\n": out[k]=" "
                i=j; continue
            if source.startswith("--",i):
                j=source.find("\n",i+2); j=n if j<0 else j
                for k in range(i,j): out[k]=" "
                i=j; continue
            if source[i] in "'\"": state=source[i]; out[i]=" "; i+=1; continue
            i+=1; continue
        if source[i]=="\\": out[i]=" "; i+=1; out[i]=" " if i<n else out[i]
        elif source[i]==state: out[i]=" "; i+=1; state="code"
        else:
            if source[i] not in "\r\n": out[i]=" "
            i+=1
    return "".join(out)
def line_at(s,p): return s.count("\n",0,p)+1

def main():
    OUT.mkdir(parents=True,exist_ok=True); REPORT.mkdir(parents=True,exist_ok=True)
    path=OUT/"input_entries.sqlite3"
    if path.exists(): path.unlink()
    db=sqlite3.connect(path)
    db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE entries(id TEXT PRIMARY KEY,module TEXT NOT NULL,module_sha256 TEXT NOT NULL,
      source_path TEXT NOT NULL,line INTEGER NOT NULL,function_symbol TEXT,entry_kind TEXT NOT NULL,
      expression TEXT NOT NULL,code_excerpt TEXT NOT NULL);
    CREATE INDEX entries_kind ON entries(entry_kind);
    CREATE INDEX entries_function ON entries(function_symbol);""")
    modules=json.loads((INDEX/"lua_modules.json").read_text(encoding="utf-8"))
    counts=collections.Counter(); states=collections.Counter(); emitted=set()
    for mod in modules:
        p=ROOT/mod.get("source_path","")
        if not p.is_file(): states["missing"]+=1; continue
        try: src=p.read_text(encoding="utf-8")
        except (OSError,UnicodeError): states["unreadable"]+=1; continue
        states["available"]+=1; m=mask(src)
        defs=[(x.start(),x.group(1)) for x in FUNCTION_RE.finditer(m)]
        patterns=[]
        for x in FUNCTION_RE.finditer(m):
            if INPUT_NAME_RE.search(x.group(1)): patterns.append((x.start(),x.group(1),"named_input_method"))
        for x in INLINE_RE.finditer(m): patterns.append((x.start(),x.group(1),"inline_input_callback"))
        for x in REG_RE.finditer(m): patterns.append((x.start(),x.group(1),"input_registration_candidate"))
        for pos,expr,kind in patterns:
            owner=None
            for start,sym in defs:
                if start<=pos: owner=sym
                else: break
            end=src.find("\n",pos); end=len(src) if end<0 else end
            text=src[src.rfind("\n",0,pos)+1:end].strip()[:600]
            ident=stable_id(mod.get("sha256",""),pos,kind,expr)
            if ident in emitted: continue
            emitted.add(ident)
            db.execute("INSERT INTO entries VALUES (?,?,?,?,?,?,?,?,?)",(ident,mod.get("name",""),mod.get("sha256",""),mod.get("source_path",""),line_at(src,pos),owner,kind,expr,text))
            counts[kind]+=1
    db.commit()
    result={"title":"阶段二玩家输入入口索引","modules":len(modules),"source_states":dict(states),"entries":db.execute("SELECT count(*) FROM entries").fetchone()[0],"by_kind":dict(counts),"database":str(path.relative_to(ROOT)).replace("\\","/"),"limitations":["命名输入方法和注册 API 是候选入口，需结合 prefab 绑定、Unity EventSystem 或 C# 调用确认实际可达性。"]}
    (REPORT/"stage2_input_entries_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
