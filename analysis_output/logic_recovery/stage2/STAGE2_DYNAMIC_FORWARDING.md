# 动态对象字段转发索引

{
  "functions": 24736,
  "assignments": 16936,
  "calls": 25055,
  "links": 10713,
  "by_certainty": {
    "method_ambiguous": 15481,
    "same_module_field_assignment_candidate": 5983,
    "method_unique": 6995,
    "method_unresolved": 2579,
    "same_module_field_assignment": 5070
  },
  "receiver_fields": 3477,
  "database": "analysis_data/logic_index/stage2/dynamic_forwarding.sqlite3",
  "limitations": [
    "Field assignment and method-name matches are static candidates; they do not establish runtime object identity or inheritance dispatch.",
    "Calls through table indexes, locals captured by closures and C# objects require separate bridge/runtime evidence."
  ]
}
