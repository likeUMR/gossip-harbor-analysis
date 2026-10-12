# 动态包装器直接效果索引

{
  "gap_functions_examined": 23,
  "wrapper_functions_found": 82,
  "direct_effects": 17,
  "dynamic_calls": 188,
  "by_effect": {
    "explicit_noop": 4,
    "network_call": 1,
    "ui_effect": 12
  },
  "database": "analysis_data/logic_index/stage2/dynamic_wrapper_effects.sqlite3",
  "quality": "candidate_static_evidence",
  "limitations": [
    "Function boundaries are conservative line spans and should be checked against Lua AST/bytecode for unusual nested syntax.",
    "A direct effect proves the wrapper operation exists, but not the identity or lifetime of a dynamically supplied callback target."
  ]
}

该索引把‘包装器中已经确定的效果’和‘被动态字段/配置表转交的目标仍未确定’分开记录。它不能替代对象身份、调用时序和运行时分支证明。
