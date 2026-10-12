"""Index network/API calls, request names, callback shapes, and nearby state writes."""
from __future__ import annotations
import collections, hashlib, json, re, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]; INDEX=ROOT/"analysis_data"/"logic_index"; OUT=INDEX/"stage2"; REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
FUNC_RE=re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(",re.M)
API_RE=re.compile(r"\b(ApiMessage|Api|Network|GM\.[A-Za-z_][\w.]*)\s*[:.]([A-Za-z_]\w*)\s*\(",re.M)
def sid(*p): return hashlib.sha256("\0".join(map(str,p)).encode()).hexdigest()
def mask(s):
    out=list(s); i=0; n=len(s); q=None
    while i<n:
        if q:
            if s[i]=="\\": out[i]=" "; i+=1; out[i]=" " if i<n else out[i]
            elif s[i]==q: out[i]=" "; i+=1; q=None
            else:
                if s[i] not in "\r\n": out[i]=" "
                i+=1
        elif s.startswith("--[[",i):
            j=s.find("]]",i+4); j=n if j<0 else j+2
            for k in range(i,j):
                if out[k] not in "\r\n": out[k]=" "
            i=j
        elif s.startswith("--",i):
            j=s.find("\n",i+2); j=n if j<0 else j
            for k in range(i,j): out[k]=" "
            i=j
        elif s[i] in "'\"": q=s[i]; out[i]=" "; i+=1
        else: i+=1
    return "".join(out)
def close_paren(m,pos):
    d=0
    for i in range(pos,len(m)):
        if m[i]=="(": d+=1
        elif m[i]==")":
            d-=1
            if d==0:return i
def split(raw,m):
    a=[]; st=0; d=0
    for i,c in enumerate(m):
        if c in "([{": d+=1
        elif c in ")]}": d-=1
        elif c=="," and d==0:a.append(raw[st:i].strip()); st=i+1
    t=raw[st:].strip()
    if t or raw.strip():a.append(t)
    return a
def main():
    p=OUT/"network_calls.sqlite3"
    if p.exists():p.unlink()
    db=sqlite3.connect(p); db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE calls(id TEXT PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,line INTEGER NOT NULL,function_symbol TEXT,
      receiver TEXT NOT NULL,method TEXT NOT NULL,request_expression TEXT NOT NULL,request_name TEXT,callback_shape TEXT NOT NULL,
      arguments_json TEXT NOT NULL,code_excerpt TEXT NOT NULL);
    CREATE INDEX network_method ON calls(method); CREATE INDEX network_request ON calls(request_name);""")
    mods=json.loads((INDEX/"lua_modules.json").read_text(encoding="utf-8")); counts=collections.Counter(); states=collections.Counter()
    for mod in mods:
        path=ROOT/mod.get("source_path","")
        if not path.is_file():states["missing"]+=1;continue
        try:s=path.read_text(encoding="utf-8")
        except (OSError,UnicodeError):states["unreadable"]+=1;continue
        states["available"]+=1; m=mask(s); defs=[(x.start(),x.group(1)) for x in FUNC_RE.finditer(m)]
        for x in API_RE.finditer(m):
            end=close_paren(m,x.end()-1)
            if end is None:continue
            raw=s[x.end():end]; args=split(raw,m[x.end():end]); req=""
            if args and re.fullmatch(r'["\'][^"\']+["\']',args[0].strip()):req=args[0].strip()[1:-1]
            tail=m[x.end():min(len(m),x.end()+250)]
            shape="inline_function" if re.search(r"\bfunction\b",tail) else ("callback_expression" if len(args)>=2 else "none")
            owner=None
            for pos,sym in defs:
                if pos<=x.start():owner=sym
                else:break
            line=s.count("\n",0,x.start())+1; line_end=s.find("\n",x.start()); line_end=len(s) if line_end<0 else line_end
            excerpt=s[s.rfind("\n",0,x.start())+1:line_end].strip()[:600]
            ident=sid(mod.get("sha256",""),x.start(),x.group(1),x.group(2))
            db.execute("INSERT OR IGNORE INTO calls VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",(ident,mod.get("name",""),mod.get("source_path",""),line,owner,x.group(1),x.group(2),s[x.start():min(len(s),x.start()+240)].split("\n",1)[0].strip(),req,shape,json.dumps(args,ensure_ascii=False),excerpt))
            counts[(x.group(1),x.group(2),shape)]+=1
    db.commit()
    result={"title":"阶段二网络/API调用索引","modules":len(mods),"source_states":dict(states),"calls":db.execute("SELECT count(*) FROM calls").fetchone()[0],"request_names":db.execute("SELECT count(DISTINCT request_name) FROM calls WHERE request_name!=''").fetchone()[0],"by_receiver":dict(db.execute("SELECT receiver,count(*) FROM calls GROUP BY receiver")),"by_callback_shape":dict(db.execute("SELECT callback_shape,count(*) FROM calls GROUP BY callback_shape")),"database":str(p.relative_to(ROOT)).replace("\\","/"),"limitations":["请求回调参数可能不是最后一个参数，当前保留完整参数数组和原始行。","服务端响应到模型写入的语义需要沿回调函数和事件图继续展开。"]}
    (REPORT/"stage2_network_calls_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8"); db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
