# 阶段二验收报告

{
  "stage": "stage2",
  "status": "static_candidate_complete",
  "runtime_confirmation": "required_in_stage3",
  "roots": 1010,
  "evidence_classes": {
    "direct_wrapper_effect_unresolved_target": 5,
    "downstream_effect_evidence": 993,
    "dynamic_callback_candidate_linked": 3,
    "dynamic_callback_effect_candidate": 2,
    "dynamic_forwarding_candidate": 3,
    "explicit_noop_or_guard_only": 4
  },
  "unresolved_root_count": 0,
  "non_downstream_root_count": 17,
  "acceptance_checks": {
    "every_input_root_indexed": true,
    "every_root_has_classification": true,
    "no_reachable_function_gaps": true,
    "dynamic_callback_unresolved_gaps": true,
    "structural_verifier_passed": true
  },
  "interpretation": {
    "static_candidate_complete": "Every input root has source-level evidence or an explicitly named candidate/no-op classification.",
    "runtime_confirmation": "This does not prove server branches, runtime object identity, dynamic inheritance dispatch, or actual device activation. Stage three must replay each interaction and compare traces."
  },
  "handoff_priorities": [
    "direct_wrapper_effect_unresolved_target: verify target object/config instance and branch conditions",
    "dynamic_forwarding_candidate: verify receiver type and method dispatch",
    "dynamic_callback_candidate_linked: propagate callback closure/config argument",
    "dynamic_callback_effect_candidate: confirm field assignment order and active callback lifetime"
  ]
}
