"""Record the refresh/round lifecycle reached from GeneratorBoost cooldown callbacks."""
from pathlib import Path
import hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit/reconciliation'
DOC=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site/docs/operations/generator/lifecycle/cooldown/detail.md'
SRC=ROOT/'analysis_data/logic_index/lua/decoded/e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01/decompiled.lua'
BODY='''## 活动日刷新、进度清零与轮次递增

GeneratorBoost 每秒更新先调用基础活动更新，然后只有资源检查后的状态是 `Started` 才继续。服务器时间达到 `GetRefreshTime()` 时，执行顺序固定为：`ClearState()` → `SetRefreshTime()` → 派发 `RefreshEvent` → 将首次弹窗标记写为 `false` → 将主窗口弹出标记写为 `true` → `AddRoundNum()`。因此刷新日不仅清空任务进度，也会清除当前增益；刷新时间写入的是当前服务器时间对应的当天 24 点时间戳，轮次在数据库中加一。

`ClearState()` 先把当前进度和上次展示进度都重建为四个零，再分别保存两份 JSON，最后调用 `ClearBuff()`。`ClearBuff()` 在活动等级已经是 0 时提前返回；有增益时才删除等级、额外产出总数/剩余数和两类缓存，重载物品与 Lucky 配置，关闭主动产出并发送清除事件。它不会统一清除普通母体的次数或冷却字段。

`AddRoundNum()` 先计算旧轮次加一并写入 `RoundNum`，随后 BI 记录读取到的 `GetRoundNum()` 和服务器配置组；如果底层读取仍返回旧值，BI 的 `r` 也会保持旧值，这两个写入/记录动作不能合并成“记录新轮次”。

### 数值例子

假设服务器时间已经达到刷新时间，当前轮次为 4，四项任务进度为 `[3, 8, 1, 0]`，活动等级为 2，额外产出剩余 5。刷新后先把两份进度都保存为 `[0, 0, 0, 0]`，再按 `ClearBuff` 顺序删除等级、额外份额和缓存、恢复默认配置；随后保存新的当天刷新时间，内存弹窗标记变为“需要弹出”，数据库轮次写为 5，并发送刷新事件。普通母体自身的 `m_itemRestNumber` 不因这次活动刷新自动归零。
'''
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    marker='<!-- reconciliation-activity-lifecycle:start -->'
    text=DOC.read_text(encoding='utf-8')
    if marker not in text:
        backup=OUT/'before_activity_lifecycle'/'lifecycle/cooldown/detail.md'
        backup.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(DOC,backup)
        pos=text.find('\n## 贯穿案例')
        assert pos>=0
        text=text[:pos]+'\n'+marker+'\n'+BODY+'\n<!-- reconciliation-activity-lifecycle:end -->\n'+text[pos:]
        DOC.write_text(text,encoding='utf-8')
    result={'source':SRC.relative_to(ROOT).as_posix(),'source_sha256':sha(SRC),'document':DOC.relative_to(ROOT).as_posix(),'document_sha256':sha(DOC),'resolved_rules':['Started gate','refresh order','ClearState progress persistence','ClearBuff level-zero early return','round increment and BI ordering'],'open_edges':['all dynamic RefreshEvent consumers','native DB commit/reload','full activity configuration selection'],'full_acceptance':False}
    (OUT/'activity_lifecycle_review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))
if __name__=='__main__':
    main()
