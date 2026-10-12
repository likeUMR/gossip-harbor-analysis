# 同步检查、合成日志与返回：具体算法与配置

GM.SyncModel:CheckMoreUpload(New.Type)位于金币之后；_DoMergeItem返回mergeInfo，_MergeItem调用_LogMerge。日志ext含TempType、BubbleType、BubbleSalePrice、BubblePrice、Balloon、ScoreRace_Score、CardType；目标有Cobweb时cobWeb=1；Group非nil写ebGroup；最近触碰配对命中写isTouched=true。

logType默认Source.Type；Target有ItemTemp时改为Target.Type，不与普通结果类型混淆。LogMerge(logType,New.Code,ext,BoardType)之后DragItem立即return；视图函数继续选中状态、BoardPointerUp等收尾。

CheckMoreUpload是触发检查而非无条件已上传；上传开关、队列与远端结果分别决定。客户端规则恢复不等于已确认服务端存档一致。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



主例日志记录201合成202，没有临时/气泡/卡片字段；同步模型检查202，随后视图选中202。

### 代入本页的值

Source.Type=201、Target无Temp/Cobweb、New.Code=202；ext副产物字段nil。执行次序Coin检查→CheckMoreUpload(202)→LogMerge(201,202)→DragItem return。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
