"""Independent read-only inventory of generator recovery evidence.

Writes work records only. Text matches and regex call candidates never confer
semantic review approval, dynamic reachability, or runtime confirmation.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml
from build_stage3_function_audit import source_functions

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'analysis_output/logic_recovery/stage3'
SITE = STAGE / 'mkdocs_site'
DOCS = SITE / 'docs'
GENERATOR = DOCS / 'operations/generator'
OUT = STAGE / 'generator_gate_audit'


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    OUT.mkdir(exist_ok=True)
    pages = {p.relative_to(DOCS).as_posix(): p.read_text(encoding='utf-8')
             for p in GENERATOR.rglob('*.md')}
    records = [r for r in source_functions()
               if r['module'] in {'ItemSpread', 'LuckyProduceModel'}]
    modules = json.loads((ROOT / 'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
    prototypes = json.loads((ROOT / 'analysis_data/logic_index/lua_functions.json').read_text(encoding='utf-8'))
    evidence = {}
    for record in records:
        p = ROOT / record['path']
        lines = p.read_text(encoding='utf-8').splitlines()
        body = '\n'.join(lines[record['line']-1:record['end_line']])
        name = record['identifier'].split(':')[-1].split('.')[-1]
        pattern = re.compile(r'(?<![\w_])' + re.escape(name) + r'(?![\w_])')
        record.update({
            'body_sha256': hashlib.sha256(body.encode()).hexdigest(),
            'document_name_matches': [rel for rel, text in pages.items() if pattern.search(text)],
            'conditions_and_returns': [
                {'line': i, 'text': line.strip()}
                for i, line in enumerate(lines[record['line']-1:record['end_line']], record['line'])
                if re.search(r'\b(if|elseif|for|while|return)\b', line)
            ],
            'instance_field_candidates': sorted(set(re.findall(r'\bself\.(m_\w+)', body))),
            'configuration_access_candidates': sorted(set(re.findall(r'\b(?:itemConfig|config)\.([A-Za-z_]\w*)', body))),
            'review_status': 'pending',
            'review_reason': 'No persistent per-branch approval with document and test evidence supplied.',
        })
        if record['module'] not in evidence:
            matches = [m for m in modules if m['name'].replace('/', '_').replace('.', '_').removesuffix('_lua')
                       == record['path'].split('/')[-1].removesuffix('.lua')]
            if record['module'] == 'LuckyProduceModel':
                matches = [m for m in modules if m['sha256'] == p.stem]
            evidence[record['module']] = {
                'source': record['path'], 'source_sha256': digest(p),
                'original_modules': [{'name': m['name'], 'sha256': m['sha256']} for m in matches],
                'prototypes': [f for f in prototypes if f['module_sha256'] in {m['sha256'] for m in matches}],
                'prototype_to_logic_unit_mapping_status': 'pending',
            }
    summary = {}
    for module in evidence:
        group = [r for r in records if r['module'] == module]
        summary[module] = {
            'named_functions': len(group),
            'with_name_match': sum(bool(r['document_name_matches']) for r in group),
            'without_name_match': [r['identifier'] for r in group if not r['document_name_matches']],
            'semantic_review_pending': len(group),
            'prototype_count': len(evidence[module]['prototypes']),
        }

    config = yaml.safe_load((SITE / 'mkdocs.yml').read_text(encoding='utf-8'))
    def leaves(node):
        if isinstance(node, str):
            yield node
        elif isinstance(node, list):
            for item in node:
                yield from leaves(item)
        elif isinstance(node, dict):
            for item in node.values():
                yield from leaves(item)
    nav_pages = set(leaves(config.get('nav', [])))
    graph = {}
    missing_links = []
    for rel, text in pages.items():
        links = []
        for href in re.findall(r'(?<!!)\[[^\]\n]*\]\(([^\s)]+)\)', text):
            parsed = urlsplit(href)
            if parsed.scheme or not parsed.path or parsed.path.startswith('/'):
                continue
            target = (DOCS / rel).parent / unquote(parsed.path)
            target = target.resolve()
            if target.suffix == '.md':
                if not target.exists():
                    missing_links.append({'page': rel, 'href': href})
                else:
                    links.append(target.relative_to(DOCS).as_posix())
        graph[rel] = links
    reached = set(nav_pages) & set(pages)
    pending = list(reached)
    while pending:
        for target in graph.get(pending.pop(), []):
            if target in pages and target not in reached:
                reached.add(target)
                pending.append(target)
    snapshot_path = DOCS / 'assets/generator-config-source-snapshot.json'
    configs = json.loads(snapshot_path.read_text(encoding='utf-8'))
    def rows(value):
        if isinstance(value, list):
            return len(value)
        if isinstance(value, dict):
            return sum(rows(x) for x in value.values())
        return 0
    findings = [
        ('G1', 'pending', '全库已有 3,415 模块指令结构校验；母体相关原型到逻辑单元的对应尚未核销，不能以命名函数数量替代。'),
        ('G2', 'failed', '审计原工具只选固定 12 模块。Super Lucky 已找到特效、音效、提示和 GeneratorBoost 消费者，尚未完成这些模块及其调用/监听闭包核销。'),
        ('G3', 'pending', '两核心模块的 114 个命名函数缺少持久化逐分支审核证据；名称匹配仅提供检索线索。'),
        ('G4', 'pending', '配置重载清机会池、活动结束清特殊状态、每日能量重置、普通次数保存等需逐字段映射与重登/边界验证。'),
        ('G5', 'pending', '现有配置族已有展示位置；尚无读取字段与全量记录双向核销。服务器阈值、开关及账号活动配置仍有未取得值。'),
        ('G6', 'pending', '自动检查相对 Markdown 链接与可达页面；尚无逻辑单元至具体段落的全量映射，四层深度与语义一致性仍需审核。'),
        ('G7', 'pending', '当前审计输入未提供全分支受控案例、原版逐事件/状态/存档差分及差异关闭记录。静态演示不是原版运行证据。'),
    ]
    if missing_links or set(pages)-reached:
        findings[5] = ('G6', 'failed', '发现缺失相对链接或不可达页面；详见 navigation。语义映射仍待完成。')
    payload = {
        'created_utc': datetime.now(timezone.utc).isoformat(),
        'version_scope': 'GH 3.98.10 recovered client snapshot; actual server configuration unconfirmed',
        'status': 'not_accepted',
        'scope_limitation': 'Two core modules inventoried, not complete operation call closure. Regex candidates are not AST/bytecode semantic proof.',
        'gates': [{'id': g, 'status': s, 'finding': f} for g, s, f in findings],
        'module_evidence': evidence, 'summary': summary, 'functions': records,
        'document_hashes': {rel: digest(DOCS / rel) for rel in pages},
        'navigation': {'generator_pages': len(pages), 'reachable_by_nav_or_markdown_links': len(reached),
                       'unreachable': sorted(set(pages)-reached), 'missing_links': missing_links,
                       'limitation': 'Relative Markdown targets only; heading anchors, absolute source URLs, UI and logic mapping are not certified.'},
        'configuration_snapshot': {'sha256': digest(snapshot_path),
                                   'table_record_counts': {k: rows(v) for k, v in configs.items()},
                                   'limitation': 'Snapshot counts only, not full configuration closure or active account values.'},
    }
    (OUT / 'audit.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    md = ['# 母体点击逐门禁审核', '',
          '结论：未通过验收。审核对应 GH_LOGIC_RECOVERY_PLAN.md 第 9.4 节。此文件属于工作记录，不进入领导网站。', '',
          '## 七项门禁', '', '| 门禁 | 结果 | 依据与缺口 |', '|---|---|---|']
    md += [f'| {g} | {s} | {f} |' for g, s, f in findings]
    md += ['', '## 核心模块的独立清单', '', '| 模块 | 命名函数 | 名称匹配 | 无名称匹配 | 语义核销待完成 | 原型数 |', '|---|---:|---:|---:|---:|---:|']
    for m, s in summary.items():
        md.append(f"| {m} | {s['named_functions']} | {s['with_name_match']} | {len(s['without_name_match'])} | {s['semantic_review_pending']} | {s['prototype_count']} |")
    md += ['', '名称匹配不是完成率；原型包含顶层与匿名函数，也不是命名函数数量。JSON 保留源码/文档哈希、每个函数的条件/返回/状态/配置候选以及原型清单。', '',
           '## 文档与配置机械检查', '', f'母体页面 {len(pages)} 个；导航或 Markdown 链接可达 {len(reached)} 个；缺失相对目标 {len(missing_links)} 个。仅证明目标存在，不证明解释充分或网页视觉正确。', '']
    for rel in sorted(set(pages)-reached):
        md.append(f'- 未纳入可达图：`{rel}`。')
    for item in missing_links:
        md.append(f"- 缺失链接：`{item['page']}` → `{item['href']}`。")
    md += ['', '## 逐函数待核销线索', '']
    for m, s in summary.items():
        md += [f'### {m}', '', '以下方法名尚未出现在母体文档；部分可能是工具或通用读取，需归属后决定解释深度：', '']
        md += [f'- `{name}`' for name in s['without_name_match']]
    md += ['', '## 修复及证据边界', '',
           '本轮修正 Super Lucky 的因果说明与错误的“后续池”说法，并明确 GeneratorBoost 追加物品是独立 Buff 分支。源码分类可以确认，但消费者闭包及原版回放仍需核销，不能把“没有额外机会”扩大为“没有任何后续活动效果”。', '',
           '后续优先：补齐配置装载/重载及重置生命周期；核销 GeneratorBoost、Disco、SmartReward、EnergyBoost 的依赖；逐分支绑定文档和案例；采集原版对照。']
    (OUT / 'REVIEW.md').write_text('\n'.join(md)+'\n', encoding='utf-8')
    print(json.dumps({'status': payload['status'], 'gates': {g:s for g,s,_ in findings},
                      'summary': summary, 'navigation': payload['navigation']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
