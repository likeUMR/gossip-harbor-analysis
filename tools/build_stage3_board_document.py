"""Generate a self-contained, searchable board-operation documentation site.

The generator keeps prose in the detailed specification while adding machine
audits: source function locations, configuration counts, and explicit status
labels. It intentionally produces plain HTML so it can be reviewed without a
package install; the same Markdown sections can later be moved into MkDocs.
"""
from __future__ import annotations

import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE3 = ROOT / "analysis_output" / "logic_recovery" / "stage3"
OUT = STAGE3 / "board_operations_document.html"


def source_functions(path: Path) -> list[dict[str, int | str]]:
    if not path.exists():
        return []
    result = []
    for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        match = re.search(r"function\s+([\w:.]+)", line)
        if match:
            result.append({"name": match.group(1), "line": number})
    return result


def markdown_to_html(text: str) -> str:
    # The report uses a deliberately small Markdown subset. Keeping this local
    # avoids changing the analysis environment merely to publish the report.
    lines = text.splitlines()
    out: list[str] = []
    in_code = False
    code: list[str] = []
    for line in lines:
        if line.strip().startswith("```"):
            if in_code:
                out.append("<pre><code>" + html.escape("\n".join(code)) + "</code></pre>")
                code = []
            in_code = not in_code
            continue
        if in_code:
            code.append(line)
            continue
        if not line.strip():
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", line)
        if m:
            level = len(m.group(1)) + 1
            anchor = re.sub(r"[^a-z0-9]+", "-", m.group(2).lower()).strip("-")
            out.append(f"<h{level} id='{anchor}'>{html.escape(m.group(2))}</h{level}>")
            continue
        if line.startswith("- "):
            if not out or not out[-1].startswith("<ul") and not out[-1].endswith("</li>"):
                out.append("<ul>")
            out.append("<li>" + html.escape(line[2:]) + "</li>")
            continue
        if out and out[-1].endswith("</li>") and not line.startswith("- "):
            out.append("</ul>")
        line = re.sub(r"`([^`]+)`", r"<code>\1</code>", html.escape(line))
        out.append("<p>" + line + "</p>")
    if out and out[-1].endswith("</li>"):
        out.append("</ul>")
    return "\n".join(out)


def config_audit() -> dict:
    def load(name: str) -> list:
        path = ROOT / "analysis_data" / "json" / name
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else []

    items = load("ItemModelConfig.json")
    orders = load("OrderItemConfig.json")
    spread = [x for x in items if any(k.startswith("Spread_") for k in x)]
    merged = [x for x in items if x.get("MergedType") not in (None, "", 0)]
    return {
        "ItemModelConfig": {"rows": len(items), "spread_rows": len(spread), "merge_rows": len(merged),
                             "bubble_rows": sum(float(x.get("BubbleChance", 0) or 0) > 0 for x in items)},
        "OrderItemConfig": {"rows": len(orders), "diff_min": min((x.get("DiffScore", 0) for x in orders), default=0),
                             "diff_max": max((x.get("DiffScore", 0) for x in orders), default=0)},
    }


