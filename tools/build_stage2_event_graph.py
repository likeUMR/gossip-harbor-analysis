"""Build a source-located event registration, dispatch, and callback graph."""
from __future__ import annotations
import bisect, collections, hashlib, json, re, sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
OUT = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"
FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(", re.M)
EVENT_CALL_RE = re.compile(r"\bEventDispatcher\s*\.\s*(AddListener|RemoveListener|DispatchEvent|PostEvent)\s*\(", re.M)

def stable_id(*parts): return hashlib.sha256("\0".join(map(str, parts)).encode()).hexdigest()
def mask_noncode(source):
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
def matching_paren(masked, pos):
    depth=0
    for i in range(pos,len(masked)):
        if masked[i]=="(": depth+=1
        elif masked[i]==")":
            depth-=1
            if depth==0: return i
    return None
def split_args(raw, masked):
    result=[]; start=0; depth=0
    for i,c in enumerate(masked):
        if c in "([{": depth+=1
        elif c in ")]}": depth-=1
        elif c=="," and depth==0:
            result.append(raw[start:i].strip()); start=i+1
    tail=raw[start:].strip()
    if tail or raw.strip(): result.append(tail)
    return result
def line_at(source,pos): return source.count("\n",0,pos)+1

def main():
    OUT.mkdir(parents=True,exist_ok=True); REPORT.mkdir(parents=True,exist_ok=True)
    path=OUT/"event_graph.sqlite3"
    if path.exists(): path.unlink()
    db=sqlite3.connect(path)
    db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE event_sites (
      id TEXT PRIMARY KEY, module TEXT NOT NULL, module_sha256 TEXT NOT NULL,
      source_path TEXT NOT NULL, line INTEGER NOT NULL, function_symbol TEXT,
      operation TEXT NOT NULL, event_expression TEXT NOT NULL, event_name TEXT,
      receiver_expression TEXT, callback_expression TEXT, callback_candidates_json TEXT NOT NULL,
      certainty TEXT NOT NULL, code_excerpt TEXT NOT NULL
    );
    CREATE TABLE unresolved (
      id INTEGER PRIMARY KEY, site_id TEXT NOT NULL, reason TEXT NOT NULL,
      expression TEXT NOT NULL
    );
    CREATE INDEX event_name ON event_sites(event_name);
    CREATE INDEX event_operation ON event_sites(operation);
    CREATE INDEX event_function ON event_sites(function_symbol);
    """)
    modules=json.loads((INDEX/"lua_modules.json").read_text(encoding="utf-8"))
    all_sources=[]; symbols=collections.defaultdict(list); states=collections.Counter()
    for module in modules:
        p=ROOT/module.get("source_path","")
        if not p.is_file(): states["missing"]+=1; continue
        try: source=p.read_text(encoding="utf-8")
        except (OSError,UnicodeError): states["unreadable"]+=1; continue
        states["available"]+=1; masked=mask_noncode(source)
        defs=[{"symbol":m.group(1),"offset":m.start(),"id":stable_id(module.get("sha256",""),m.group(1),line_at(source,m.start()))} for m in FUNCTION_RE.finditer(masked)]
        for d in defs:
            symbols[(module.get("sha256",""),d["symbol"])].append(d)
            if ":" in d["symbol"] or "." in d["symbol"]:
                method=re.split(r"[.:]",d["symbol"],1)[1]
                symbols[(module.get("sha256",""),method)].append(d)
        all_sources.append((module,source,masked,defs))
    counts=collections.Counter(); unresolved=collections.Counter()
    for module,source,masked,defs in all_sources:
        offsets=[d["offset"] for d in defs]; digest=module.get("sha256",""); source_path=module.get("source_path","")
        for m in EVENT_CALL_RE.finditer(masked):
            close=matching_paren(masked,m.end()-1)
            if close is None: continue
            args=split_args(source[m.end():close],masked[m.end():close])
            op=m.group(1); event=args[0].strip() if args else ""
            receiver=args[1].strip() if len(args)>1 else ""
            callback=args[2].strip() if len(args)>2 else ""
            pos=m.start(); idx=bisect.bisect_right(offsets,pos)-1; owner=defs[idx]["symbol"] if idx>=0 else None
            event_match=re.fullmatch(r"EEventType\.([A-Za-z_]\w*)",event)
            event_name=event_match.group(1) if event_match else None
            method_match=re.search(r"(?:[:.])([A-Za-z_]\w*)$",callback)
            candidates=[]
            if method_match:
                method=method_match.group(1)
                candidates=symbols.get((digest,method),[])
                if receiver=="self" and owner:
                    owner_name=re.split(r"[.:]",owner,1)[0]
                    candidates=[d for d in symbols.get((digest,owner_name+":"+method),[])]
            certainty="candidate_unique" if len(candidates)==1 else ("ambiguous" if candidates else "unresolved")
            excerpt=source[source.rfind("\n",0,pos)+1:source.find("\n",pos) if source.find("\n",pos)>=0 else len(source)].strip()[:600]
            site_id=stable_id(digest,pos,op,event,callback)
            db.execute("INSERT INTO event_sites VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",(site_id,module.get("name",""),digest,source_path,line_at(source,pos),owner,op,event,event_name,receiver,callback,json.dumps([d["id"] for d in candidates]),certainty,excerpt))
            counts[op]+=1
            if op in ("AddListener","RemoveListener") and not candidates:
                reason="回调表达式不是当前模块可唯一解析的方法，可能是动态对象、继承、匿名函数或跨语言桥接"
                db.execute("INSERT INTO unresolved(site_id,reason,expression) VALUES (?,?,?)",(site_id,reason,callback)); unresolved["callback"]+=1
            if not event_name:
                db.execute("INSERT INTO unresolved(site_id,reason,expression) VALUES (?,?,?)",(site_id,"事件表达式由字段或运行时配置计算，无法静态归一化",event)); unresolved["event_expression"]+=1
    db.commit()
    summary={"title":"阶段二事件传播图","modules":len(modules),"source_states":dict(states),"event_sites":db.execute("SELECT count(*) FROM event_sites").fetchone()[0],"by_operation":dict(counts),"event_names":db.execute("SELECT count(DISTINCT event_name) FROM event_sites WHERE event_name IS NOT NULL").fetchone()[0],"unresolved":dict(unresolved),"database":str(path.relative_to(ROOT)).replace("\\","/"),"limitations":["同名方法候选按模块和方法名归类，继承/混入/对象别名仍需运行时或类型信息确认。","事件注册顺序、对象生命周期和网络返回触发关系需要第三阶段结合场景验证。"]}
    (REPORT/"stage2_event_graph_summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    db.close(); print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
