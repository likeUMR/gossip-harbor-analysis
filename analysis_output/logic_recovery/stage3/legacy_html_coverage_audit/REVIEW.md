# 三份旧版 HTML 覆盖核验

核验对象：`gossip_harbor_terminal_simulation.html`、`gossip_harbor_piece_mechanics.html`、`gossip_harbor_order_mechanics.html`。三份文件已原样复制到 MkDocs 的 `docs/assets/reference-analysis/`，页面正文按章节建立映射，故动态表格、图表和嵌入数据不会因 Markdown 转换而丢失。

## 结论

三份旧版 HTML 的章节、表格和交互数据均可从站点对应页面打开。新增页面分别挂在“付费项目”“母体点击”“订单提交”下；现有源码拆页覆盖可证明的规则，历史页面补充理论计算和模拟输出。历史模拟的假设等级已在页面中明确，不把它们宣称为客户端实测。

## 章节数量

| 文件 | 章节 | 表格 | 归档页面 |
| --- | ---: | ---: | --- |
| 棋子机制 | 6 | 7 | `operations/generator/legacy_mechanics/index.md` |
| 订单机制 | 6 | 18 | `operations/orders/legacy_mechanics/index.md` |
| 终局模拟 | 12 | 5 | `operations/paid/terminal_simulation/index.md` |

逐知识点映射与哈希见同目录的 `coverage_matrix.json` 和 `hashes.json`。
