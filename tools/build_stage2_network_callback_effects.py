"""Extract effects inside anonymous Lua callbacks passed to API/network calls."""
from __future__ import annotations
import collections, json, re, sqlite3
from pathlib import Path
from tree_sitter import Parser, Language
import tree_sitter_lua

ROOT=Path(__file__).resolve().parents[1]; STAGE2=ROOT/"analysis_data"/"logic_index"/"stage2"; REPORT=ROOT/"analysis_output"/"logic_recovery"/"stage2"
EFFECT_RE=[
 ("event_dispatch",re.compile(r"\bEventDispatcher\s*\.\s*(DispatchEvent|PostEvent)\s*\(")),
 ("state_or_db_write",re.compile(r"\b(?:Set|Save|Remove|Clear|Sync|Update)\s*\(")),
 ("ui_effect",re.compile(r"\bGM\s*\.\s*UIManager\s*[:.]")),
 ("network_nested_call",re.compile(r"\b(?:ApiMessage|Api|Network)\s*[:.]")),
]
def char_offset(source, byte_offset):
    encoded=source.encode("utf-8")
    return len(encoded[:byte_offset].decode("utf-8","ignore"))
def line_at_byte(source, byte_offset):
    return source.count("\n",0,char_offset(source,byte_offset))+1

def main():
    out=STAGE2/"network_callback_effects.sqlite3"
    if out.exists(): out.unlink()
    db=sqlite3.connect(out); db.executescript("""PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;
    CREATE TABLE callbacks(id INTEGER PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,request_line INTEGER NOT NULL,
      request_expression TEXT NOT NULL,callback_start_line INTEGER NOT NULL,callback_end_line INTEGER NOT NULL,
      callback_text TEXT NOT NULL,callback_shape TEXT NOT NULL);
    CREATE TABLE effects(id INTEGER PRIMARY KEY,callback_id INTEGER NOT NULL,effect_kind TEXT NOT NULL,line INTEGER NOT NULL,expression TEXT NOT NULL);
    CREATE TABLE unresolved(id INTEGER PRIMARY KEY,module TEXT NOT NULL,source_path TEXT NOT NULL,line INTEGER NOT NULL,reason TEXT NOT NULL,expression TEXT NOT NULL);
    CREATE INDEX cb_request ON callbacks(request_line); CREATE INDEX effect_kind ON effects(effect_kind);""")
    net=sqlite3.connect(STAGE2/"network_calls.sqlite3")
    requests=collections.defaultdict(list)
    for row in net.execute("SELECT module,source_path,line,receiver,method,request_expression FROM calls WHERE callback_shape='inline_function'"):
        requests[(row[0],row[1],row[2],row[3],row[4])].append(row)
    parser=Parser(); parser.language=Language(tree_sitter_lua.language())
    modules=json.loads((ROOT/"analysis_data/logic_index/lua_modules.json").read_text(encoding="utf-8"))
    by_path={m.get("source_path"):m for m in modules}; counts=collections.Counter(); parsed=0
    for source_path,module in by_path.items():
        path=ROOT/source_path
        if not path.is_file(): continue
        try: source=path.read_text(encoding="utf-8")
        except (OSError,UnicodeError): continue
        tree=parser.parse(source.encode("utf-8")); parsed+=1
        def walk(node):
            if node.type=="function_call":
                name=node.child_by_field_name("name")
                if name is not None:
                    text=name.text.decode("utf-8","replace")
                    if "." in text:
                        receiver,method=text.rsplit(".",1)
                        line=line_at_byte(source,name.start_byte)
                        key=(module.get("name",""),source_path,line,receiver,method)
                        rows=requests.get(key,[])
                        if rows:
                            funcs=[]
                            for child in node.children:
                                if child.type=="arguments":
                                    funcs.extend(x for x in child.children if x.type=="function_definition")
                            if not funcs:
                                for row in rows:
                                    db.execute("INSERT INTO unresolved(module,source_path,line,reason,expression) VALUES (?,?,?,?,?)",(module.get("name",""),source_path,line,"网络调用记录为内联回调但 AST 未找到函数体",row[5]))
                            for fn in funcs:
                                fn_start=char_offset(source,fn.start_byte); fn_end=char_offset(source,fn.end_byte); name_start=char_offset(source,name.start_byte); name_end=char_offset(source,name.end_byte)
                                text_body=source[fn_start:fn_end]
                                cbid=db.execute("INSERT INTO callbacks(module,source_path,request_line,request_expression,callback_start_line,callback_end_line,callback_text,callback_shape) VALUES (?,?,?,?,?,?,?,?)",(module.get("name",""),source_path,line,source[name_start:min(len(source),name_end+240)].split("\n",1)[0],line_at_byte(source,fn.start_byte),line_at_byte(source,fn.end_byte),text_body[:12000],"anonymous")).lastrowid
                                for kind,pattern in EFFECT_RE:
                                    for match in pattern.finditer(text_body):
                                        effect_line=source.count("\n",0,fn_start+match.start())+1
                                        db.execute("INSERT INTO effects(callback_id,effect_kind,line,expression) VALUES (?,?,?,?)",(cbid,kind,effect_line,text_body[match.start():match.start()+180].split("\n",1)[0].strip()))
                                        counts[kind]+=1
                                counts["callbacks"]+=1
            for child in node.children: walk(child)
        walk(tree.root_node)
    db.commit()
    result={"title":"阶段二网络回调副作用索引","parsed_modules":parsed,"callbacks":db.execute("SELECT count(*) FROM callbacks").fetchone()[0],"effects":db.execute("SELECT count(*) FROM effects").fetchone()[0],"unresolved":db.execute("SELECT count(*) FROM unresolved").fetchone()[0],"by_effect":dict(db.execute("SELECT effect_kind,count(*) FROM effects GROUP BY effect_kind")),"database":str(out.relative_to(ROOT)).replace("\\","/"),"limitations":["只对 AST 能识别的匿名回调建立体内副作用证据；命名回调和动态函数值需沿 Lua 调用图继续追踪。","效果分类依据源码调用名，具体条件分支和运行时执行次数仍需场景验证。"]}
    (REPORT/"stage2_network_callback_effects_summary.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8"); net.close(); db.close(); print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=="__main__": main()
