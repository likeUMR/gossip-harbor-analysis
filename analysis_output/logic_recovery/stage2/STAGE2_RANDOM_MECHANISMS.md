# 随机与抽样机制索引

扫描 Lua 模块：3415
机制记录：1983
权重相关记录：62
明确 `table.remove` 删除候选：150

## 已恢复的共享算法
- `Table.ListRandomSelectN(source, selectCount)`：若 `selectCount >= #source` 直接返回 source；否则每次调用 `MathUtil.Random(#source)` 取 1-based 索引，将元素加入 results，再执行 `table.remove(source,index)`。因此 N 小于候选数时无放回且原地缩短 source；N 不小于候选数时返回整个 source。
- `Table.ListAlwaysRandomSelectN(source, selectCount)`：先 `Table.DeepCopy(source)`，最多循环 `min(#source,selectCount)` 次，每次随机索引后从拷贝删除；无放回但不修改调用方 source。
- `MathUtil.RandomN(n, selectCount)`：维护已选索引 map；第 i 次在 `1..n-i+1` 取随机位置，再按已选位置向右校正成原数组索引并标记，返回不重复索引列表。
- `Table.ListRandomSelectOne(source)`：空表返回 nil，否则调用 `MathUtil.Random(#source)` 返回一个元素，不删除 source；重复调用允许重复结果。
- `Table.ListWeightSelectOne(source, weightKey)`：默认字段 `Weight`，先求权重总和，要求总和大于 0；再取 1 到总和的整数随机数，按累计权重区间返回元素，不删除 source。
- `MathUtil.Random(l,r)`：先取 `math.random()` 的 `[0,1)` 浮点值；单参数返回 `floor(CurRandom*l)+1`，双参数返回 `l+floor(CurRandom*(r-l+1))`，因此整数端点均包含。测试模式可由 `GM.TestModel:SetMathRandomLR` 把浮点区间改为 `[fCurLeft,fCurRight]`，默认 `[0,1]`。

## 判定口径
- `ListRandomSelectN` 已依据共享 helper 源码证据标为 without_replacement。
- 其他删除点只有在随机索引和候选集合关系清楚时才升级为无放回；单独出现 `table.remove` 只证明候选表被修改。

## 分类
{
  "candidate_mutation": 1493,
  "candidate_remove": 150,
  "random_n": 21,
  "random_uniform": 257,
  "weighted": 62
}
