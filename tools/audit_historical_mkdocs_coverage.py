"""Audit current MkDocs content against every documentation snapshot in Git history.

The audit is intentionally conservative: a historical heading is considered covered
only when the normalized heading is present in the current docs or in an archived
reference HTML. The report is a discovery aid, not a claim that matching words prove
the same semantics.
"""

from __future__ import annotations

import argparse
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path
from collections import defaultdict
from pathlib import PurePosixPath


HEADING_RE = re.compile(r"(?im)^\s{0,3}#{1,6}\s+(.+?)\s*$|<h[1-6][^>]*>(.*?)</h[1-6]>")
TAG_RE = re.compile(r"<[^>]+>")
ENTITY_RE = re.compile(r"&(?:nbsp|amp|lt|gt|quot|#39);", re.I)
DOC_PREFIXES = (
    "analysis_output/logic_recovery/stage3/mkdocs_site/docs/",
    "analysis_output/gossip_harbor_",
)

# Historical headings changed as flat pages were reorganized into the four-level
# operation tree. These are reviewed content mappings, not fuzzy matches.
REVIEWED_RENAMES = {
    "三个根操作": "docs/index.md:四个顶层主题",
    "基础消耗和倍增比率": "operations/generator/energy/boost/detail.md",
    "棋盘事件的具体写入顺序": "operations/generator/events/board/detail.md",
    "资源事件的具体监听链": "operations/generator/events/resource/detail.md",
    "副作用的具体字段": "operations/generator/events/side_effects/detail.md",
    "活动、日志和 ui 副作用": "operations/generator/events/side_effects/index.md",
    "cd、加速和恢复结算": "operations/generator/lifecycle/cooldown/detail.md",
    "次数扣除、变换和销毁顺序": "operations/generator/lifecycle/count/detail.md",
    "读取与周期重装": "operations/generator/lucky/chance/load.md",
    "阈值队列生成": "operations/generator/lucky/free/generate.md",
    "super/free 产出类型": "operations/generator/lucky/items/type.md",
    "chestcustomitem": "operations/generator/output/chest/index.md",
    "chestcustomitem 的具体选择": "operations/generator/output/chest/detail.md",
    "fixed": "operations/generator/output/fixed/index.md",
    "fixed 的具体选择": "operations/generator/output/fixed/detail.md",
    "smartitem": "operations/generator/output/smart/index.md",
    "smartitem 的具体选择": "operations/generator/output/smart/detail.md",
    "1. 手动点击：确定性的方形环扫描": "operations/generator/position/disposable/detail.md",
    "2. 自动产出：随机空位与自动循环": "operations/generator/position/disposable/detail.md",
    "3. findrandomposition 的每一次抽样": "operations/generator/position/disposable/detail.md",
    "4. 满盘、缓存与最终写入": "operations/generator/position/disposable/detail.md",
    "自动产出与缓存的具体条件": "operations/generator/position/auto/detail.md",
    "特殊棋子与吞噬": "operations/merge/special/index.md",
    "订单完成、补位与同步": "operations/orders/finish/index.md",
    "奖励结算": "operations/orders/rewards/index.md",
    "lucky、disco 与产出改写": "operations/generator/overrides/activity/index.md",
    "活动改写的具体顺序": "operations/generator/overrides/activity/detail.md",
    "链升级和 fishnet 具体算法": "operations/generator/overrides/boost/detail.md",
    "缺能量后先显示什么窗口": "operations/generator/energy/consume/detail.md",
    "generatorboost 任务进度与增益升级": "operations/generator/events/side_effects/detail.md",
    "落子通知后的 generatorboost 追加产出": "operations/generator/events/side_effects/detail.md",
    "剩余池恢复的具体例子": "operations/generator/lifecycle/count/detail.md",
    "次数与剩余权重池怎样跨重载保留": "operations/generator/lifecycle/count/detail.md",
    "buff切换何时真正清机会池": "operations/generator/lucky/chance/load.md",
    "两种切换的具体例子": "operations/generator/lucky/chance/load.md",
    "接口切换例子与真实升级路线的区别": "operations/generator/lucky/chance/load.md",
    "点击关闭母体后，界面如何响应": "operations/generator/state/closed/detail.md",
    "点击开启中的母体后，界面如何响应": "operations/generator/state/opening/detail.md",
    "存档如何恢复当前母体": "operations/generator/state/model/detail.md",
    "交付收尾": "operations/orders/finish/index.md",
    "配置索引": "reference_pdf_coverage.md:配置索引",
    "证据分级": "reference_pdf_coverage.md:证据分级",
    "三类操作验收矩阵": "docs/index.md:历史验收基线",
    "当前状态": "reference_pdf_coverage.md:仍需区分的证据等级",
}


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True, encoding="utf-8").strip()


def git_bytes(*args: str) -> bytes:
    return subprocess.check_output(["git", *args])


def norm(value: str) -> str:
    value = TAG_RE.sub(" ", value)
    value = ENTITY_RE.sub(" ", value)
    value = re.sub(r"[`*_~]", "", value)
    value = re.sub(r"\$\{[^}]+\}|\$\w+", "", value)
    value = re.sub(r"\s+", " ", value).strip().casefold()
    return value


def headings(text: str) -> set[str]:
    found: set[str] = set()
    for match in HEADING_RE.finditer(text):
        value = match.group(1) or match.group(2) or ""
        value = norm(value)
        if value:
            found.add(value)
    return found


