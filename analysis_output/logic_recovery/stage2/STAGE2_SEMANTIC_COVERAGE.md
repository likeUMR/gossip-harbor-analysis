# 阶段二输入语义覆盖矩阵

{
  "roots": 1010,
  "by_class": {
    "direct_wrapper_effect_unresolved_target": 5,
    "downstream_effect_evidence": 993,
    "dynamic_callback_candidate_linked": 3,
    "dynamic_callback_effect_candidate": 2,
    "dynamic_forwarding_candidate": 3,
    "explicit_noop_or_guard_only": 4
  },
  "with_event": 872,
  "with_state": 874,
  "with_network": 684,
  "with_bridge": 926,
  "with_random": 344,
  "with_config": 369,
  "database": "analysis_data/logic_index/stage2/semantic_coverage.sqlite3"
}

该矩阵按输入根统计静态可达的事件、状态、网络、桥接、随机和配置证据。`downstream_effect_evidence` 只表示静态索引中存在后续效果证据，不表示已证明运行时一定触发；动态接收者、服务端行为和未解析回调仍不能由该表单独证明。
