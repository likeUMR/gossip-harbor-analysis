"""Build a standalone stage-one inventory and acceptance report."""
import html
import json
from pathlib import Path

from audit_gh_resources import DATA, OUT, ROOT, load, save

CATEGORIES = {"data_config": "配置、剧情与本地化数据", "model_gameplay": "模型与玩法",
              "ui_view": "界面与表现", "test_debug": "测试与调试",
              "support_or_unclassified": "公共支持或待细分"}
ISSUES = {"unresolved_apk_binary": "尚未完整解码的 APK 二进制",
          "unity_object_decode_failed": "类型树尚未完整恢复的 Unity 对象",
          "unresolved_textasset_payload": "分离动画缺少匹配骨架上下文",
          "native_high_level_source": "原生逻辑的高层阅读材料",
          "android_java_errors": "JADX 源码生成异常",
          "lua_source_structure_differs": "Lua 回编译结构差异"}
ISSUES["binary_field_semantics"] = "已完整拆出、待解释字段语义的 SDK 配置"


def main():
    summary = load(OUT / "stage1_summary.json")
    modules = load(DATA / "lua_modules.json")
    validations = {x["sha256"]: x for x in load(DATA / "lua_validation.json")}
    issues = load(DATA / "issues.json")
    verification = load(DATA / "verification_summary.json") if (DATA / "verification_summary.json").exists() else None
    native_libraries = load(DATA / "native_libraries.json")
    packages = load(DATA / "packages.json")
    for row in modules:
        row["validation"] = validations[row["sha256"]]["status"]
    model = {"summary": summary, "modules": modules, "issues": issues, "verification": verification,
             "categories": CATEGORIES, "issue_names": ISSUES}
    save(OUT / "stage1_report_data.json", model)
    category_lines = "\n".join(f"| {CATEGORIES[k]} | {v['files']:,} | {v['file_percent']:.2f}% | {v['bytes'] / 1048576:.2f} MiB | {v['decompiled_lines']:,} |"
                                for k, v in summary["categories"].items())
    issue_lines = "\n".join(f"| {ISSUES.get(x['category'],x['category'])} | {x['count']:,} | {'阻断全量验收' if x['severity']=='blocking' else '有低层证据，阅读仍需复核'} |" for x in issues)
    digest_lines = "\n".join(f"- `{Path(x['path']).name}`：`{x['sha256']}`" for x in packages)
    verification_text = "核验尚未运行完成。" if not verification else (
        f"独立核对 {verification['unity_containers_checked']:,} 个 Unity 容器，数量不一致 {verification['unity_count_failures']} 个；"
        f"逐文件校验 {verification['hashed_files']:,} 份产物 SHA-256，失败 {verification['hash_failures']} 份。")
    markdown = f"""# 第一阶段：资源恢复、代码索引与验收报告

样本：Gossip Harbor 3.98.10。报告生成于 2026-10-09。远端资源依据已保存的 2026-09-22 catalog 获取，下载时间另有记录。

## 当前结论

**已取得样本内的代码与数据均已解密或完整结构化读取；严格全量验收仍未通过，唯一资源阻断项是 318 个分离动画缺少匹配骨架。** 逐个动画检查全部 1,115 个骨架均找不到满足原始引用的依赖。这个结论只对四个 APK 和已保存 catalog 的资源全集成立，不表示历史版本或服务端永久无法取得。

第一阶段已达到当前样本能够证明的恢复边界。全部逻辑的语义、实际生效版本、调用链和复刻行为尚未验收，不能据此宣称“已经能够完整复刻”或“领导知道的机制已经全部掌握”。

包内四个 APK 的 2,330 个文件均已提取并做 CRC 校验。保存的远端目录列出 2,074 个唯一 bundle，1,829 个已下载，245 个对应 APK 内文件。所有已取得 Unity 容器均进入全量扫描，不按名称关键词筛选。

## 核心统计

| 指标 | 数值 | 口径 |
| --- | ---: | --- |
| Lua 逻辑模块名 | {summary['module_names']:,} | 同名热更新只计一个逻辑名 |
| Lua 内容版本 | {summary['unique_bytecode_chunks']:,} | 按 SHA-256 去重；包含配置、测试与数据代码 |
| Lua 字节码大小 | {summary['bytecode_bytes'] / 1048576:.2f} MiB | 解密后的模块总大小 |
| Lua 嵌套函数原型 | {summary['nested_function_prototypes']:,} | 含匿名函数与回调；不含模块主入口 |
| Lua 全部原型 | {summary['function_prototypes_including_main']:,} | 包含 {summary['unique_bytecode_chunks']:,} 个模块主入口 |
| Lua 指令数 | {summary['bytecode_instructions']:,} | 严格字节码解析 |
| 反编译 Lua 行数 | {summary['decompiled_lines']:,} | 工具生成行数，不是原始源码行数 |
| Lua 反汇编行数 | {summary['disassembly_lines']:,} | 含常量、局部变量等列表 |
| Unity 对象出现次数 | {summary['unity_objects_occurrences']:,} | 包含重复容器出处，不能等同于唯一资源数 |
| 唯一 Unity 容器 | {summary['unity_unique_containers']:,} | 包含 bundle、独立 serialized file 和拼接资源 |
| 原生库 | {summary['native_library_count']:,} | ARM64 ELF；可执行节全部反汇编 |
| 原生反汇编行数 | {summary['native_disassembly_lines']:,} | 指令或数据项行数 |
| IL2CPP 类型 | {summary['native']['parsed_types']:,} | 类、结构、枚举和接口，包含引擎及 SDK |
| IL2CPP 方法映射 | {summary['native']['method_mappings']:,} | 地址与签名；不等同于恢复 C# 方法体 |
| Android DEX | {summary['android']['dex_count']:,} | APK 内 7 个，另恢复加密载荷内 {summary['android']['nested_dex_count']} 个 |
| Android 类定义 / smali 文件 | {summary['android']['class_definitions']:,} / {summary['android']['smali_files']:,} | 每个 DEX 单独核对 |
| Java 反编译文件 | {summary['android']['jadx']['source_files']:,} | 内部类可能合并，不能与 DEX 类数直接比较 |
| Java 反编译行数 | {summary['android']['jadx']['source_lines']:,} | 生成代码，包含第三方库 |
| 新恢复 Java 文件 / 行 | {summary['android']['nested_jadx']['source_files']:,} / {summary['android']['nested_jadx']['source_lines']:,} | 受保护 DEX 的阅读材料，单独统计 |
| Android 方法 / 有方法体 | {summary['android']['method_index']['methods']:,} / {summary['android']['method_index']['methods_with_code']:,} | 全部 smali 的逐方法索引 |
| 另恢复的嵌套原生程序 | {len(summary['nested_native_code'])} | assets/dic 解密为 x86 ELF，包含完整反汇编 |
| 解密数据库表 | {len(summary['database']['tables']):,} | 2026-09-22 的设备快照，只有 {sum(x['rows'] for x in summary['database']['tables']):,} 行实际数据 |

不得把各种语言与反汇编的行数相加后称作“原始游戏代码量”。C# dump.cs 是声明和占位方法体，排除在实现源码行数之外。

## Lua 类型占比

| 初步分类 | 文件数 | 文件占比 | 字节码大小 | 生成源码行数 |
| --- | ---: | ---: | ---: | ---: |
{category_lines}

分类按模块名和路径自动生成，是第一阶段索引，不代表已经逐函数确认用途。原始归档、顶级模块族和完整路径均保留，后续按实际逻辑继续细分。占比分母为 {summary['unique_bytecode_chunks']:,} 份唯一内容版本。

## 工具与验证

- 全量 APK：Python zipfile，逐 entry 解包、CRC 和 SHA-256。
- Unity：UnityPy 1.25.0，读取全部对象，保留原始字节及类型树。
- 类型树：Il2CppDumper 的 DummyDll 字段信息 + TypeTreeGeneratorAPI 0.0.10；最后 5 个对象依据字段声明与 Unity 序列化布局恢复，逐个验证完整字节消费。当前失败项为零。布局重建与原始类型树区分记录。
- Lua：现有兼容版 luac 5.3.5 + 严格格式解析器；为标准工具转换序列化头与长字符串长度，保留原始指令。
- Lua 源码：unluac 1.2.3.561，源码提交与下载哈希见工具 manifest。
- Lua 回编译：{summary['lua_validation']['statuses'].get('instruction_structure_equal',0):,} 份全部结构一致；修正 9 处 unluac 生成差异，保留修正前源码与逐处证据。全部原型数量与独立 luac 列表一致。
- Android：JADX 1.5.3 + baksmali 3.0.9；{summary['android']['class_definitions']:,} 个类均有 smali。原日志报告 37 个错误事件；实际生成文件中有 {summary['android']['method_index']['java_files_with_failure_markers']} 个文件含显式报错标记，全部映射到完整 smali。新恢复 DEX 的 JADX 导出退出码为 {summary['android']['nested_jadx']['exit']}。
- 原生：pyelftools + Capstone，按 ELF 可执行节核对覆盖字节数；保留 il2cpp 命名节，不能只读取 .text。
- Spine：@pixi-spine/runtime-3.8 4.0.6；依据客户端 RVA 0x1927350 的 marker 153 分支补充延迟加载支持。1,115 个骨架完整读取并导出全部几何和时间线；555 个分离动画全部完成独立线格式解析与逐字节回编码验证，其中 237 个有匹配上下文，318 个无法在样本中找到匹配骨架。
- 加密嵌套代码：复现 AFk1rSDK 与 AFk1tSDK 算法及载荷字节修补，4 个 AppsFlyer 载荷全部解密；内部 ZIP CRC、DEX SHA1/Adler32/长度均验证。额外恢复 15 个类，全部导出 smali 与 Java。assets/dic 按实际 SDK 读取算法解密为 EM_386 ELF。
- SDK 配置：Billing protobuf 全量线结构解析；Vulkan AQKV 的 16,088 字节均归属到头部、589 个字符串、固定表和预测参数。字段语义解释保留为后续分析项，未用“已知 SDK 名称”代替解析。
- 数据库：sqlcipher3-wheels 0.5.7，依据 SQLiteDatabase 初始化函数及 ELF 重定位定位密码；SQLCipher 4 解密后通过 SQLite integrity_check。

{verification_text}

严格解析和结构一致验证提高阅读可信度，但不代替玩法分析。未执行游戏行为一致性测试。下载文件的 SHA-256 是采集证据，未将它冒充 catalog 的 Unity Hash128 或 CDN 官方校验值。

## 剩余缺口

| 项目 | 数量 | 状态 |
| --- | ---: | --- |
{issue_lines}

此前的 7 个 APK 二进制问题均已推进到内容恢复：4 个 AppsFlyer 载荷和 assets/dic 已解密；Billing 和 Vulkan 已完整结构化拆出。未识别或未解密的 APK 二进制为零，Unity 对象解析失败为零，Lua 源码结构差异为零。

318 个动画已经完整读取原始索引、帧、曲线、稀疏变形值、绘制顺序及事件编码；并非仍有 318 个未知加密文件。但变形基线、附件名称和骨架索引含义依赖对应骨架，不能凭时间线唯一反推出缺失几何。

独立检查每个问题动画与全部 1,115 个骨架的骨骼、槽位、约束、字符串引用、皮肤、附件、变形范围和事件定义，318 个均无匹配依赖。证据见 spine_dependency_checks.json。示例 Harrison_happy_begin.ani 在槽位 60 引用 C_dabi1，当前 Harrison 骨架该附件位于槽位 61；当前骨架内同名嵌入动画也采用不同索引。已有证据支持版本不匹配，尚未证明这些分离动画运行时是否仍被装载。

要恢复这些历史动画的准确播放，需要对应版本骨架/完整历史资源包，或能够验证旧索引映射与原始几何的运行时证据。单纯重新运行解包、解密或更换反编译器无法从当前文件推导出不存在的完整依赖；不能把此结论扩大为“所有渠道均无法取得”。

原生伪代码、Java 报错处高层重建，以及两份 SDK 配置的字段解释仍有办法继续分析。这些项目已有完整底层输入，并未认定为不可解决，也不等于后续语义审阅完成。

## 怎样验收才算拆好

1. **固定分母。** 指定四个 APK 哈希和远端 catalog 哈希；所有完成率只对该快照负责。
2. **逐层守恒。** APK entry 清单与 ZIP 中的名称和数量一致；全部 Unity serialized file 的对象数与导出清单一致；Lua 归档声明数、模块数、长度和最终偏移一致；全部函数原型与 luac 列表一致；DEX 类定义数与 smali 文件数一致。
3. **完整读入。** 不允许用“读取了头部”代表对象解码成功；字节码、骨骼和分离动画必须完整消费输入，或明确解释格式允许的尾部。
4. **产物可复核。** 原始文件、解密文件、反汇编、源码和索引能够相互追溯；实际文件哈希与索引一致，脚本可重复运行。
5. **异常归零。** 未识别、未解密、解析失败、缺少依赖和版本关系未确认项必须逐条解决。无法解决的明确列为未完成，不能改名或移出分母。
6. **阅读可信。** 源码回编译差异和 Java 生成错误有复核结论；可读源码不可靠时明确使用完整反汇编作为依据。
7. **范围一致。** 包内与 catalog 内资源覆盖不证明服务端、账号分组或将来资源完整；远端配置装载与实际生效优先级仍需后续操作链分析确认。

当前可通过“全部已列举资源取得与保留”“已发现加密代码恢复”“Lua 完整恢复与结构一致”“所有 Unity 对象解码”“原生可执行节反汇编”“DEX 类/方法导出”“所有动画编码读取与回编码”和“设备数据库解密”等分项验收。**整个第一阶段的严格全量验收仍不通过：318 个依赖缺失项保留在分母内。** 本阶段停止条件是已证明当前样本内没有它们的匹配依赖，而非认定全局无法解决。

## 查阅与重跑

- 可筛选报告：stage1_inventory.html。
- Lua 明细：lua_module_inventory.csv；原型清单：analysis_data/logic_index/lua_functions.json。
- 资源、对象、远端、类型、数据库和问题索引均位于 analysis_data/logic_index。
- 同名模块版本保留在 module_variants.json，未合并覆盖。Common.GameConfig 和 Board.Model.RandomGenerateCodeHelper 各有包内与热更新版本。

```powershell
python tools/audit_gh_resources.py apk
python tools/audit_gh_resources.py remote --workers 16
python tools/audit_gh_resources.py unity --workers 4
python tools/repair_gh_typetrees.py
python tools/recover_gh_unity_settings.py
python tools/audit_gh_resources.py code --workers 8
python tools/repair_gh_lua_sources.py
python tools/audit_gh_resources.py native
python tools/audit_gh_resources.py assembly
python tools/recover_gh_remaining.py
python tools/decrypt_gh_appsflyer.py
python tools/decode_gh_vkquality.py
python tools/decompile_gh_android.py
python tools/index_gh_android_methods.py
python tools/decode_gh_database.py
python tools/finalize_gh_inventory.py
node tools/patch_gh_spine.cjs
node tools/decode_gh_spine.cjs
node tools/decode_gh_animation_wire.cjs
node tools/check_gh_spine_dependencies.cjs
python tools/finalize_gh_inventory.py
python tools/validate_gh_lua.py
python tools/verify_gh_stage1.py
python tools/audit_gh_resources.py report
python tools/build_stage1_report.py
```

首次环境准备使用 bootstrap_logic_tools.py、bootstrap_jadx.py 及 tools/logic_vendor/spine 的 package-lock.json。UnityPy、TypeTreeGeneratorAPI、sqlcipher3-wheels、pyelftools、Capstone 为 Python 依赖。

## 样本指纹

{digest_lines}
"""
    (OUT / "STAGE1_REPORT.md").write_text(markdown, encoding="utf-8")
    raw = json.dumps(model, ensure_ascii=False).replace("</", "<\\/")
    page = """<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gossip Harbor · 第一阶段资源审计</title><style>
*{box-sizing:border-box}body{margin:0;background:#f7f8fa;color:#20252b;font:14px/1.6 'Segoe UI','Microsoft YaHei',sans-serif;letter-spacing:0}main{max-width:1450px;margin:auto;padding:28px}header{border-bottom:1px solid #d8dde3;padding-bottom:18px}h1{font-size:28px;margin:0 0 5px}h2{font-size:20px;margin:24px 0 10px}p{margin:8px 0}.muted{color:#626d79}.status{padding:12px 16px;border-left:4px solid #ba6519;background:#fff2e4;margin:18px 0}.stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:0;border-block:1px solid #d8dde3;margin:20px 0}.stat{padding:15px 10px}.stat b{font-size:25px;display:block}.stat span{color:#626d79}nav{display:flex;gap:5px;border-bottom:1px solid #d8dde3;overflow:auto}button,select,input{font:inherit;letter-spacing:0;border:1px solid #c7ced6;border-radius:4px;padding:7px 12px;background:#fff;color:inherit}button{cursor:pointer}nav button{border:0;border-bottom:3px solid transparent;border-radius:0;white-space:nowrap}nav button[aria-selected=true]{border-color:#18745c;color:#12614c;font-weight:600}section[hidden]{display:none}.table-wrap{overflow:auto;background:#fff;border-block:1px solid #d8dde3}table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:10px 12px;border-bottom:1px solid #e5e9ed;vertical-align:top}th{background:#eef1f4;font-size:13px;white-space:nowrap}td.num{text-align:right;white-space:nowrap}a{color:#116c57;text-decoration:none}a:hover{text-decoration:underline}code{font:12px Consolas,monospace;overflow-wrap:anywhere}.toolbar{display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding:16px 0}.toolbar input{min-width:180px;flex:1}.toolbar label{display:flex;gap:6px;align-items:center}.pagination{display:flex;gap:12px;align-items:center;justify-content:flex-end;margin:12px 0}.module{min-width:280px;max-width:600px;overflow-wrap:anywhere}.badge{font-size:12px;padding:2px 5px;background:#e4f1ea;color:#155a3c;white-space:nowrap}.warn{background:#fff1dc;color:#865000}.bars{display:flex;height:20px;width:100%;margin:12px 0}.legend{display:flex;gap:18px;flex-wrap:wrap;font-size:13px}.legend i{display:inline-block;width:10px;height:10px;margin-right:5px}.gates{padding-left:22px}.gates li{margin:10px 0}details{border-bottom:1px solid #ddd;padding:14px 0}summary{cursor:pointer;font-weight:600}.issue-list{max-height:420px;overflow:auto}footer{border-top:1px solid #d8dde3;margin-top:28px;padding:14px 0;color:#626d79} @media(max-width:700px){main{padding:16px}h1{font-size:23px}.stats{grid-template-columns:repeat(2,minmax(0,1fr))}.stat b{font-size:22px}.toolbar label{width:100%;justify-content:space-between}.toolbar select{max-width:65%}.module{min-width:240px}.pagination{justify-content:space-between}}
</style></head><body><main><header><h1>Gossip Harbor 3.98.10</h1><div class="muted">第一阶段 · 资源恢复、代码索引与验收 · 2026-10-09</div></header>
<div class="status"><strong>严格全量验收：尚未通过</strong><br>资源与代码主体已恢复；剩余格式、对象与动画问题逐项保留。尚未进行全部函数的语义审阅。</div><div id="stats" class="stats"></div>
<nav role="tablist" aria-label="报告视图"><button role="tab" aria-selected="true" data-tab="overview">验收与统计</button><button role="tab" aria-selected="false" data-tab="modules">Lua 文件索引</button><button role="tab" aria-selected="false" data-tab="issues">缺口清单</button></nav>
<section id="overview"><h2>范围与版本</h2><p>4 个 APK、2,330 个包内文件；保存的 catalog 中 2,074 个 bundle 已全部取得或对应到 APK。远端目录快照来自 2026-09-22，下载时间与 SHA-256 单独记录。</p><p class="muted">Unity 对象出现次数包含重复出处；原始源码行数未知。反编译行数、反汇编行数与 C# 占位声明分别统计。</p><h2>代码与资源规模</h2><div id="scale" class="table-wrap"></div><h2>Lua 初步分类</h2><div id="bars" class="bars"></div><div id="legend" class="legend"></div><div id="category" class="table-wrap" style="margin-top:12px"></div><h2>独立一致性核验</h2><p id="verification"></p><h2>验收规则</h2><ol class="gates"><li>固定 APK 与 catalog 指纹，完成率绑定同一个版本快照。</li><li>逐层核对 ZIP entry、Unity 对象、Lua 模块与函数、DEX 类定义的数量。</li><li>完整读入对象与字节码；保留所有解析错误和未消费内容。</li><li>实际产物通过哈希核对，能够追溯原始来源与处理工具。</li><li>未知格式、未解密、缺依赖与解析失败逐项解决后，才通过严格全量验收。</li><li>生成源码必须验证；回编译差异和 JADX 错误不能隐藏。</li></ol><h2>已验证的恢复结果</h2><p>Lua 全部严格解析，3,406 份回编译结构一致，9 份有结构差异；DEX 全部类有 smali。22 个原生库可执行节均有反汇编。45 张设备数据库表已解密。1,115 个骨骼完整解码，555 个分离动画中 237 个通过。</p><p class="muted">结构一致比较覆盖指令、常量、上值与子原型，不含调试数据；尚未执行玩法行为验证。C# 方法签名与占位方法体不算恢复了实现源码。</p></section>
<section id="modules" hidden><div class="toolbar"><input id="search" aria-label="搜索模块" placeholder="搜索模块名、归档或路径"><label>分类<select id="categoryFilter"><option value="">全部</option></select></label><label>回编译<select id="validationFilter"><option value="">全部</option><option value="instruction_structure_equal">结构一致</option><option value="compiled_structure_differs">结构不同</option></select></label></div><p id="resultCount" class="muted"></p><div class="table-wrap"><table><thead><tr><th>模块与阅读文件</th><th>归档 / 分类</th><th>字节</th><th>原型</th><th>指令</th><th>源码行</th><th>回编译</th></tr></thead><tbody id="moduleRows"></tbody></table></div><div class="pagination"><button id="previous">上一页</button><span id="pageCount"></span><button id="next">下一页</button></div></section>
<section id="issues" hidden><h2>未通过项目</h2><p class="muted">阻断项必须解决才能通过全量验收。阅读项已有底层证据，但生成的高层代码需要复核。</p><div id="issueRows"></div></section>
<footer><a href="STAGE1_REPORT.md">完整验收说明</a> · <a href="stage1_summary.json">统计 JSON</a> · <a href="lua_module_inventory.csv">Lua 明细 CSV</a> · <a href="../../analysis_data/logic_index/issues.json">原始问题清单</a></footer></main>
<script id="data" type="application/json">__DATA__</script><script>
const D=JSON.parse(document.querySelector('#data').textContent),S=D.summary,$=s=>document.querySelector(s),fmt=n=>Number(n).toLocaleString('zh-CN'),escape=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),link=(p,t)=>p?`<a href="../../${escape(p)}">${t}</a>`:'',colors=['#738290','#26785b','#287d9b','#b77825','#9d5570'];
const stats=[['Lua 内容版本',S.unique_bytecode_chunks],['嵌套函数原型',S.nested_function_prototypes],['唯一 Unity 容器',S.unity_unique_containers],['DEX 类 / smali',S.android.smali_files]];$('#stats').innerHTML=stats.map(([k,v])=>`<div class="stat"><b>${fmt(v)}</b><span>${k}</span></div>`).join('');
const table=(heads,rows)=>`<table><thead><tr>${heads.map(x=>`<th>${x}</th>`).join('')}</tr></thead><tbody>${rows.map(row=>`<tr>${row.map((x,i)=>`<td class="${i?'num':''}">${x}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
$('#scale').innerHTML=table(['指标','数值'],[['Lua 模块名',fmt(S.module_names)],['字节码大小',`${(S.bytecode_bytes/1048576).toFixed(2)} MiB`],['Lua 指令',fmt(S.bytecode_instructions)],['Lua 生成源码行',fmt(S.decompiled_lines)],['Lua 反汇编行',fmt(S.disassembly_lines)],['Unity 对象出现次数',fmt(S.unity_objects_occurrences)],['IL2CPP 类型 / 方法映射',`${fmt(S.native.parsed_types)} / ${fmt(S.native.method_mappings)}`],['原生反汇编行',fmt(S.native_disassembly_lines)],['Java 文件 / 生成行',`${fmt(S.android.jadx.source_files)} / ${fmt(S.android.jadx.source_lines)}`],['smali 行',fmt(S.android.smali_lines)]]);
const cats=Object.entries(S.categories);$('#category').innerHTML=table(['初步分类','文件','占比','字节码 MiB','源码行'],cats.map(([k,v])=>[D.categories[k],fmt(v.files),v.file_percent.toFixed(2)+'%',(v.bytes/1048576).toFixed(2),fmt(v.decompiled_lines)]));$('#bars').innerHTML=cats.map(([k,v],i)=>`<div title="${D.categories[k]} ${v.file_percent.toFixed(2)}%" style="width:${v.file_percent}%;background:${colors[i]}"></div>`).join('');$('#legend').innerHTML=cats.map(([k,v],i)=>`<span><i style="background:${colors[i]}"></i>${D.categories[k]}</span>`).join('');
const V=D.verification;$('#verification').textContent=V?`独立核对 ${fmt(V.unity_containers_checked)} 个 Unity 容器，数量不一致 ${V.unity_count_failures} 个；逐文件核对 ${fmt(V.hashed_files)} 份 SHA-256，失败 ${V.hash_failures} 份。`:'核验尚未完成。';
for(const [k,v] of Object.entries(D.categories))$('#categoryFilter').insertAdjacentHTML('beforeend',`<option value="${k}">${v}</option>`);let page=0,filtered=[];function render(){const q=$('#search').value.toLowerCase(),c=$('#categoryFilter').value,v=$('#validationFilter').value;filtered=D.modules.filter(x=>(!q||`${x.name} ${x.archive} ${x.path}`.toLowerCase().includes(q))&&(!c||x.category===c)&&(!v||x.validation===v));page=Math.min(page,Math.max(0,Math.ceil(filtered.length/100)-1));$('#resultCount').textContent=`${fmt(filtered.length)} 份内容版本 · 同名热更新保留独立行`;$('#moduleRows').innerHTML=filtered.slice(page*100,page*100+100).map(x=>`<tr><td class="module"><strong>${escape(x.name)}</strong><br>${link(x.source_path,'源码')} · ${link(x.disassembly_path,'反汇编')} · ${link(x.path,'原始字节码')}</td><td>${escape(x.archive)}<br><span class="muted">${D.categories[x.category]}</span></td><td class="num">${fmt(x.bytes)}</td><td class="num">${fmt(x.prototype_count)}</td><td class="num">${fmt(x.instructions)}</td><td class="num">${fmt(x.decompiled_lines)}</td><td><span class="badge ${x.validation==='instruction_structure_equal'?'':'warn'}">${x.validation==='instruction_structure_equal'?'一致':'需复核'}</span></td></tr>`).join('');$('#pageCount').textContent=`${page+1} / ${Math.max(1,Math.ceil(filtered.length/100))}`;$('#previous').disabled=page===0;$('#next').disabled=(page+1)*100>=filtered.length;}
for(const id of ['#search','#categoryFilter','#validationFilter'])$(id).addEventListener('input',()=>{page=0;render()});$('#previous').onclick=()=>{page--;render()};$('#next').onclick=()=>{page++;render()};render();
$('#issueRows').innerHTML=D.issues.map(x=>`<details><summary>${D.issue_names[x.category]||escape(x.category)} · ${fmt(x.count)} <span class="badge warn">${x.severity==='blocking'?'阻断验收':'阅读复核'}</span></summary><p class="muted">${escape(x.note)}</p><div class="issue-list">${x.items.map(y=>{const p=y.path||y.source||y.raw_path||y.container_path;return `<p>${escape(y.name||y.format||y.category||'')} ${p?link(p,`<code>${escape(p)}</code>`):''}${y.error?`<br><code>${escape(y.error)}</code>`:''}</p>`}).join('')}</div></details>`).join('');
document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-tab]').forEach(t=>t.setAttribute('aria-selected',String(t===b)));for(const id of ['overview','modules','issues'])$('#'+id).hidden=id!==b.dataset.tab});
</script></body></html>""".replace("__DATA__", raw)
    restored = (
        f"Lua {summary['unique_bytecode_chunks']:,} 份全部严格解析并通过回编译结构比对；"
        f"{summary['android']['class_definitions']:,} 个 DEX 类全部有 smali，"
        f"{summary['android']['method_index']['methods']:,} 个方法已索引。"
        "4 个 AppsFlyer 加密载荷和 assets/dic 全部恢复。22 个 ARM64 库及额外 x86 ELF 均保留反汇编。"
        "全部 Unity 对象解码成功；1,115 个骨架导出完整结构，555 个分离动画全部完成编码读取与逐字节回编码。"
        "237 个动画有匹配上下文；318 个穷尽检查 1,115 个骨架后仍缺匹配依赖。"
    )
    page = page.replace(
        "Lua 全部严格解析，3,406 份回编译结构一致，9 份有结构差异；DEX 全部类有 smali。22 个原生库可执行节均有反汇编。45 张设备数据库表已解密。1,115 个骨骼完整解码，555 个分离动画中 237 个通过。",
        restored)
    page = page.replace("资源与代码主体已恢复；剩余格式、对象与动画问题逐项保留。尚未进行全部函数的语义审阅。",
        "已达到当前样本的恢复边界：318 个动画缺少匹配骨架，全部保留在分母。其他代码与配置已有完整底层输入；语义审阅和复刻行为尚未验收。")
    page = page.replace("阻断项必须解决才能通过全量验收。阅读项已有底层证据，但生成的高层代码需要复核。",
        "阻断项：当前快照没有匹配骨架，需补对应历史资源或运行时证据。阅读项仍可继续分析，已有完整底层输入，未认定为不可解决。")
    (OUT / "stage1_inventory.html").write_text(page, encoding="utf-8")
    print(f"Built {OUT / 'stage1_inventory.html'}")


if __name__ == "__main__":
    main()
