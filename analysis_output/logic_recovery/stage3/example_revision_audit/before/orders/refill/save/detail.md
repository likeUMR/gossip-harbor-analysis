# 移除旧单、保存新单与重载：具体算法与配置

_RemoveOrder先清Album槽奖励（无模型缓存待清槽），再_DBRemoveOrder。DBRemove删槽行、礼物信息，写lastfinishorder_slot=innerType@avatarId@id@code1;code2;code3，并保留内存旧订单引用；清luckorder_/baselineorder_/UnLockedDiffRange_；ChestOrderFinish清宝箱槽状态。DBAdd BatchSet该槽type、最多3条requirementStr、avatarId、id，保存礼物；Lucky/基准真分别写标记"1"，DiffRange真写字符串。DBGetOrders读取所有槽和标记、空DiffRange→nil；_CreateOrder对Timed类用TimedOrderOrder、Extra用EmptyReqOrder，其他MainOrder；恢复礼物后回集合。_DBGetLastFinishOrder按@和;拆分，但源码未将innerType/avatarId/id统一tonumber，类型一致性不能擅自假设。重复链状态json逗号换@保存、恢复逆换json.decode，空集合删除记录。原生DB存档一致性和同步回滚需外部运行验证。

## 源码依据

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:_DBGetOrders（恢复文本行284）；MainOrderModel:_DBGetLastFinishOrder（恢复文本行322）；MainOrderModel:SaveRepeatWeightDecreaseInfo（恢复文本行348）；MainOrderModel:_DBAddOrder（恢复文本行358）；MainOrderModel:_DBRemoveOrder（恢复文本行395）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例旧需求203;203;204被记为上一单。新单若创建成功，保存其真实需求，之后重载复用已保存需求。

### 代入本页的值

历史字符串示意1@头像@Id@203;203;204；不删除重复203；新单标记仅真才写1。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
