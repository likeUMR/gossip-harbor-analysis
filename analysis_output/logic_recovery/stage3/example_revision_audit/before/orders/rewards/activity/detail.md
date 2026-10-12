# 按顺序收集活动奖励：具体算法与配置

GetRewards若Finished返回缓存DeepCopy，若Special返回空表。正常追加顺序：主装饰代币(Started对象且CanAddScore，数量>0)→FloatRace(CanAddScore且非nil)→TimedOrder检查GetTimedOrderRewards中是否含相册缓存奖励并设skipAlbumReward（这里没有把整份TimedRewards追加！）→未跳过时Album(IsActivityOpen)按diff/slot或orderType+innerType取包并复制，CanSupportAlbumBuff再×2；相册Buff还要求buff激活、非Timed/非Special且预览false调用结果非空→Avenue正分→Upward非nil→Road正分→HitBricks资格调用为真再调用一次取奖→Ring真→Combo真→ActivityModuleManager各模块GetRewardsByOrder返回非空数组追加→ChestCustomer槽追加RewardKey..innerType.."_"..slot,count1→基础金币/BakeOut。

ActivityModuleManager以pairs遍历注册模块，不保证跨模块固定顺序；各GetAddScoreByOrder内部资格/公式与远端档位属于具体活动，不能把“活动开启”当成必定有奖。

## 源码依据

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:CanSupportAlbumBuff（恢复文本行128）；MainOrder:GetRewards（恢复文本行136）

- Model.Activity.ActivityModuleManager：[恢复源码](../../../../assets/order-evidence/Model.Activity.ActivityModuleManager.lua) · [原始指令](../../../../assets/order-evidence/Model.Activity.ActivityModuleManager.disassembly.txt)。对应：ActivityModuleManager:GetRewardsByOrder（恢复文本行60）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例所有活动资格关闭，所以不追加活动代币、相册包或宝箱标记；只留下末尾金币。

### 代入本页的值

rewards=[{type=Gold,count=8}]；不是每项活动都获得1份。对照TimedRewards含相册包，仅导致skipAlbumReward=true，不自动证明此函数追加了限时奖励。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
