"""Document GeneratorBoost task progress handling reached after ItemSpread."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit/reconciliation'
DOC=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site/docs/operations/generator/energy/consume/detail.md'
SRC=ROOT/'analysis_data/logic_index/lua/decoded/e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01/decompiled.lua'
BODY='''## GeneratorBoost 任务进度与增益升级

GeneratorBoost 在活动进入 `Started` 时注册 `TaskEventProgressGain`，结束或释放时移除注册；本次点击的能量消耗经 PropertyConsumed 通知进入任务模块：只接受属性类型 Energy，以实际通知中的属性数量形成 Energy 任务消息。任务模块形成 `operation=Add` 的进度消息，再进入 `_OnProgressGain`。处理顺序是：先拒绝非 `Add` 消息；取得当前已完成任务数；按任务配置顺序遍历所有 `taskType` 等于消息类型的任务。

对每个匹配任务，特殊订单类型 `MainOrderType.Special` 会被跳过；已经达到 `task.num` 的任务也跳过。其它任务把当前进度与 `message.num` 相加，再用 `min(结果, task.num)` 截顶，立即把整个进度数组 JSON 写回数据库。刚好达到目标时，再记录完成任务 BI 并派发 `TaskFinishedEvent`；只有进入本消息前已经至少完成过一个任务（`finishedCount >= 1`），才在这个完成点调用 `BuffLevelUp`。已完成任务数在进入循环前只计算一次：如果进入时没有任务完成，即使同一消息连续完成两项任务，两项都不会调用升级；进入时已有至少一项完成，每个新完成的匹配任务都会分别尝试升级。

`BuffLevelUp` 先计算当前等级加一。存在该等级配置时才写 `ActiveBuffLevel` 和激活 BI，并按新 Buff 类型重载 Lucky、重载普通物品配置，或派发 NoCD 的主棋盘逻辑事件；即使不存在下一级，函数最后仍会把主窗口标记为待弹出并把主动产出标记设为真。任务配置 `generatorBoostTask` 和增益配置 `generatorBoostBuff` 来自服务器配置，客户端源码只确定字段和算法，不能把当前账号的任务数量当成包内默认值。

### 进度消息怎样到达活动模型

`TaskEventProgressGainModule:AddRegister` 用模型对象作键保存注册项；未提供自定义条件时，默认条件是该模型的 `GetState(false)==Started`。派发时用 `pairs` 遍历注册表，逐个调用条件函数，通过后才调用模型的 `_OnProgressGain`，因此不能假设活动模型有固定先后顺序。消息的 `operation` 为空时，模块先补成 `Add`；这与模型内部只接受 `Add` 的判断共同决定默认消息会计入进度。

该模块把多个独立来源转换成进度消息，例如能量属性消耗使用 `TaskEventType.Energy` 和消耗数量，气泡产出使用 `BubbleSpread`，其它来源还包括合成、订单、金币、卡片和活动专用事件。它们共用派发器，但每个来源自己的前置条件、数量字段和活动注册条件仍需分别核销；不能把“监听到了 ItemSpread”直接解释成所有任务都加一。

### 数值例子

假设任务表按 index 为 1、2、3、4 排序，类型分别为 `Energy`、`Energy`、`OrderFinish`、`Energy`，目标为 `[3, 2, 1, 5]`，当前进度为 `[2, 0, 1, 5]`。一次 `Energy` 消息 `num=4` 到达时，任务1先从 2 加到 3 并截顶，写入进度并完成任务；任务2再从 0 加到 2 并完成，但本次进入前 `finishedCount=2`（任务3和任务4已完成）时，两次完成都会分别调用 `BuffLevelUp`，而不是整条消息只升级一次。若消息携带的订单是 `Special`，匹配任务3即使未完成也跳过；若消息 `operation` 不是 `Add`，整个消息不改变任何字段。
'''
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    marker='<!-- reconciliation-generator-progress:start -->'
    text=DOC.read_text(encoding='utf-8')
    if marker not in text:
        b=OUT/'before_progress_lifecycle'/'energy/consume/detail.md'
        b.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(DOC,b)
        pos=text.find('\n## 贯穿案例')
        assert pos>=0
        text=text[:pos]+'\n'+marker+'\n'+BODY+'\n<!-- reconciliation-generator-progress:end -->\n'+text[pos:]
        DOC.write_text(text,encoding='utf-8')
    result={'source':SRC.relative_to(ROOT).as_posix(),'source_sha256':sha(SRC),'document':DOC.relative_to(ROOT).as_posix(),'document_sha256':sha(DOC),'resolved_rules':['Started registration/remove','Add-only gate','matching task iteration','special-order skip','progress cap and DB write','first-task no-level-up rule','BuffLevelUp terminal flags'],'open_edges':['TaskEventProgressGain dynamic producers and condition functions','server task/buff records','native DB and event consumers'],'full_acceptance':False}
    (OUT/'progress_lifecycle_review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))
if __name__=='__main__':
    main()
