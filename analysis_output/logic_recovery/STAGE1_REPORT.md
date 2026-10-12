# 第一阶段：资源恢复、代码索引与验收报告

样本：Gossip Harbor 3.98.10。报告生成于 2026-10-09。远端资源依据已保存的 2026-09-22 catalog 获取，下载时间另有记录。

## 当前结论

**已取得样本内的代码与数据均已解密或完整结构化读取；严格全量验收仍未通过，唯一资源阻断项是 318 个分离动画缺少匹配骨架。** 逐个动画检查全部 1,115 个骨架均找不到满足原始引用的依赖。这个结论只对四个 APK 和已保存 catalog 的资源全集成立，不表示历史版本或服务端永久无法取得。

第一阶段已达到当前样本能够证明的恢复边界。全部逻辑的语义、实际生效版本、调用链和复刻行为尚未验收，不能据此宣称“已经能够完整复刻”或“领导知道的机制已经全部掌握”。

包内四个 APK 的 2,330 个文件均已提取并做 CRC 校验。保存的远端目录列出 2,074 个唯一 bundle，1,829 个已下载，245 个对应 APK 内文件。所有已取得 Unity 容器均进入全量扫描，不按名称关键词筛选。

## 核心统计

| 指标 | 数值 | 口径 |
| --- | ---: | --- |
| Lua 逻辑模块名 | 3,413 | 同名热更新只计一个逻辑名 |
| Lua 内容版本 | 3,415 | 按 SHA-256 去重；包含配置、测试与数据代码 |
| Lua 字节码大小 | 89.62 MiB | 解密后的模块总大小 |
| Lua 嵌套函数原型 | 29,857 | 含匿名函数与回调；不含模块主入口 |
| Lua 全部原型 | 33,272 | 包含 3,415 个模块主入口 |
| Lua 指令数 | 4,286,950 | 严格字节码解析 |
| 反编译 Lua 行数 | 2,396,819 | 工具生成行数，不是原始源码行数 |
| Lua 反汇编行数 | 6,024,167 | 含常量、局部变量等列表 |
| Unity 对象出现次数 | 713,647 | 包含重复容器出处，不能等同于唯一资源数 |
| 唯一 Unity 容器 | 2,210 | 包含 bundle、独立 serialized file 和拼接资源 |
| 原生库 | 22 | ARM64 ELF；可执行节全部反汇编 |
| 原生反汇编行数 | 11,517,337 | 指令或数据项行数 |
| IL2CPP 类型 | 10,387 | 类、结构、枚举和接口，包含引擎及 SDK |
| IL2CPP 方法映射 | 78,516 | 地址与签名；不等同于恢复 C# 方法体 |
| Android DEX | 11 | APK 内 7 个，另恢复加密载荷内 4 个 |
| Android 类定义 / smali 文件 | 43,784 / 43,784 | 每个 DEX 单独核对 |
| Java 反编译文件 | 26,004 | 内部类可能合并，不能与 DEX 类数直接比较 |
| Java 反编译行数 | 2,671,635 | 生成代码，包含第三方库 |
| 新恢复 Java 文件 / 行 | 12 / 2,758 | 受保护 DEX 的阅读材料，单独统计 |
| Android 方法 / 有方法体 | 254,729 / 238,445 | 全部 smali 的逐方法索引 |
| 另恢复的嵌套原生程序 | 1 | assets/dic 解密为 x86 ELF，包含完整反汇编 |
| 解密数据库表 | 45 | 2026-09-22 的设备快照，只有 3 行实际数据 |

不得把各种语言与反汇编的行数相加后称作“原始游戏代码量”。C# dump.cs 是声明和占位方法体，排除在实现源码行数之外。

## Lua 类型占比

| 初步分类 | 文件数 | 文件占比 | 字节码大小 | 生成源码行数 |
| --- | ---: | ---: | ---: | ---: |
| 配置、剧情与本地化数据 | 1,217 | 35.64% | 74.53 MiB | 2,063,917 |
| 公共支持或待细分 | 256 | 7.50% | 0.92 MiB | 21,000 |
| 模型与玩法 | 608 | 17.80% | 6.37 MiB | 148,492 |
| 界面与表现 | 1,217 | 35.64% | 6.70 MiB | 137,454 |
| 测试与调试 | 117 | 3.43% | 1.10 MiB | 25,956 |