def main() -> None:
    manifest = json.loads((STAGE3 / "stage3_board_operation_manifest.json").read_text(encoding="utf-8"))
    spec = (STAGE3 / "BOARD_OPERATIONS_DETAILED_SPEC.md").read_text(encoding="utf-8")
    functions = {}
    for module in manifest["modules"].values():
        path = Path(module["decompiled_source"])
        functions[path.name] = {"path": str(path), "functions": source_functions(path)}
    audit = config_audit()
    nav = "".join(f"<a href='#op-{x['id']}'>{html.escape(x['label'])}</a>" for x in manifest["operations"])
    operation_cards = []
    for op in manifest["operations"]:
        chain = "".join(f"<li><code>{html.escape(x)}</code></li>" for x in op["chain"])
        branches = "".join(f"<span class='tag'>{html.escape(x)}</span>" for x in op["branches"])
        operation_cards.append(f"""<details open id='op-{op['id']}'><summary>{html.escape(op['label'])} <small>{html.escape(op['entry'])}</small></summary>
        <div class='operation'><h3>执行顺序</h3><ol>{chain}</ol><h3>分支覆盖</h3><div>{branches}</div>
        <p class='status'>证据状态：{html.escape(op['evidence'])}</p></div></details>""")
    function_rows = []
    for file, info in functions.items():
        for fn in info["functions"]:
            function_rows.append(f"<tr><td>{html.escape(file)}</td><td><code>{html.escape(str(fn['name']))}</code></td><td>{fn['line']}</td></tr>")
    config_rows = "".join(f"<tr><th>{html.escape(k)}</th><td>{json.dumps(v, ensure_ascii=False)}</td></tr>" for k, v in audit.items())
    gaps = "".join(f"<li>{html.escape(x)}</li>" for x in manifest["acceptance_gaps"])
    body = markdown_to_html(spec)
    page = f"""<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width,initial-scale=1'><title>Gossip Harbor 棋盘逻辑文档</title>
<style>
:root{{--bg:#f6f7fb;--panel:#fff;--ink:#202532;--muted:#667085;--line:#d9dee8;--accent:#2457a6;--tag:#e8f0ff;--warn:#fff4d6}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.65 system-ui,"Microsoft YaHei",sans-serif}}header{{background:#182b49;color:#fff;padding:24px 32px;position:sticky;top:0;z-index:2}}header h1{{margin:0 0 5px;font-size:25px}}header p{{margin:0;color:#d8e4f7}}nav{{display:flex;gap:12px;flex-wrap:wrap;margin-top:14px}}nav a{{color:#d8e4f7;text-decoration:none;border-bottom:1px solid #7596c5}}main{{max-width:1250px;margin:24px auto;padding:0 22px}}section,details{{background:var(--panel);border:1px solid var(--line);border-radius:7px;margin:0 0 16px;box-shadow:0 1px 2px #172b4d0c}}section{{padding:20px}}summary{{cursor:pointer;padding:16px 20px;font-weight:700;font-size:18px}}summary small{{color:var(--muted);font-weight:400;margin-left:10px}}.operation{{padding:0 20px 20px}}h2{{margin-top:0;color:var(--accent)}}h3{{margin-bottom:6px}}code,pre{{font-family:ui-monospace,SFMono-Regular,Consolas,monospace}}code{{background:#f0f2f5;padding:1px 4px;border-radius:3px}}pre{{background:#18212f;color:#e7edf7;padding:14px;overflow:auto;border-radius:5px}}.tag{{display:inline-block;background:var(--tag);color:#2457a6;border-radius:12px;padding:2px 9px;margin:3px;font-size:13px}}.status{{background:var(--warn);padding:9px 12px;border-left:3px solid #d99b00}}table{{border-collapse:collapse;width:100%;font-size:14px}}th,td{{border-bottom:1px solid var(--line);padding:7px 9px;text-align:left;vertical-align:top}}th{{background:#f4f6fa}}.search{{width:100%;padding:10px;border:1px solid var(--line);border-radius:5px;margin:8px 0 15px}}.count{{color:var(--muted)}}
</style></head><body><header><h1>Gossip Harbor 3.98.10：棋盘逻辑文档</h1><p>从玩家操作到函数、配表、状态变化和验收证据的可展开分析</p><nav>{nav}<a href='#audit'>覆盖审计</a><a href='#spec'>详细规格</a></nav></header><main>
<section><h2>阅读方法</h2><p>先看操作卡片中的有序调用链，再展开详细规格中的子流程。页面把静态反编译证据、配置统计和运行时待确认项分开，避免把推断当成事实。</p></section>
{''.join(operation_cards)}
<section id='audit'><h2>覆盖审计</h2><p class='count'>模块：{len(manifest['modules'])}；操作入口：{len(manifest['operations'])}；已索引函数：{len(function_rows)}；配置表：{len(audit)}</p><table><thead><tr><th>配置表</th><th>统计</th></tr></thead><tbody>{config_rows}</tbody></table><h3>明确的剩余验证项</h3><ul>{gaps}</ul></section>
<section><h2>源函数索引</h2><input class='search' placeholder='过滤文件或函数名' oninput="filterRows(this.value)"><table id='functions'><thead><tr><th>文件</th><th>函数</th><th>行</th></tr></thead><tbody>{''.join(function_rows)}</tbody></table></section>
<section id='spec'><h2>详细规格正文</h2>{body}</section>
</main><script>function filterRows(q){{q=q.toLowerCase();document.querySelectorAll('#functions tbody tr').forEach(r=>r.style.display=r.innerText.toLowerCase().includes(q)?'':'none')}}</script></body></html>"""
    OUT.write_text(page, encoding="utf-8")
    print(f"wrote {OUT} ({len(page)} bytes, {len(function_rows)} indexed functions)")


if __name__ == "__main__":
    main()