def files_at(commit: str) -> list[str]:
    paths = git("ls-tree", "-r", "--name-only", commit).splitlines()
    return [
        p for p in paths
        if p.startswith(DOC_PREFIXES) and PurePosixPath(p).suffix.casefold() in {".md", ".html"}
    ]


def snapshot(commit: str) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    available = files_at(commit)
    pathspecs: list[str] = []
    if any(p.startswith("analysis_output/logic_recovery/stage3/mkdocs_site/docs/") for p in available):
        pathspecs.append("analysis_output/logic_recovery/stage3/mkdocs_site/docs")
    pathspecs.extend(p for p in available if p.startswith("analysis_output/gossip_harbor_"))
    if not pathspecs:
        return result
    archive = git_bytes("archive", "--format=tar", commit, "--", *pathspecs)
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as tar:
        for member in tar:
            path = member.name
            if not member.isfile() or not path.startswith(DOC_PREFIXES):
                continue
            if PurePosixPath(path).suffix.casefold() not in {".md", ".html"}:
                continue
            extracted = tar.extractfile(member)
            if extracted is None:
                continue
            result[path] = headings(extracted.read().decode("utf-8", errors="replace"))
    return result


def working_tree_snapshot() -> dict[str, set[str]]:
    """Read the current checkout so the audit can run before its report is committed."""
    result: dict[str, set[str]] = {}
    root = Path.cwd()
    docs = root / "analysis_output/logic_recovery/stage3/mkdocs_site/docs"
    if docs.is_dir():
        candidates = list(docs.rglob("*.md")) + list(docs.rglob("*.html"))
    else:
        candidates = []
    candidates += list((root / "analysis_output").glob("gossip_harbor_*.html"))
    for path in candidates:
        relative = path.relative_to(root).as_posix()
        result[relative] = headings(path.read_text(encoding="utf-8", errors="replace"))
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="analysis_output/logic_recovery/stage3/legacy_html_coverage_audit/historical_coverage_report.json")
    parser.add_argument("--markdown", default="analysis_output/logic_recovery/stage3/legacy_html_coverage_audit/HISTORICAL_COVERAGE.md")
    args = parser.parse_args()

    commits = git("log", "--all", "--format=%H", "--reverse").splitlines()
    if not commits:
        raise SystemExit("No Git history found")
    current = working_tree_snapshot()
    current_headings = set().union(*current.values()) if current else set()
    history: list[dict[str, object]] = []
    missing_by_heading: defaultdict[str, list[str]] = defaultdict(list)
    for commit in commits:
        files = snapshot(commit)
        missing: dict[str, list[str]] = {}
        for path, values in files.items():
            absent = sorted(value for value in values if value not in current_headings)
            if absent:
                missing[path] = absent
                for value in absent:
                    missing_by_heading[value].append(path)
        subject = git("show", "-s", "--format=%s", commit)
        history.append({"commit": commit, "subject": subject, "files": len(files), "missing_headings": missing})

    report = {
        "current_commit": "working-tree-at-audit",
        "commit_count": len(commits),
        "current_document_files": len(current),
        "current_unique_headings": len(current_headings),
        "historical_commits": history,
        "unique_missing_headings": {k: sorted(set(v)) for k, v in sorted(missing_by_heading.items())},
        "reviewed_renames": {k: REVIEWED_RENAMES[k] for k in sorted(missing_by_heading) if k in REVIEWED_RENAMES},
        "unresolved_headings": {k: sorted(set(v)) for k, v in sorted(missing_by_heading.items()) if k not in REVIEWED_RENAMES},
        "interpretation": "A missing heading is a review candidate. It is not proof of semantic loss; the reviewer must map or explicitly retire it."
    }
    with open(args.output, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    unresolved = {k: v for k, v in missing_by_heading.items() if k not in REVIEWED_RENAMES}
    lines = ["# Git 历史版本覆盖核验", "", f"审计提交数：{len(commits)}；当前文档来源：工作树。", "", "脚本按每个 Git 提交读取 MkDocs 文档和历史 HTML，抽取 Markdown/HTML 标题并与当前工作树标题集合比较。标题缺失只代表需要人工复核，不自动宣称语义丢失。", "", "## 结果摘要", "", f"- 当前文档文件：{len(current)}", f"- 当前唯一标题：{len(current_headings)}", f"- 历史提交：{len(commits)}", f"- 历史标题差异：{len(missing_by_heading)}", f"- 已复核的页面重组/改名：{len(missing_by_heading) - len(unresolved)}", f"- 未解决标题：{len(unresolved)}", ""]
    if unresolved:
        lines += ["## 未解决标题", "", "| 历史标题 | 出现于历史文件 |", "| --- | --- |"]
        for value, paths in sorted(unresolved.items()):
            lines.append(f"| `{value}` | {len(set(paths))} 个历史文件 |")
    else:
        lines += ["## 结论", "", "所有历史标题差异均已映射到当前页面或历史治理基线；没有未解决标题。"]
    lines += ["", "## 已复核的页面重组", "", "| 历史标题 | 当前归档位置 |", "| --- | --- |"]
    for value, target in sorted(REVIEWED_RENAMES.items()):
        if value in missing_by_heading:
            lines.append(f"| `{value}` | `{target}` |")
    with open(args.markdown, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
