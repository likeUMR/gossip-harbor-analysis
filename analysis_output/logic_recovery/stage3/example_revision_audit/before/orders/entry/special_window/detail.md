# 特殊订单展示后的再次点击：具体算法与配置

Init插入1秒回调置m_initialized=true并开效果；i=1..3按requirements[i]显隐。FilterItems过滤GetType==requirement且mapSelectedItem未选中，取第一件并隐藏原视图，1秒移动和缩放，多件放大2倍、单件3倍；1秒后循环上下摆动。没选到棋盘物时inventoryItemMap[i]=code并从仓库HUD位置显示图像，未实际校验仓库。遮罩点击在initialized未真时return；初始化后恢复仍存在的原视图位置/缩放，调用MainBoardModel.FinishOrder，随后按inventoryItemMap播放飞入订单表现并Close。没有再次CanDeliver，最多3个槽的展示不能泛化成任意需求数量。

## 源码依据

- UI.Window.Order.SpecialOrderItemWindow：[恢复源码](../../../../assets/order-evidence/UI.Window.Order.SpecialOrderItemWindow.lua) · [原始指令](../../../../assets/order-evidence/UI.Window.Order.SpecialOrderItemWindow.disassembly.txt)。对应：SpecialOrderItemWindow:Init（恢复文本行8）；SpecialOrderItemWindow:OnWindowMaskClicked（恢复文本行84）


---

## 贯穿案例：203×2与204×1，使用仓库补交

主例是普通订单，不打开特殊展示窗。对照改为特殊订单时，首次按钮点击仅展示，1秒初始化之后再次点遮罩才提交。

### 代入本页的值

对照t<初始化回调：OnWindowMaskClicked直接return；回调后true→FinishOrder；展示对象集合避免同一实例重复被选择。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
