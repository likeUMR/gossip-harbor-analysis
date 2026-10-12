# Git 历史版本覆盖审计

本页说明如何确认当前 MkDocs 没有丢失历史分析。审计脚本为仓库中的 `tools/audit_historical_mkdocs_coverage.py`，它读取所有 Git 提交中的 MkDocs Markdown 和历史 HTML，抽取标题集合并生成机器可复核的 JSON 报告。

## 审计结论

历史提交中的 44 个标题差异经过逐项复核，分为三类：

1. **页面重组但内容保留**：旧的单页已经拆为四级页面。例如“特殊棋子与吞噬”现在位于“升级与剪刀”和“棋子吞噬”；“奖励结算”现在拆为价格、活动奖励、亲密度礼物、Buff、即时/延迟奖励等页面。
2. **标题改写但规则保留**：例如旧的“手动点击：确定性的方形环扫描”现在是“一次性落点的具体算法”中的“手动路径：`FindEmptyPositionInSpreadOrder`”；旧的 `Fixed`、`SmartItem`、`ChestCustomItem` 页面现在分别位于普通产出下的对应目录。
3. **历史治理内容原先被移除**：配置索引、证据分级、三类操作验收矩阵和当前状态已补回[参考 PDF 覆盖核验](reference_pdf_coverage.md)与[首页](index.md)，不重新建立旧的“配置与验证”顶层栏目。

## 历史文件保留策略

三个旧版交互 HTML 已原样放在[历史分析附件](assets/reference-analysis/terminal-simulation.html)及其同目录中；旧 Markdown 的内容已经合并到当前机制页，重组时没有丢弃算法、公式、案例、字段或证据边界。若标题只在旧提交出现，审计报告会列为复核候选，而不是静默忽略。

## 重新运行

在仓库根目录运行：

```text
python tools/audit_historical_mkdocs_coverage.py
```

报告输出到 `analysis_output/logic_recovery/stage3/legacy_html_coverage_audit/`。该目录中的 JSON 保存提交、历史文件、缺失标题候选和解释；判断“缺失”前必须结合页面重组映射和正文证据复核。
