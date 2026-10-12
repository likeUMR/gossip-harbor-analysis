# GH 调试工具索引

样本：Gossip Harbor 3.98.10。本文记录包内静态证据；未在游戏进程中实际连接 IDE，因此“已包含”和“当前构建/账号能连通”分开标记。

## 结论

安装包内包含可用作 Lua 调试入口的 LuaPanda 与 EmmyLua 集成、Lua/C# 变量检查工具及测试面板中的调试地址窗口。地址映射和 ARM64 汇编表明 `LuaManager.Initialize` 会直接调用 `LuaDebugHelper.AddDefaultDebugger`。该方法读取 `lua.debugger` 偏好值，默认值为 2；`AddDebugger` 将 0 映射为不挂调试器、1 映射为 EmmyLua、2 映射为 LuaPanda。偏好项可覆盖此默认行为。

LuaPanda 启动时作为客户端连接到配置地址的 8818 端口；C# 集成传入 `TestDebugAddress`，默认 `localhost`。EmmyLua 集成执行 `emmy_core`，调用 `dbg.tcpListen('localhost', 9966)`，并检查 `emmy.wait.ide.enable`。这些连接值和函数调用来自当前包的字符串常量及反汇编，尚未通过运行时抓包验证网络方向以外的 IDE 握手兼容性。

## 工具构成与证据

| 组件 | 包内职责 | 当前证据与边界 |
| --- | --- | --- |
| LuaDebugHelper | 在 LuaEnv 初始化期间按持久化偏好选择调试器；支持 Null、EmmyLua、LuaPanda | Il2CppDumper 元数据与 ARM64 汇编；直接入口 `LuaManager.Initialize -> AddDefaultDebugger -> AddDebugger`。方法体可在 `il2cpp_native.sqlite3` 按符号查询，RVA 汇编见下方定位 |
| LuaPanda 3.3.1 | Lua 断点、单步、变量与调用栈调试；模块带有 socket 客户端逻辑 | Lua 字节码共 149 个原型、7,850 条指令，round-trip 结构验证通过。`start(host, port)` 默认连接 `127.0.0.1:8818`；本样本 C# 注入地址来自 `TestDebugAddress`，默认 `localhost` |
| EmmyLua | 通过 emmy_core Lua 模块提供 IDE 调试 | 本机代码内含 `require('emmy_core')` 与 `dbg.tcpListen('localhost', 9966)`；`emmy.wait.ide.enable` 控制等待 IDE 的相关逻辑。Emmy 库本体是否在该构建运行时可加载，仍需真机/模拟器验证 |
| LuaDebugTool | 暴露 Lua/C# 对象值检查：取 C# 字段、搜索对象数据、转换变量信息、读取 userdata/list/dictionary | `dump.cs` 有类和方法签名，XLua 包装器存在注册/导出方法；C# 函数体需结合原生汇编阅读 |
| TestDebugAddressWindow | 在测试窗口中选择/输入 LuaPanda 目标主机 | 默认 `localhost`；确认地址变化后写入 `TestDebugAddress` 并调用退出，要求重启后生效。窗口由测试工具打开；测试入口受测试模式和测试面板偏好控制 |

## 调试器选择逻辑

1. `LuaManager.Initialize` 在 LuaEnv 初始化链中调用 `LuaDebugHelper.AddDefaultDebugger`（直接调用，`il2cpp.asm` 行 805,927；RVA `0x1281ca8`）。
2. `AddDefaultDebugger` 对 `lua.debugger` 读取默认值 2；值为 0 时返回，不注入调试器；非 0 时调用 `AddDebugger`（RVA `0x133c418`）。
3. `AddDebugger` 读取同一选择值：0 不加载，1 走 `AddEmmyLuaDebugger`，2 走 `AddLuaPandaDebugger`，其他值抛 `ArgumentOutOfRangeException`（RVA `0x133bf68`）。
4. `SelectDebugger` 将传入枚举值保存到 `lua.debugger`；测试数据清理逻辑会在 `DeleteAll` 前后保留此偏好值。
5. `AddLuaPandaDebugger` 注入以下等效启动代码：读取 `TestDebugAddress`，缺省 `localhost`，再执行 `LuaPanda.start(debugAddress, 8818)`。LuaPanda 的 `start` 实现为客户端 `sock:connect(host, port)`。
6. `AddEmmyLuaDebugger` 注入 EmmyLua 初始化代码并监听 `localhost:9966`；另外读取 IDE 等待开关 `emmy.wait.ide.enable`。

第 2、3 步由 ARM64 指令的参数常量、条件分支和直接调用目标支持；枚举名称来自 `dump.cs`。`dump.cs` 的函数体是空壳，所以需要把这些结论视为“元数据 + 机器码静态恢复”，不是原始 C# 源码。

## 文件定位

- `analysis_data/logic_index/stage2/il2cpp_dumper_run/dump.cs`：LuaDebugHelper 枚举、键和方法签名；LuaDebugTool API。
- `analysis_data/logic_index/stage2/il2cpp_dumper_run/stringliteral.json`：LuaPanda、EmmyLua 注入字符串及配置键。
- `analysis_data/logic_index/native/<libil2cpp-sha256>/il2cpp.asm`：方法入口的 ARM64 汇编。
- `analysis_data/logic_index/stage2/il2cpp_native.sqlite3`：按 `methods.name`、`direct_calls.target_method_name`、`native_functions.start_address` 查询符号、调用方和汇编行。
- `analysis_data/logic_index/lua/decoded/0357ab743b048f0a341af0d2faf4bcf9d9776ad59497da36fbf4b0a4b33ddbc1/decompiled.lua`：LuaPanda 可读反编译文本。
- `analysis_data/logic_index/lua/decoded/dfd3085707448532fe93997573febb80753adf771a208904cc10fe76eae0f037/decompiled.lua`：地址编辑、保存和重启逻辑。
- `analysis_data/logic_index/lua/decoded/7690ccbd5e2e63f852899ce1a2a9faa13b199d77344cb02cd1357464f46b2446/decompiled.lua`：`ClearTestPlayerPrefs` 对 `lua.debugger` 偏好的保留逻辑。

精确 RVA：GetCurLuaDebugger `0x133be88`；SelectDebugger `0x133bed0`；AddDebugger `0x133bf68`；AddEmmyLuaDebugger `0x133c020`；AddLuaPandaDebugger `0x133c338`；AddDefaultDebugger `0x133c418`；IsEmmyWaitForIDE `0x133c47c`；SetEmmyWaitForIDE `0x133c4d0`。每个函数在 `il2cpp_native.sqlite3` 有对应 `start_line`/`end_line`。

## 尚未验证

- 目标安装包启动后 `lua.debugger` 的设备实际值，以及启动时是否成功加载 LuaPanda 或 EmmyLua。
- `emmy_core` 本体、LuaSocket native 库和 Android ABI 兼容性；LuaPanda 会在 socket 获取失败时报告错误并停用调试 hook。
- IDE 连接与协议版本兼容性；包内 LuaPanda 自报版本为 3.3.1。
- 测试地址窗口的权限边界、是否只在 test build 存在，以及改变地址后重启的完整操作链。
- 用隔离设备验证监听绑定、端口转发、断线重连、断点/单步/变量读写和退出清理。

因此，这些工具足以作为阶段三试点的调试手段候选，但当前不能声称目标 APK 上调试连接已经可用。运行时验证前不应把包内默认值等同于用户设备的有效偏好状态。
