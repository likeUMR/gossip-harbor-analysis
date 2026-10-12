# 订单存档与恢复：具体算法与配置

_RemoveOrder先清Album槽奖励（无模型缓存待清槽），再_DBRemoveOrder。DBRemove删槽行、礼物信息，写lastfinishorder_slot=innerType@avatarId@id@code1;code2;code3，并保留内存旧订单引用；清luckorder_/baselineorder_/UnLockedDiffRange_；ChestOrderFinish清宝箱槽状态。DBAdd BatchSet该槽type、最多3条requirementStr、avatarId、id，保存礼物；Lucky/基准真分别写标记"1"，DiffRange真写字符串。DBGetOrders读取所有槽和标记、空DiffRange→nil；_CreateOrder对Timed类用TimedOrderOrder、Extra用EmptyReqOrder，其他MainOrder；恢复礼物后回集合。_DBGetLastFinishOrder按@和;拆分，但源码未将innerType/avatarId/id统一tonumber，类型一致性不能擅自假设。重复链状态json逗号换@保存、恢复逆换json.decode，空集合删除记录。原生DB存档一致性和同步回滚需外部运行验证。

## 源码依据

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:_DBGetOrders（恢复文本行284）；MainOrderModel:_DBGetLastFinishOrder（恢复文本行322）；MainOrderModel:SaveRepeatWeightDecreaseInfo（恢复文本行348）；MainOrderModel:_DBAddOrder（恢复文本行358）；MainOrderModel:_DBRemoveOrder（恢复文本行395）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：保存与重载保持同一需求

**完整输入（演示设定）：** 旧槽4类型3/avatar6/Id42/需求203;203;204；假设新单类型3/avatar7/Id43/需求203;503、Lucky=false、baseline=false、无DiffRange或礼物。

**按执行顺序代入：** 历史lastfinishorder_4=3@6@42@203;203;204；DBAdd记录槽4/type3/avatar7/id43/requirementStr203;503，清旧特殊标记；DBGet恢复同需求数组。

**玩家看到的结果：** 重开后槽4仍是要求203和503的同一订单，旧单两个203的重复记录也保留；不会重开变成另一份需求。
