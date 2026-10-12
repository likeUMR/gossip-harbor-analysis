# 合成记录与同步：具体算法与配置

GM.SyncModel:CheckMoreUpload(New.Type)位于金币之后；_DoMergeItem返回mergeInfo，_MergeItem调用_LogMerge。日志ext含TempType、BubbleType、BubbleSalePrice、BubblePrice、Balloon、ScoreRace_Score、CardType；目标有Cobweb时cobWeb=1；Group非nil写ebGroup；最近触碰配对命中写isTouched=true。

logType默认Source.Type；Target有ItemTemp时改为Target.Type，不与普通结果类型混淆。LogMerge(logType,New.Code,ext,BoardType)之后DragItem立即return；视图函数继续选中状态、BoardPointerUp等收尾。

CheckMoreUpload是触发检查而非无条件已上传；上传开关、队列与远端结果分别决定。客户端规则恢复不等于已确认服务端存档一致。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：正常合成结束并返回

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。201×2合成202，Source/Target无Temp/Cobweb，假设本次无副产物；最近触碰配对未命中。

**按执行顺序代入：** Coin检查→CheckMoreUpload(202)→LogMerge(201,202,ext)；ext副产物字段nil，logType201；DragItem return。

**玩家看到的结果：** 棋盘剩目标格202，源格空出，能量不变；同步已提出检查，本例不假设服务器已确认。
