# 特殊任务确认：具体算法与配置

Init插入1秒回调置m_initialized=true并开效果；i=1..3按requirements[i]显隐。FilterItems过滤GetType==requirement且mapSelectedItem未选中，取第一件并隐藏原视图，1秒移动和缩放，多件放大2倍、单件3倍；1秒后循环上下摆动。没选到棋盘物时inventoryItemMap[i]=code并从仓库HUD位置显示图像，未实际校验仓库。遮罩点击在initialized未真时return；初始化后恢复仍存在的原视图位置/缩放，调用MainBoardModel.FinishOrder，随后按inventoryItemMap播放飞入订单表现并Close。没有再次CanDeliver，最多3个槽的展示不能泛化成任意需求数量。

## 源码依据

- UI.Window.Order.SpecialOrderItemWindow：[恢复源码](../../../../assets/order-evidence/UI.Window.Order.SpecialOrderItemWindow.lua) · [原始指令](../../../../assets/order-evidence/UI.Window.Order.SpecialOrderItemWindow.disassembly.txt)。对应：SpecialOrderItemWindow:Init（恢复文本行8）；SpecialOrderItemWindow:OnWindowMaskClicked（恢复文本行84）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：特殊订单二次点击

**完整输入（演示设定）：** 假设特殊任务需求1610一件，棋盘上有该物且可用于展示；按钮开启，初始化和聚拢已完成。 本例采用特殊任务Id1配置，宝石20、能量10，清链与奖励输入同特殊任务场景。

**按执行顺序代入：** 首次打开SpecialOrderItemWindow；等待完成标记；再次点击→还原展示对象→FinishOrder→特殊完成路径，随后关闭窗口。

**玩家看到的结果：** 首次点击只看到任务物聚拢；第二次点击完成任务1，按任务表领15宝石和100能量，余额变35宝石、110能量。
