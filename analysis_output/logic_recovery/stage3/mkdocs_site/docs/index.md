# Gossip Harbor 棋盘逻辑

本站采用逻辑树组织，不按真实源文件排列。左侧树的每一层代表游戏逻辑的一层：根节点是玩家操作，下一层是操作中的主要判断，再下一层是判断内部的机制分支，最底层页面直接给出算法、配表、状态和源码证据。

## 三个根操作

- [母体点击](operations/generator/index.md)：状态、空位、能量、Lucky、五类普通产出、次数、CD 和后续事件。
- [棋子拖拽与合成](operations/merge/index.md)：移动、交换、特殊棋子、普通合成和副产物。
- [订单提交](operations/orders/index.md)：可交付判断、需求扣除、奖励、订单完成和补位。

## 阅读方法

展开左侧树，父页面只解释当前层级的作用、顺序和子节点；子页面继续向下展开。底层节点页面同时展示算法、配表、状态字段、源码位置和证据等级，不把证据从机制中拆走。

参考入口：[配置索引](reference/configuration.md)、[证据分级](reference/evidence.md)、[验收矩阵](verification/acceptance.md)、[当前状态](verification/status.md)。这些页面不占用左侧一级逻辑树。

## 当前规模

Lua 模块 3,415 个，Lua 原型 33,272 个，Android 类 43,784 个，Android 方法 254,729 个。`ItemModelConfig`: 548 行，Spread 163 行，MergedType 370 行，BubbleChance>0 138 行；`OrderItemConfig`: 74 行，DiffScore 2–3000。