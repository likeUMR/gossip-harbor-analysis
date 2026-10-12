"""Independent whole-decoded-corpus event registration inventory, not proof of reachability."""
from pathlib import Path
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit'

def main():
    modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
    by_hash={}
    for row in modules:
        by_hash.setdefault(row['sha256'],[]).append({'name':row['name'],'path':row['path']})
    registrations=[]
    corpus=[]
    pattern=re.compile(r'EventDispatcher\.AddListener\(EEventType\.ItemSpread\s*,\s*self\s*,\s*self\.(\w+)\)')
    for path in sorted((ROOT/'analysis_data/logic_index/lua/decoded').glob('*/decompiled.lua')):
        source=path.read_text(encoding='utf-8')
        corpus.append({'sha256':path.parent.name,'readable_sha256':hashlib.sha256(source.encode()).hexdigest()})
        funcs=list(re.finditer(r'^function ([\w.:]+)\([^\n]*\)',source,re.M))
        for match in pattern.finditer(source):
            callback=match[1]
            providers=[]
            for i,fun in enumerate(funcs):
                if fun[1].split(':')[-1].split('.')[-1]!=callback:
                    continue
                body=source[fun.start():funcs[i+1].start() if i+1<len(funcs) else len(source)]
                providers.append({'identifier':fun[1],'line':source.count('\n',0,fun.start())+1,'body_sha256':hashlib.sha256(body.encode()).hexdigest(),'body':body})
            registrations.append({'module_sha256':path.parent.name,'source':path.relative_to(ROOT).as_posix(),
                'module_variants':by_hash.get(path.parent.name,[]),'registration_line':source.count('\n',0,match.start())+1,
                'callback':callback,'local_provider_candidates':providers,'status':'pending',
                'reason':'Registration is a candidate, not an active subscription; guard, callback dependencies, configs and downstream events require review.'})
    payload={'kind':'independent-registration-candidate-inventory','event':'EEventType.ItemSpread',
             'corpus_count':len(corpus),'corpus':corpus,'registrations':registrations,
             'limitations':'Exact direct syntax only. Variable event aliases, wrappers, inherited methods and board-local event registrations are not certified.'}
    OUT.mkdir(exist_ok=True)
    (OUT/'event_consumers.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
    lines=['# ItemSpread 下游监听独立清单','','这是工作记录。不是已审核完成列表，不作为领导页面。', '',
           f'扫描 {len(corpus)} 份按哈希归类的恢复源码，找到 {len(registrations)} 个直接注册点。仍需核销注册条件、消费者、配置、再派发事件以及动态包装注册。','',
           '| 模块 | 回调 | 注册行 | 本模块实现候选 | 状态 |','|---|---|---:|---|---|']
    for r in registrations:
        names=' / '.join(sorted({x['name'] for x in r['module_variants']})) or r['module_sha256']
        lines.append(f"| {names} | {r['callback']} | {r['registration_line']} | {', '.join(p['identifier'] for p in r['local_provider_candidates'])} | pending |")
    (OUT/'EVENT_CONSUMERS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print(json.dumps({'corpus':len(corpus),'registration_candidates':len(registrations),'all_pending':True}))

if __name__=='__main__': main()
