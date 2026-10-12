from pathlib import Path

path = Path(r"C:\Users\TU\Documents\ChatGPT\Gossip_Harbor_Analysis\analysis_output\logic_recovery\stage3\mkdocs_site\mkdocs.yml")
text = path.read_text(encoding="utf-8")
if "operations/paid/index.md" not in text:
    block = """  - 付费项目:
      - operations/paid/index.md
      - 常驻钻石包:
          - operations/paid/gem_pack/index.md
          - 价格档位与奖励: operations/paid/gem_pack/detail.md
      - 常驻商店购买:
          - operations/paid/regular_shop/index.md
          - 商品候选、权重与购买次数: operations/paid/regular_shop/detail.md
      - 每日特惠与闪购:
          - operations/paid/daily_flash/index.md
          - 日界刷新、广告与动态价格: operations/paid/daily_flash/detail.md
      - 新手礼包:
          - operations/paid/starter/index.md
          - 等级触发、持续时间与一次性购买: operations/paid/starter/detail.md
      - 时间限时礼包:
          - operations/paid/time_limit/index.md
          - 触发窗口、过期与展示资格: operations/paid/time_limit/detail.md
      - 能量礼包:
          - operations/paid/energy/index.md
          - 价格触发、次数上限与刷新: operations/paid/energy/detail.md
      - 订单与棋子定向礼包:
          - operations/paid/order_item/index.md
          - 缺口触发、优先级与礼包内容: operations/paid/order_item/detail.md
      - 周期与链式礼包:
          - operations/paid/weekly_chain/index.md
          - 周期、阶段推进与购买记录: operations/paid/weekly_chain/detail.md
      - 新周礼包:
          - operations/paid/new_weekly/index.md
          - 周期窗口与新周模型: operations/paid/new_weekly/detail.md
      - 成长基金:
          - operations/paid/growth_fund/index.md
          - 等级奖励、购买与领取资格: operations/paid/growth_fund/detail.md
      - 等级礼包:
          - operations/paid/level_up/index.md
          - 等级触发、弹窗与关闭: operations/paid/level_up/detail.md
      - 三阶段礼包:
          - operations/paid/tri_stage/index.md
          - 阶段触发、商品属性与购买索引: operations/paid/tri_stage/detail.md
      - 一加N礼包:
          - operations/paid/one_plus_n/index.md
          - 周期、弹窗上限与多步奖励: operations/paid/one_plus_n/detail.md
      - 一加四礼包:
          - operations/paid/one_plus_four/index.md
          - 四步内容、冷却与领取: operations/paid/one_plus_four/detail.md
      - 自定义卡牌礼包:
          - operations/paid/customize_card/index.md
          - 卡牌配置、奖励内容与价格: operations/paid/customize_card/detail.md
      - 砍价礼包:
          - operations/paid/chop_gift/index.md
          - 砍价阶段、价格描述与购买: operations/paid/chop_gift/detail.md
      - 大量礼包:
          - operations/paid/plenty/index.md
          - 礼包集合与批量奖励: operations/paid/plenty/detail.md
      - 活动与个性化礼包:
          - operations/paid/event_personalized/index.md
          - 服务端投放、分层与未知边界: operations/paid/event_personalized/detail.md
      - 礼包价值与性价比:
          - operations/paid/value/index.md
          - 内部价值、折扣率与有效价值: operations/paid/value/detail.md
"""
    text = text.replace("nav:\n", "nav:\n" + block, 1)
    path.write_text(text, encoding="utf-8")
print("paid nav present", "operations/paid/index.md" in path.read_text(encoding="utf-8"))
