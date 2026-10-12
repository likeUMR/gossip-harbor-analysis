"""Check stage-two index integrity and source-location coverage."""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
STAGE2 = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def integrity(path):
    db = sqlite3.connect(path)
    result = db.execute("PRAGMA integrity_check").fetchone()[0]
    db.close()
    return result


def main():
    errors = []
    modules = load_json(INDEX / "lua_modules.json")
    android_classes = load_json(INDEX / "android_classes.json")
    android_methods = load_json(INDEX / "android_methods.json")
    lua_functions = load_json(INDEX / "lua_functions.json")
    lua_validation = load_json(INDEX / "lua_validation_summary.json")
    source_states = {"available": 0, "missing": [], "unreadable": []}
    line_counts = {}
    for module in modules:
        source = ROOT / module.get("source_path", "")
        if not source.is_file():
            source_states["missing"].append(module.get("name", ""))
            continue
        try:
            line_counts[module.get("source_path", "")] = len(source.read_text(encoding="utf-8").splitlines())
            source_states["available"] += 1
        except (OSError, UnicodeError):
            source_states["unreadable"].append(module.get("name", ""))

    main_db_path = STAGE2 / "logic_index.sqlite3"
    lua_db_path = STAGE2 / "lua_relations.sqlite3"
    state_db_path = STAGE2 / "state_config_access.sqlite3"
    il2cpp_db_path = STAGE2 / "il2cpp_native.sqlite3"
    trigger_db_path = STAGE2 / "interaction_triggers.sqlite3"
    event_db_path = STAGE2 / "event_graph.sqlite3"
    input_db_path = STAGE2 / "input_entries.sqlite3"
    input_paths_db_path = STAGE2 / "input_paths.sqlite3"
    reachability_db_path = STAGE2 / "input_call_reachability.sqlite3"
    bridge_db_path = STAGE2 / "lua_bridge.sqlite3"
    network_db_path = STAGE2 / "network_calls.sqlite3"
    network_effects_db_path = STAGE2 / "network_callback_effects.sqlite3"
    named_callbacks_db_path = STAGE2 / "named_network_callbacks.sqlite3"
    assignment_db_path = STAGE2 / "callback_assignments.sqlite3"
    random_db_path = STAGE2 / "random_mechanisms.sqlite3"
    weight_db_path = STAGE2 / "weight_config.sqlite3"
    semantic_db_path = STAGE2 / "semantic_coverage.sqlite3"
    dynamic_callback_db_path = STAGE2 / "dynamic_callbacks.sqlite3"
    state_mutations_db_path = STAGE2 / "state_mutations.sqlite3"
    dynamic_callback_effects_db_path = STAGE2 / "dynamic_callback_effects.sqlite3"
    dynamic_wrapper_effects_db_path = STAGE2 / "dynamic_wrapper_effects.sqlite3"
    dynamic_forwarding_db_path = STAGE2 / "dynamic_forwarding.sqlite3"
    for path in (main_db_path, lua_db_path, state_db_path, il2cpp_db_path, trigger_db_path, event_db_path, input_db_path, input_paths_db_path, reachability_db_path, bridge_db_path, network_db_path, network_effects_db_path, named_callbacks_db_path, assignment_db_path, random_db_path, weight_db_path, semantic_db_path, dynamic_callback_db_path, state_mutations_db_path, dynamic_callback_effects_db_path, dynamic_wrapper_effects_db_path, dynamic_forwarding_db_path):
        if not path.is_file():
            errors.append(f"missing database: {path}")
        elif integrity(path) != "ok":
            errors.append(f"integrity check failed: {path}")

    main = sqlite3.connect(main_db_path) if main_db_path.is_file() else None
    main_counts = {}
    if main:
        main_counts = dict(main.execute("SELECT kind, count(*) FROM entities GROUP BY kind"))
        expected = {
            "lua_module": len(modules), "lua_prototype": len(lua_functions),
            "android_class": len(android_classes), "android_method": len(android_methods),
        }
        for kind, count in expected.items():
            if main_counts.get(kind, 0) != count:
                errors.append(f"{kind} count mismatch: database={main_counts.get(kind, 0)}, source={count}")
        unresolved = main.execute("SELECT layer, category, count(*) FROM unresolved GROUP BY layer, category").fetchall()
        edge_counts = dict(main.execute("SELECT kind, count(*) FROM edges GROUP BY kind"))
        main.close()
    else:
        unresolved, edge_counts = [], {}

    lua_counts = {}
    state_config_counts = {}
    il2cpp_native_counts = {}
    trigger_counts = {}
    event_counts = {}
    input_counts = {}
    input_path_counts = {}
    reachability_counts = {}
    bridge_counts = {}
    network_counts = {}
    network_effect_counts = {}
    named_callback_counts = {}
    assignment_counts = {}
    random_counts = {}
    weight_counts = {}
    semantic_counts = {}
    dynamic_callback_counts = {}
    state_mutation_counts = {}
    dynamic_callback_effect_counts = {}
    dynamic_wrapper_effect_counts = {}
    dynamic_forwarding_counts = {}
    bad_locations = []
    if lua_db_path.is_file():
        lua = sqlite3.connect(lua_db_path)
        lua_counts["functions"] = lua.execute("SELECT count(*) FROM functions").fetchone()[0]
        lua_counts["relations"] = lua.execute("SELECT count(*) FROM relations").fetchone()[0]
        lua_counts["unresolved"] = lua.execute("SELECT count(*) FROM unresolved").fetchone()[0]
        for source_path, line in lua.execute("SELECT source_path, line FROM relations"):
            if source_path not in line_counts or line < 1 or line > line_counts[source_path]:
                bad_locations.append({"source_path": source_path, "line": line})
        lua.close()
    if state_db_path.is_file():
        state_db = sqlite3.connect(state_db_path)
        state_config_counts["access_sites"] = state_db.execute("SELECT count(*) FROM access_sites").fetchone()[0]
        state_config_counts["unresolved"] = state_db.execute("SELECT count(*) FROM unresolved").fetchone()[0]
        state_config_counts["by_kind"] = dict(state_db.execute(
            "SELECT access_kind,count(*) FROM access_sites GROUP BY access_kind"))
        for source_path, line in state_db.execute("SELECT source_path,line FROM access_sites"):
            if source_path not in line_counts or line < 1 or line > line_counts[source_path]:
                bad_locations.append({"source_path": source_path, "line": line, "index": "state_config_access"})
        state_db.close()
    if trigger_db_path.is_file():
        trigger_db = sqlite3.connect(trigger_db_path)
        trigger_counts["rows"] = trigger_db.execute("SELECT count(*) FROM triggers").fetchone()[0]
        trigger_counts["by_kind"] = dict(trigger_db.execute(
            "SELECT trigger_kind,count(*) FROM triggers GROUP BY trigger_kind"))
        for source_path, line in trigger_db.execute("SELECT source_path,line FROM triggers"):
            if source_path not in line_counts or line < 1 or line > line_counts[source_path]:
                bad_locations.append({"source_path": source_path, "line": line, "index": "interaction_triggers"})
        trigger_db.close()
    if event_db_path.is_file():
        event_db = sqlite3.connect(event_db_path)
        event_counts["sites"] = event_db.execute("SELECT count(*) FROM event_sites").fetchone()[0]
        event_counts["event_names"] = event_db.execute(
            "SELECT count(DISTINCT event_name) FROM event_sites WHERE event_name IS NOT NULL").fetchone()[0]
        event_counts["by_operation"] = dict(event_db.execute(
            "SELECT operation,count(*) FROM event_sites GROUP BY operation"))
        event_counts["unresolved"] = event_db.execute("SELECT count(*) FROM unresolved").fetchone()[0]
        for source_path, line in event_db.execute("SELECT source_path,line FROM event_sites"):
            if source_path not in line_counts or line < 1 or line > line_counts[source_path]:
                bad_locations.append({"source_path": source_path, "line": line, "index": "event_graph"})
        event_db.close()
        coverage_path = REPORT / "stage2_event_coverage.json"
        if not coverage_path.is_file():
            errors.append("missing event coverage matrix")
        else:
            coverage = load_json(coverage_path)
            static_event_names = event_db_counts = event_counts.get("event_names")
            if static_event_names is not None and coverage.get("event_names") != static_event_names:
                errors.append("event coverage matrix event count does not match event graph")
    if input_db_path.is_file():
        input_db = sqlite3.connect(input_db_path)
        input_counts["entries"] = input_db.execute("SELECT count(*) FROM entries").fetchone()[0]
        input_counts["by_kind"] = dict(input_db.execute(
            "SELECT entry_kind,count(*) FROM entries GROUP BY entry_kind"))
        for source_path, line in input_db.execute("SELECT source_path,line FROM entries"):
            if source_path not in line_counts or line < 1 or line > line_counts[source_path]:
                bad_locations.append({"source_path": source_path, "line": line, "index": "input_entries"})
        input_db.close()
    if input_paths_db_path.is_file():
        input_paths_db = sqlite3.connect(input_paths_db_path)
        input_path_counts["paths"] = input_paths_db.execute("SELECT count(*) FROM paths").fetchone()[0]
        input_path_counts["paths_with_downstream_evidence"] = input_paths_db.execute(
            "SELECT count(*) FROM paths WHERE classification!='no_downstream_static_evidence'").fetchone()[0]
        input_path_counts["items"] = input_paths_db.execute("SELECT count(*) FROM path_items").fetchone()[0]
        input_paths_db.close()
    if reachability_db_path.is_file():
        reachability_db = sqlite3.connect(reachability_db_path)
        reachability_counts["roots"] = reachability_db.execute("SELECT count(*) FROM roots").fetchone()[0]
        reachability_counts["reachable_rows"] = reachability_db.execute("SELECT count(*) FROM reachable").fetchone()[0]
        reachability_counts["roots_with_event_reachable"] = reachability_db.execute(
            "SELECT count(DISTINCT root_id) FROM reachable WHERE has_event=1").fetchone()[0]
        reachability_counts["roots_with_state_reachable"] = reachability_db.execute(
            "SELECT count(DISTINCT root_id) FROM reachable WHERE has_state=1").fetchone()[0]
        reachability_db.close()
    if bridge_db_path.is_file():
        bridge_db = sqlite3.connect(bridge_db_path)
        bridge_counts["rows"] = bridge_db.execute("SELECT count(*) FROM bridges").fetchone()[0]
        bridge_counts["by_certainty"] = dict(bridge_db.execute(
            "SELECT certainty,count(*) FROM bridges GROUP BY certainty"))
        bridge_db.close()
    if network_db_path.is_file():
        network_db = sqlite3.connect(network_db_path)
        network_counts["calls"] = network_db.execute("SELECT count(*) FROM calls").fetchone()[0]
        network_counts["request_names"] = network_db.execute(
            "SELECT count(DISTINCT request_name) FROM calls WHERE request_name!=''").fetchone()[0]
        network_counts["by_callback_shape"] = dict(network_db.execute(
            "SELECT callback_shape,count(*) FROM calls GROUP BY callback_shape"))
        network_db.close()
    if network_effects_db_path.is_file():
        network_effects_db = sqlite3.connect(network_effects_db_path)
        network_effect_counts["callbacks"] = network_effects_db.execute("SELECT count(*) FROM callbacks").fetchone()[0]
        network_effect_counts["effects"] = network_effects_db.execute("SELECT count(*) FROM effects").fetchone()[0]
        network_effect_counts["unresolved"] = network_effects_db.execute("SELECT count(*) FROM unresolved").fetchone()[0]
        network_effects_db.close()
    if named_callbacks_db_path.is_file():
        named_callbacks_db = sqlite3.connect(named_callbacks_db_path)
        named_callback_counts["expressions"] = named_callbacks_db.execute("SELECT count(*) FROM callbacks").fetchone()[0]
        named_callback_counts["effects"] = named_callbacks_db.execute("SELECT count(*) FROM effects").fetchone()[0]
        named_callback_counts["by_certainty"] = dict(named_callbacks_db.execute(
            "SELECT certainty,count(*) FROM callbacks GROUP BY certainty"))
        named_callbacks_db.close()
    if assignment_db_path.is_file():
        assignment_db = sqlite3.connect(assignment_db_path)
        assignment_counts["assignments"] = assignment_db.execute("SELECT count(*) FROM assignments").fetchone()[0]
        assignment_counts["resolved_call_arguments"] = assignment_db.execute(
            "SELECT count(*) FROM resolved_calls").fetchone()[0]
        assignment_counts["by_certainty"] = dict(assignment_db.execute(
            "SELECT certainty,count(*) FROM resolved_calls GROUP BY certainty"))
        assignment_db.close()
    if random_db_path.is_file():
        random_db = sqlite3.connect(random_db_path)
        random_counts["mechanisms"] = random_db.execute("SELECT count(*) FROM mechanisms").fetchone()[0]
        random_counts["config_fields"] = random_db.execute("SELECT count(*) FROM config_fields").fetchone()[0]
        random_counts["by_kind"] = dict(random_db.execute(
            "SELECT mechanism_kind,count(*) FROM mechanisms GROUP BY mechanism_kind"))
        random_counts["by_replacement_status"] = dict(random_db.execute(
            "SELECT replacement_status,count(*) FROM mechanisms GROUP BY replacement_status"))
        random_counts["explicit_candidate_removals"] = random_db.execute(
            "SELECT count(*) FROM mechanisms WHERE removal_evidence='explicit_table_remove'").fetchone()[0]
        random_db.close()
    else:
        errors.append("missing random mechanisms index")
    if weight_db_path.is_file():
        weight_db = sqlite3.connect(weight_db_path)
        weight_counts["assignments"] = weight_db.execute("SELECT count(*) FROM assignments").fetchone()[0]
        weight_counts["selections"] = weight_db.execute("SELECT count(*) FROM selections").fetchone()[0]
        weight_counts["groups"] = weight_db.execute("SELECT count(*) FROM groups").fetchone()[0]
        weight_counts["zero_values"] = weight_db.execute("SELECT count(*) FROM assignments WHERE numeric_value=0").fetchone()[0]
        weight_counts["negative_values"] = weight_db.execute("SELECT count(*) FROM assignments WHERE numeric_value<0").fetchone()[0]
        weight_db.close()
    else:
        errors.append("missing weight configuration index")
    if semantic_db_path.is_file():
        semantic_db = sqlite3.connect(semantic_db_path)
        semantic_counts["roots"] = semantic_db.execute("SELECT count(*) FROM root_coverage").fetchone()[0]
        semantic_counts["by_class"] = dict(semantic_db.execute("SELECT evidence_class,count(*) FROM root_coverage GROUP BY evidence_class"))
        for key,column in (("with_event","has_event"),("with_state","has_state"),("with_network","has_network"),("with_bridge","has_bridge"),("with_random","has_random"),("with_config","has_config")):
            semantic_counts[key] = semantic_db.execute(f"SELECT count(*) FROM root_coverage WHERE {column}=1").fetchone()[0]
        semantic_db.close()
        gap_path = REPORT / "stage2_semantic_gaps.json"
        if not gap_path.is_file():
            errors.append("missing semantic gaps report")
        else:
            gaps = load_json(gap_path)
            non_effect = semantic_counts["roots"] - semantic_counts["by_class"].get("downstream_effect_evidence", 0)
            if len(gaps) != non_effect:
                errors.append("semantic gaps report count does not match coverage matrix")
    else:
        errors.append("missing semantic coverage matrix")
    if dynamic_callback_db_path.is_file():
        dynamic_db = sqlite3.connect(dynamic_callback_db_path)
        dynamic_callback_counts["calls"] = dynamic_db.execute("SELECT count(*) FROM calls").fetchone()[0]
        dynamic_callback_counts["assignments"] = dynamic_db.execute("SELECT count(*) FROM assignments").fetchone()[0]
        dynamic_callback_counts["links"] = dynamic_db.execute("SELECT count(*) FROM links").fetchone()[0]
        dynamic_callback_counts["unlinked_calls"] = dynamic_db.execute("SELECT count(*) FROM calls c WHERE NOT EXISTS(SELECT 1 FROM links l WHERE l.call_id=c.id)").fetchone()[0]
        dynamic_db.close()
    else:
        errors.append("missing dynamic callback index")
    if state_mutations_db_path.is_file():
        mutation_db = sqlite3.connect(state_mutations_db_path)
        state_mutation_counts["mutations"] = mutation_db.execute("SELECT count(*) FROM mutations").fetchone()[0]
        state_mutation_counts["self_mutations"] = mutation_db.execute("SELECT count(*) FROM mutations WHERE mutation_kind='object_field_assignment'").fetchone()[0]
        state_mutation_counts["global_model_mutations"] = mutation_db.execute("SELECT count(*) FROM mutations WHERE mutation_kind='global_model_assignment'").fetchone()[0]
        mutation_db.close()
    else:
        errors.append("missing direct state mutation index")
    if dynamic_callback_effects_db_path.is_file():
        effect_db = sqlite3.connect(dynamic_callback_effects_db_path)
        dynamic_callback_effect_counts["definitions"] = effect_db.execute("SELECT count(*) FROM definitions").fetchone()[0]
        dynamic_callback_effect_counts["effects"] = effect_db.execute("SELECT count(*) FROM effects").fetchone()[0]
        dynamic_callback_effect_counts["links"] = effect_db.execute("SELECT count(*) FROM links").fetchone()[0]
        effect_db.close()
    else:
        errors.append("missing dynamic callback effects index")
    if dynamic_wrapper_effects_db_path.is_file():
        wrapper_db = sqlite3.connect(dynamic_wrapper_effects_db_path)
        dynamic_wrapper_effect_counts = {
            "wrappers": wrapper_db.execute("SELECT count(*) FROM wrappers").fetchone()[0],
            "effects": wrapper_db.execute("SELECT count(*) FROM effects").fetchone()[0],
            "dynamic_calls": wrapper_db.execute("SELECT count(*) FROM dynamic_calls").fetchone()[0],
        }
        wrapper_db.close()
    else:
        errors.append("missing dynamic wrapper effects index")
    if dynamic_forwarding_db_path.is_file():
        forwarding_db = sqlite3.connect(dynamic_forwarding_db_path)
        dynamic_forwarding_counts = {
            "functions": forwarding_db.execute("SELECT count(*) FROM functions").fetchone()[0],
            "assignments": forwarding_db.execute("SELECT count(*) FROM assignments").fetchone()[0],
            "calls": forwarding_db.execute("SELECT count(*) FROM calls").fetchone()[0],
            "links": forwarding_db.execute("SELECT count(*) FROM links").fetchone()[0],
        }
        forwarding_db.close()
    else:
        errors.append("missing dynamic forwarding index")
    il2cpp_summary_path = REPORT / "stage2_il2cpp_native_index_summary.json"
    if il2cpp_db_path.is_file():
        il2cpp = sqlite3.connect(il2cpp_db_path)
        il2cpp_native_counts = {
            "methods": il2cpp.execute("SELECT count(*) FROM methods").fetchone()[0],
            "methods_mapped_to_function_start": il2cpp.execute(
                "SELECT count(*) FROM methods WHERE mapping_status='mapped_to_native_function_start'").fetchone()[0],
            "native_function_entries": il2cpp.execute("SELECT count(*) FROM native_functions").fetchone()[0],
            "native_functions_with_disassembly": il2cpp.execute(
                "SELECT count(*) FROM native_functions WHERE disassembly_status='indexed'").fetchone()[0],
            "direct_calls": il2cpp.execute("SELECT count(*) FROM direct_calls").fetchone()[0],
            "direct_calls_to_method_entry": il2cpp.execute(
                "SELECT count(*) FROM direct_calls WHERE target_status='mapped_method'").fetchone()[0],
        }
        il2cpp.close()
        if il2cpp_summary_path.is_file():
            il2cpp_report = load_json(il2cpp_summary_path)
            dumper_run_path = REPORT / "stage2_il2cpp_dumper_run.json"
            if not dumper_run_path.is_file():
                errors.append("missing reproducible Il2CppDumper run report")
            else:
                dumper_run = load_json(dumper_run_path)
                if dumper_run.get("status") != "pass":
                    errors.append("Il2CppDumper run did not pass")
                if dumper_run.get("method_count") != il2cpp_report.get("method_map", {}).get("methods"):
                    errors.append("Il2CppDumper method count does not match native index")
                if dumper_run.get("binary_sha256") != il2cpp_report.get("inputs", {}).get("binary_sha256"):
                    errors.append("Il2CppDumper binary hash does not match native index input")
                if dumper_run.get("method_map_sha256") != il2cpp_report.get("inputs", {}).get("method_map_sha256"):
                    errors.append("Il2CppDumper method-map hash does not match native index input")
            method_total = il2cpp_report.get("method_map", {}).get("methods")
            if il2cpp_native_counts["methods"] != method_total:
                errors.append("IL2CPP method rows do not match native index summary")
            if il2cpp_native_counts["methods_mapped_to_function_start"] != method_total:
                errors.append("one or more IL2CPP methods do not map to a native function entry")
            if il2cpp_native_counts["native_functions_with_disassembly"] != il2cpp_native_counts["native_function_entries"]:
                errors.append("one or more native function entries lack disassembly evidence")
        else:
            errors.append("missing IL2CPP native index summary")
    if bad_locations:
        errors.append(f"Lua relation locations outside readable source files: {len(bad_locations)}")

    test_inventory = load_json(REPORT / "test_framework_inventory.json")
    test_modules = [m for m in modules if m.get("category") == "test_debug" or m.get("name", "").startswith("Test.")]
    if test_inventory.get("module_count") != len(test_modules):
        errors.append("test framework module count does not match Lua module inventory")
    test_counts = {
        "modules": test_inventory.get("module_count", 0),
        "button_definitions": len(test_inventory.get("button_definitions", [])),
        "button_configurations": len(test_inventory.get("button_configurations", [])),
        "commands": len(test_inventory.get("commands", [])),
        "button_reference_resolution": test_inventory.get("button_reference_resolution_counts", {}),
        "button_handler_resolution": test_inventory.get("button_handler_resolution_counts", {}),
    }
    if test_counts["button_definitions"] != test_inventory.get("button_definition_count"):
        errors.append("test button definition count does not match indexed records")
    if test_counts["button_configurations"] != test_inventory.get("configured_button_reference_count"):
        errors.append("test button configuration count does not match indexed records")
    if test_counts["commands"] != test_inventory.get("test_command_count"):
        errors.append("test command count does not match indexed records")

    semantic_status = "not_certified"
    if semantic_counts.get("roots", 0) == len({r.get("root_id") for r in load_json(REPORT / "stage2_semantic_gaps.json")}) + semantic_counts.get("by_class", {}).get("downstream_effect_evidence", 0):
        unresolved_classes = {"dynamic_callback_unresolved", "no_reachable_function", "logic_only_no_indexed_effect"}
        if not (unresolved_classes & set(semantic_counts.get("by_class", {}))):
            semantic_status = "static_candidate_complete_runtime_unverified"
    result = {
        "title": "Stage-two index structural verification",
        "structural_status": "pass" if not errors else "fail",
        "semantic_coverage_status": semantic_status,
        "errors": errors,
        "lua_modules": len(modules), "lua_source_available": source_states["available"],
        "lua_source_missing": len(source_states["missing"]), "lua_source_unreadable": len(source_states["unreadable"]),
        "lua_parse_status": {value: sum(row.get("parse_status") == value for row in modules)
                              for value in sorted({row.get("parse_status", "unknown") for row in modules})},
        "lua_decompile_status": {value: sum(row.get("decompile_status") == value for row in modules)
                                 for value in sorted({row.get("decompile_status", "unknown") for row in modules})},
        "lua_roundtrip_validation": lua_validation,
        "main_entity_counts": main_counts, "main_edge_counts": edge_counts,
        "main_unresolved_counts": [dict(zip(("layer", "category", "count"), row)) for row in unresolved],
        "lua_relation_counts": lua_counts, "state_config_access_counts": state_config_counts,
        "interaction_trigger_counts": trigger_counts,
        "event_graph_counts": event_counts,
        "input_entry_counts": input_counts,
        "input_path_counts": input_path_counts,
        "input_call_reachability_counts": reachability_counts,
        "lua_bridge_counts": bridge_counts,
        "network_call_counts": network_counts,
        "network_callback_effect_counts": network_effect_counts,
        "named_network_callback_counts": named_callback_counts,
        "callback_assignment_counts": assignment_counts,
        "random_mechanism_counts": random_counts,
        "weight_config_counts": weight_counts,
        "semantic_coverage_counts": semantic_counts,
        "dynamic_callback_counts": dynamic_callback_counts,
        "state_mutation_counts": state_mutation_counts,
        "dynamic_callback_effect_counts": dynamic_callback_effect_counts,
        "dynamic_wrapper_effect_counts": dynamic_wrapper_effect_counts,
        "dynamic_forwarding_counts": dynamic_forwarding_counts,
        "il2cpp_native_counts": il2cpp_native_counts,
        "invalid_relation_locations": bad_locations[:30],
        "test_module_count": len(test_modules), "test_framework_counts": test_counts,
        "database_integrity": {path.name: integrity(path) for path in (main_db_path, lua_db_path, state_db_path, il2cpp_db_path, trigger_db_path, event_db_path, input_db_path, input_paths_db_path, reachability_db_path, bridge_db_path, network_db_path, network_effects_db_path, named_callbacks_db_path, assignment_db_path, random_db_path, weight_db_path, semantic_db_path, dynamic_callback_db_path, state_mutations_db_path, dynamic_callback_effects_db_path, dynamic_wrapper_effects_db_path, dynamic_forwarding_db_path) if path.is_file()},
        "interpretation": "A structural pass verifies counts, database integrity, and evidence locations only. It does not validate decompilation semantics, dynamic targets, runtime activation, configuration variants, state lifecycles, or full behavior coverage.",
    }
    (REPORT / "stage2_structural_verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
