"""Index Lua configuration, preference, database-table, and model API access sites."""
from __future__ import annotations

import bisect
import collections
import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
OUT = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"
FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(", re.M)
METHOD_RE = re.compile(
    r"(?:(?P<receiver>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*[:.]\s*)?"
    r"(?P<method>GetServerConfigMD5|GetServerConfigEntries|GetServerConfig|GetGeneralConfByType|IsServerControlOpen|"
    r"GetLocalConfig|GetRemoteConfig|GetSystemConfig|GetConfig|"
    r"GetInt|GetString|GetFloat|GetBool|SetInt|SetString|SetFloat|SetBool|"
    r"GetValue|Set|Remove|Clear|Save)\s*\("
)
MODEL_METHOD_RE = re.compile(r"^(?:Get|Is|Has|Can|Check|Set|Add|Sub|Remove|Clear|Reset|Restore|Save|Sync|Acquire|Consume|Use|Update|Finish|Unlock|Create|Delete|Open|Close|Start|Stop|Complete|Claim|Collect|Refresh)")
NONCODE_RE = re.compile(
    r"--\[(=*)\[.*?\]\1\]|--[^\r\n]*|\"(?:\\.|[^\"\\])*\"|"
    r"'(?:\\.|[^'\\])*'|\[(=*)\[.*?\]\2\]", re.S)


def stable_id(*parts):
    return hashlib.sha256("\0".join(map(str, parts)).encode("utf-8")).hexdigest()


def mask_noncode(source: str) -> str:
    """Blank Lua strings/comments while preserving offsets and newlines."""
    return NONCODE_RE.sub(lambda match: "".join("\n" if char == "\n" else " " for char in match.group()), source)


def matching_paren(masked: str, open_pos: int):
    depth = 0
    for i in range(open_pos, len(masked)):
        if masked[i] == "(":
            depth += 1
        elif masked[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return None


def split_arguments(raw: str, masked: str):
    args, start = [], 0
    paren = bracket = brace = 0
    for i, char in enumerate(masked):
        if char == "(": paren += 1
        elif char == ")": paren -= 1
        elif char == "[": bracket += 1
        elif char == "]": bracket -= 1
        elif char == "{": brace += 1
        elif char == "}": brace -= 1
        elif char == "," and paren == bracket == brace == 0:
            args.append(raw[start:i].strip())
            start = i + 1
    tail = raw[start:].strip()
    if tail or raw.strip():
        args.append(tail)
    return args


def line_at(line_starts, offset: int):
    return bisect.bisect_right(line_starts, offset)


def function_at(definitions, offsets, call_offset):
    position = bisect.bisect_right(offsets, call_offset) - 1
    return definitions[position] if position >= 0 else None


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    out_path = OUT / "state_config_access.sqlite3"
    if out_path.exists():
        out_path.unlink()
    db = sqlite3.connect(out_path)
    db.executescript("""
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        CREATE TABLE access_sites (
            id TEXT PRIMARY KEY, module TEXT NOT NULL, module_sha256 TEXT NOT NULL,
            function_id TEXT, function_symbol TEXT, source_path TEXT NOT NULL,
            line INTEGER NOT NULL, access_kind TEXT NOT NULL, operation TEXT NOT NULL,
            receiver TEXT, member TEXT NOT NULL, key_expression TEXT, key_value TEXT,
            arguments_json TEXT NOT NULL, certainty TEXT NOT NULL,
            code_excerpt TEXT NOT NULL
        );
        CREATE TABLE unresolved (
            id INTEGER PRIMARY KEY, module TEXT NOT NULL, source_path TEXT NOT NULL,
            line INTEGER NOT NULL, access_kind TEXT NOT NULL, expression TEXT NOT NULL,
            reason TEXT NOT NULL
        );
        CREATE INDEX access_kind_op ON access_sites(access_kind, operation);
        CREATE INDEX access_module_line ON access_sites(module, line);
        CREATE INDEX access_key ON access_sites(key_expression);
        CREATE INDEX access_function ON access_sites(function_id);
    """)

    modules = json.loads((INDEX / "lua_modules.json").read_text(encoding="utf-8"))
    config_key_maps = collections.defaultdict(dict)
    key_source_by_table = {
        "LocalConfigKey": "Model.ConfigModel",
        "ServerConfigKey": "Model.ConfigModel",
        "EGeneralConfType": "Model.ConfigModel",
        "EPlayerPrefKey": "Model.UserData.UserDataKey",
        "SystemConfigKey": "Model.SystemConfigModel",
        "UIPrefabConfigName": "Data.AssetName.UIPrefabConfigName",
        "ScenePrefabConfigName": "Data.AssetName.ScenePrefabConfigName",
    }
    module_by_name = {module.get("name"): module for module in modules}
    for table_name, module_name in key_source_by_table.items():
        source_module = module_by_name.get(module_name)
        if not source_module or not source_module.get("source_path"):
            continue
        table_source = (ROOT / source_module["source_path"]).read_text(encoding="utf-8")
        table_match = re.search(r"^" + re.escape(table_name) + r"\s*=\s*\{(.*?)^\}", table_source, re.M | re.S)
        if not table_match:
            continue
        for key_match in re.finditer(r'^\s*([A-Za-z_]\w*)\s*=\s*"((?:\\.|[^"])*)"', table_match.group(1), re.M):
            value = re.sub(r"\\(\d{3})", lambda match: chr(int(match.group(1))), key_match.group(2))
            value = value.replace(r"\"", '"').replace(r"\\", "\\")
            config_key_maps[table_name][key_match.group(1)] = value
    module_states = collections.Counter()
    counts = collections.Counter()
    operations = collections.Counter()
    key_kinds = collections.Counter()
    key_resolution_counts = collections.Counter()
    emitted = set()

    for module in modules:
        source_path = module.get("source_path", "")
        full_path = ROOT / source_path
        if not full_path.is_file():
            module_states["missing"] += 1
            continue
        try:
            source = full_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            module_states["unreadable"] += 1
            continue
        module_states["available"] += 1
        masked = mask_noncode(source)
        line_starts = [0] + [i + 1 for i, char in enumerate(source) if char == "\n"]
        definitions = []
        for match in FUNCTION_RE.finditer(masked):
            symbol = match.group(1)
            line = line_at(line_starts, match.start())
            fid = stable_id(module.get("sha256", ""), symbol, line)
            definitions.append((match.start(), fid, symbol))
        def_offsets = [item[0] for item in definitions]

        for match in METHOD_RE.finditer(masked):
            receiver = match.group("receiver") or ""
            method = match.group("method")
            open_pos = match.end() - 1
            close_pos = matching_paren(masked, open_pos)
            if close_pos is None:
                db.execute("INSERT INTO unresolved (module,source_path,line,access_kind,expression,reason) VALUES (?,?,?,?,?,?)",
                           (module.get("name", ""), source_path, line_at(line_starts, match.start()), "call_arguments",
                            match.group(0), "未匹配到调用闭括号"))
                continue
            raw_args = source[open_pos + 1:close_pos]
            masked_args = masked[open_pos + 1:close_pos]
            args = split_arguments(raw_args, masked_args)
            low_receiver = receiver.lower()
            kind = None
            operation = None
            key_expr = args[0] if args else ""
            certainty = "source_call_candidate"
            if receiver == "PlayerPrefs" and method in {"GetInt", "GetString", "GetFloat", "GetBool", "SetInt", "SetString", "SetFloat", "SetBool"}:
                kind = "player_prefs"
                operation = "read" if method.startswith("Get") else "write"
            elif method == "GetConfig" and any(name in receiver for name in ("UIPrefabConfig", "ScenePrefabConfig")):
                kind = "resource_config_read"
                operation = "resource_key_lookup"
            elif method in {"GetServerConfig", "GetLocalConfig", "GetRemoteConfig", "GetSystemConfig", "GetConfig"} and (
                    method in {"GetServerConfig", "GetRemoteConfig", "GetSystemConfig"} or
                    method == "GetLocalConfig" and bool(args) and "config" in low_receiver or
                    method == "GetConfig" and "config" in low_receiver):
                kind = "configuration_read"
                operation = method.removeprefix("Get").lower() + "_read"
            elif method in {"GetServerConfigMD5", "GetServerConfigEntries", "GetGeneralConfByType", "IsServerControlOpen"}:
                kind = "configuration_control_or_metadata"
                operation = "flag_or_metadata_read"
            elif method in {"GetLocalConfig", "GetRemoteConfig", "GetSystemConfig", "GetConfig"}:
                kind = "model_config_accessor"
                operation = "read_candidate"
            elif "dbtable" in low_receiver and method in {"GetValue", "Set", "Remove", "Clear", "Save"}:
                kind = "database_table"
                operation = {"GetValue": "read", "Set": "write", "Remove": "remove", "Clear": "clear", "Save": "save"}[method]
            elif (receiver.startswith("GM.") or re.search(r"\.(?:m_model|m_dataModel|m_\w*Model)$", receiver)) and MODEL_METHOD_RE.match(method):
                kind = "model_api_candidate"
                operation = ("read_candidate" if method.startswith(("Get", "Is", "Has", "Can")) else
                             "write_candidate" if method.startswith(("Set", "Add", "Sub", "Remove", "Clear", "Reset", "Restore", "Save", "Sync", "Acquire", "Consume", "Use", "Finish", "Unlock", "Delete", "Claim", "Collect")) else "stateful_candidate")
            if kind is None:
                continue

            key_expr = key_expr.strip()
            key_value = ""
            key_ref = re.fullmatch(r"(LocalConfigKey|ServerConfigKey|EGeneralConfType|EPlayerPrefKey|SystemConfigKey|UIPrefabConfigName|ScenePrefabConfigName)\.([A-Za-z_]\w*)", key_expr)
            if key_ref:
                key_value = config_key_maps.get(key_ref.group(1), {}).get(key_ref.group(2), "")
                key_resolution_counts["resolved" if key_value else "unresolved"] += 1
            if kind in {"configuration_read", "configuration_control_or_metadata"}:
                if re.search(r"(?:Local|Remote|System)ConfigKey\.", key_expr):
                    key_kind = "named_config_key"
                elif re.search(r"(?:ServerConfigKey|SystemConfigKey|EGeneralConfType)\.", key_expr):
                    key_kind = "named_server_key_or_flag"
                elif key_expr:
                    key_kind = "dynamic_or_expression"
                else:
                    key_kind = "missing_argument"
            elif kind == "resource_config_read":
                key_kind = "named_resource_key" if re.search(r"(?:UIPrefabConfigName|ScenePrefabConfigName)\.", key_expr) else "computed_resource_key"
            elif kind == "player_prefs":
                key_kind = "literal_string" if key_expr.startswith(("\"", "'")) else "named_or_dynamic_key"
            else:
                key_kind = "first_argument_candidate" if key_expr else "no_argument"
            key_kinds[(kind, key_kind)] += 1

            function = function_at(definitions, def_offsets, match.start())
            function_id, function_symbol = (function[1], function[2]) if function else (None, None)
            line = line_at(line_starts, match.start())
            excerpt_start = source.rfind("\n", 0, match.start()) + 1
            excerpt_end = source.find("\n", close_pos)
            excerpt_end = len(source) if excerpt_end < 0 else excerpt_end
            excerpt = source[excerpt_start:excerpt_end].strip()[:600]
            access_id = stable_id(module.get("sha256", ""), line, kind, receiver, method, key_expr)
            if access_id in emitted:
                continue
            emitted.add(access_id)
            db.execute("INSERT INTO access_sites VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (
                access_id, module.get("name", ""), module.get("sha256", ""), function_id, function_symbol,
                source_path, line, kind, operation, receiver, method, key_expr, key_value,
                json.dumps(args, ensure_ascii=False, separators=(",", ":")), certainty, excerpt))
            if key_ref and not key_value:
                db.execute("INSERT INTO unresolved (module,source_path,line,access_kind,expression,reason) VALUES (?,?,?,?,?,?)",
                           (module.get("name", ""), source_path, line, kind, key_expr,
                            "枚举键未在当前已恢复的键定义表中解析"))
            counts[kind] += 1
            operations[(kind, operation)] += 1
            if kind in {"configuration_read", "resource_config_read"} and key_kind in {"dynamic_or_expression", "computed_resource_key"}:
                db.execute("INSERT INTO unresolved (module,source_path,line,access_kind,expression,reason) VALUES (?,?,?,?,?,?)",
                           (module.get("name", ""), source_path, line, kind, key_expr,
                            "读取键为变量、资源名或表达式；需追踪赋值来源与运行时选择"))

    db.commit()
    by_kind = {row[0]: row[1] for row in db.execute("SELECT access_kind,count(*) FROM access_sites GROUP BY access_kind")}
    by_operation = {f"{row[0]}/{row[1]}": row[2] for row in db.execute(
        "SELECT access_kind,operation,count(*) FROM access_sites GROUP BY access_kind,operation")}
    summary = {
        "title": "阶段二 Lua 配置与状态访问候选索引",
        "modules_total": len(modules), "module_source_states": dict(module_states),
        "access_sites": by_kind, "operations": by_operation,
        "key_expression_kinds": {f"{kind}/{key_kind}": count for (kind, key_kind), count in sorted(key_kinds.items())},
        "key_definition_map_sizes": {table: len(values) for table, values in config_key_maps.items()},
        "enum_key_resolution": dict(key_resolution_counts),
        "unresolved_config_or_resource_key_expressions": db.execute(
            "SELECT count(*) FROM unresolved WHERE access_kind IN ('configuration_read','resource_config_read')").fetchone()[0],
        "database": str(out_path.relative_to(ROOT)).replace("\\", "/"),
        "limits": [
            "Access sites are lexical candidates; they do not establish which configuration variant is selected at runtime.",
            "Database table calls and model APIs need data-column and callee analysis to establish field-level state effects.",
            "The nearest preceding named function is a locator hint; nested closures may be attributed to the enclosing method.",
            "Read/write classification follows API names. Save, sync, server authority, migrations, resets, and restore paths remain to be traced.",
        ],
    }
    (REPORT / "stage2_state_config_access_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
