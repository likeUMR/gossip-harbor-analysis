# 交换写格、订单刷新与计时：具体算法与配置

记itemPosition=S。顺序_SetItem(S,nil,false)→_SetItem(T,source,false)→_SetItem(S,target)；第三次未传false，会CountItemsCode/UpdateOrderState。旧说明“两次对象写回都禁订单刷新”错误，当前实现只前两次禁用。

随后_LogMove(source,source.GetPosition(),T)，_LogMove(target,T,S)，再source.SetPosition(T)、target.SetPosition(S)，最后_UpdateAccelerate(source,target)。因此订单刷新通知发生在两对象SetPosition之前，但格层已经交换；同步消费者读取格层与对象位置时须按该时点理解。

交换没有空位移动分支的ItemMoveEnd，也没有普通合成/吞噬事件。存在计时或激活加速组件时UpdatePerSecond调用两次；不是两件新物，不SaveItemProperty重建状态。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.MainBoardItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-201.png" alt="棋子201" style="width:72px;height:72px;object-fit:contain;margin-right:12px;"><img src="../../../../../assets/cases/item-202.png" alt="棋子202" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

本例不交换。不同类型对照：source201与target202不可普通合成，均可移动时互换。

### 代入本页的值

S=(3,3)、T=(4,3)：第三次SetItem(S,target,nil)触发一次订单刷新，此时source.Position仍S、target.Position仍T；随后改为T/S，再加速更新。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
