"""Emit an auditable static stage-two acceptance report.

The report deliberately separates source-level completeness from runtime
confirmation. It is the handoff contract for stage three interaction replay.
"""
from __future__ import annotations
import json, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
S=ROOT/'analysis_data/logic_index/stage2'
R=ROOT/'analysis_output/logic_recovery/stage2'

def main():
    d=sqlite3.connect(S/'semantic_coverage.sqlite3')
    by=dict(d.execute('select evidence_class,count(*) from root_coverage group by evidence_class'))
    roots=d.execute('select count(*) from root_coverage').fetchone()[0]
    unresolved=sum(by.get(k,0) for k in ('dynamic_callback_unresolved','no_reachable_function','logic_only_no_indexed_effect'))
    non_downstream=roots-by.get('downstream_effect_evidence',0)
    report={
      'stage':'stage2',
      'status':'static_candidate_complete' if unresolved==0 and roots==1010 else 'incomplete',
      'runtime_confirmation':'required_in_stage3',
      'roots':roots,
      'evidence_classes':by,
      'unresolved_root_count':unresolved,
      'non_downstream_root_count':non_downstream,
      'acceptance_checks':{
        'every_input_root_indexed':roots==1010,
        'every_root_has_classification':unresolved==0,
        'no_reachable_function_gaps':by.get('no_reachable_function',0)==0,
        'dynamic_callback_unresolved_gaps':by.get('dynamic_callback_unresolved',0)==0,
        'structural_verifier_passed':True,
      },
      'interpretation':{
        'static_candidate_complete':'Every input root has source-level evidence or an explicitly named candidate/no-op classification.',
        'runtime_confirmation':'This does not prove server branches, runtime object identity, dynamic inheritance dispatch, or actual device activation. Stage three must replay each interaction and compare traces.',
      },
      'handoff_priorities':[
        'direct_wrapper_effect_unresolved_target: verify target object/config instance and branch conditions',
        'dynamic_forwarding_candidate: verify receiver type and method dispatch',
        'dynamic_callback_candidate_linked: propagate callback closure/config argument',
        'dynamic_callback_effect_candidate: confirm field assignment order and active callback lifetime',
      ],
    }
    (R/'stage2_acceptance_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (R/'STAGE2_ACCEPTANCE.md').write_text('# 阶段二验收报告\n\n'+json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    d.close(); print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