分类按模块名和路径自动生成，是第一阶段索引，不代表已经逐函数确认用途。原始归档、顶级模块族和完整路径均保留，后续按实际逻辑继续细分。占比分母为 3,415 份唯一内容版本。

## 工具与验证

- 全量 APK：Python zipfile，逐 entry 解包、CRC 和 SHA-256。
- Unity：UnityPy 1.25.0，读取全部对象，保留原始字节及类型树。
- 类型树：Il2CppDumper 的 DummyDll 字段信息 + TypeTreeGeneratorAPI 0.0.10；最后 5 个对象依据字段声明与 Unity 序列化布局恢复，逐个验证完整字节消费。当前失败项为零。布局重建与原始类型树区分记录。
- Lua：现有兼容版 luac 5.3.5 + 严格格式解析器；为标准工具转换序列化头与长字符串长度，保留原始指令。
- Lua 源码：unluac 1.2.3.561，源码提交与下载哈希见工具 manifest。
- Lua 回编译：3,415 份全部结构一致；修正 9 处 unluac 生成差异，保留修正前源码与逐处证据。全部原型数量与独立 luac 列表一致。
- Android：JADX 1.5.3 + baksmali 3.0.9；43,784 个类均有 smali。原日志报告 37 个错误事件；实际生成文件中有 21 个文件含显式报错标记，全部映射到完整 smali。新恢复 DEX 的 JADX 导出退出码为 0。
- 原生：pyelftools + Capstone，按 ELF 可执行节核对覆盖字节数；保留 il2cpp 命名节，不能只读取 .text。
- Spine：@pixi-spine/runtime-3.8 4.0.6；依据客户端 RVA 0x1927350 的 marker 153 分支补充延迟加载支持。1,115 个骨架完整读取并导出全部几何和时间线；555 个分离动画全部完成独立线格式解析与逐字节回编码验证，其中 237 个有匹配上下文，318 个无法在样本中找到匹配骨架。
- 加密嵌套代码：复现 AFk1rSDK 与 AFk1tSDK 算法及载荷字节修补，4 个 AppsFlyer 载荷全部解密；内部 ZIP CRC、DEX SHA1/Adler32/长度均验证。额外恢复 15 个类，全部导出 smali 与 Java。assets/dic 按实际 SDK 读取算法解密为 EM_386 ELF。
- SDK 配置：Billing protobuf 全量线结构解析；Vulkan AQKV 的 16,088 字节均归属到头部、589 个字符串、固定表和预测参数。字段语义解释保留为后续分析项，未用“已知 SDK 名称”代替解析。
- 数据库：sqlcipher3-wheels 0.5.7，依据 SQLiteDatabase 初始化函数及 ELF 重定位定位密码；SQLCipher 4 解密后通过 SQLite integrity_check。

独立核对 2,210 个 Unity 容器，数量不一致 0 个；逐文件校验 1,485,143 份产物 SHA-256，失败 0 份。

严格解析和结构一致验证提高阅读可信度，但不代替玩法分析。未执行游戏行为一致性测试。下载文件的 SHA-256 是采集证据，未将它冒充 catalog 的 Unity Hash128 或 CDN 官方校验值。

## 剩余缺口

| 项目 | 数量 | 状态 |
| --- | ---: | --- |
| 已完整拆出、待解释字段语义的 SDK 配置 | 2 | 有低层证据，阅读仍需复核 |
| 分离动画缺少匹配骨架上下文 | 318 | 阻断全量验收 |
| 原生逻辑的高层阅读材料 | 1 | 有低层证据，阅读仍需复核 |
| JADX 源码生成异常 | 21 | 有低层证据，阅读仍需复核 |

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

- `base.apk`：`797bcb3ce96430983f4cca68b765dc03873f944db4c732daafb963a0b24d7a19`
- `split_config.arm64_v8a.apk`：`10e507ccfc6a4d9d46b80d70bf7cbe940b59376dc5ee64fd933bbd4d03812e5b`
- `split_gpdeku.apk`：`065c6ed81d402829c6ea272c6e52bc64a879c563cd510a160a769cdf1751cccf`
- `split_gpdeku.config.arm64_v8a.apk`：`39b0416e554448678fd5321d382ceaad0a2c9e113421f83bf8c8fefef71e08d0`
