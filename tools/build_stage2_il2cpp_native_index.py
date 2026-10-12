"""Index IL2CPP method addresses and ARM64 assembly call sites."""
from __future__ import annotations

import hashlib
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "analysis_data" / "logic_index"
STAGE2 = INDEX / "stage2"
REPORT = ROOT / "analysis_output" / "logic_recovery" / "stage2"
INSN_RE = re.compile(r"^\s*([0-9a-fA-F]{8,16}):\s*(.*?)\s*$")
DIRECT_BL_RE = re.compile(r"^bl\s+#?(?:0x)?([0-9a-fA-F]+)\b", re.I)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    STAGE2.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    native_root = INDEX / "native"
    candidates = list(native_root.glob("*/index.json"))
    native_index = None
    for path in candidates:
        record = json.loads(path.read_text(encoding="utf-8"))
        if (record.get("machine") == "EM_AARCH64" and record.get("status") == "disassembled"
                and Path(record.get("path", "")).name == "libil2cpp.so"):
            native_index = record
            break
    if not native_index:
        raise SystemExit("No complete AArch64 native disassembly index found")

    binary = ROOT / native_index["path"]
    binary_hash = sha256(binary)
    method_script = STAGE2 / "il2cpp_dumper_run" / "script.json"
    metadata = ROOT / "apk_extract" / "gossip_harbor_3.98.10" / "base_extracted" / "assets" / "bin" / "Data" / "Managed" / "Metadata" / "global-metadata.dat"
    if not method_script.is_file() or not metadata.is_file():
        raise SystemExit("Run Il2CppDumper with this sample's libil2cpp.so and global-metadata.dat first")
    dumper_root = method_script.parent
    dumper_hash = sha256(method_script)
    dump = json.loads(method_script.read_text(encoding="utf-8"))
    method_rows = dump.get("ScriptMethod", [])
    function_starts = sorted(set(dump.get("Addresses", [])))
    methods_by_address: dict[int, list[dict]] = {}
    for method in method_rows:
        methods_by_address.setdefault(int(method["Address"]), []).append(method)
    starts_set = set(function_starts)
    starts_with_methods = set(methods_by_address)

    db_path = STAGE2 / "il2cpp_native.sqlite3"
    if db_path.exists():
        db_path.unlink()
    db = sqlite3.connect(db_path)
    db.executescript("""
        PRAGMA journal_mode=OFF;
        PRAGMA synchronous=OFF;
        CREATE TABLE native_functions (
            start_address INTEGER PRIMARY KEY, end_address INTEGER,
            assembly_path TEXT, start_line INTEGER, end_line INTEGER,
            assembly_text_byte_span INTEGER, instruction_count INTEGER NOT NULL DEFAULT 0,
            direct_call_count INTEGER NOT NULL DEFAULT 0,
            indirect_call_count INTEGER NOT NULL DEFAULT 0,
            disassembly_status TEXT NOT NULL DEFAULT 'missing'
        );
        CREATE TABLE methods (
            id INTEGER PRIMARY KEY, address INTEGER NOT NULL, name TEXT NOT NULL,
            signature TEXT, type_signature TEXT, native_function_start INTEGER,
            mapping_status TEXT NOT NULL
        );
        CREATE INDEX methods_name ON methods(name);
        CREATE INDEX methods_address ON methods(address);
        CREATE INDEX methods_function ON methods(native_function_start);
        CREATE TABLE direct_calls (
            id INTEGER PRIMARY KEY, caller_start INTEGER, caller_method_address INTEGER,
            caller_method_name TEXT, line INTEGER NOT NULL, instruction_address INTEGER NOT NULL,
            target_address INTEGER NOT NULL, target_method_name TEXT, target_status TEXT NOT NULL,
            assembly_path TEXT NOT NULL, instruction TEXT NOT NULL
        );
        CREATE INDEX direct_calls_caller ON direct_calls(caller_start);
        CREATE INDEX direct_calls_target ON direct_calls(target_address);
    """)

    start_to_next = {start: function_starts[i + 1] if i + 1 < len(function_starts) else None
                     for i, start in enumerate(function_starts)}
    for start in function_starts:
        db.execute("INSERT INTO native_functions(start_address,end_address) VALUES (?,?)",
                   (start, start_to_next[start]))

    method_name_by_address = {address: " | ".join(m["Name"] for m in rows)
                              for address, rows in methods_by_address.items()}
    for address, rows in methods_by_address.items():
        status = "mapped_to_native_function_start" if address in starts_set else "method_address_not_in_function_start_list"
        for method in rows:
            db.execute("INSERT INTO methods(address,name,signature,type_signature,native_function_start,mapping_status) VALUES (?,?,?,?,?,?)",
                       (address, method.get("Name", ""), method.get("Signature", ""), method.get("TypeSignature", ""),
                        address if address in starts_set else None, status))

    # The disassembly is streamed once; line offsets allow precise lookup without
    # copying hundreds of megabytes of assembly into SQLite.
    counts = {"assembly_lines": 0, "instructions": 0, "mapped_instruction_lines": 0,
              "direct_calls": 0, "indirect_calls": 0, "method_entry_addresses_seen": 0}
    sections = [section for section in native_index.get("sections", []) if section.get("status") == "complete"]
    for section in sections:
        asm_path = ROOT / section["path"]
        active_start = None
        active_line = None
        active_byte_start = None
        instruction_counts = {"instructions": 0, "direct": 0, "indirect": 0}
        seen_methods = set()

        def flush(end_line: int, end_byte: int) -> None:
            nonlocal active_start, active_line, active_byte_start
            if active_start is None:
                return
            db.execute("UPDATE native_functions SET assembly_path=?,start_line=?,end_line=?,assembly_text_byte_span=?,instruction_count=?,direct_call_count=?,indirect_call_count=?,disassembly_status='indexed' WHERE start_address=?",
                       (section["path"], active_line, end_line - 1, end_byte - active_byte_start,
                        instruction_counts["instructions"], instruction_counts["direct"], instruction_counts["indirect"], active_start))
            active_start = active_line = active_byte_start = None
            instruction_counts.update(instructions=0, direct=0, indirect=0)

        with asm_path.open("rb") as stream:
            line_number = 0
            while True:
                line_offset = stream.tell()
                raw = stream.readline()
                if not raw:
                    break
                line_number += 1
                counts["assembly_lines"] += 1
                line = raw.decode("utf-8", errors="replace").rstrip("\r\n")
                match = INSN_RE.match(line)
                if not match:
                    continue
                address = int(match.group(1), 16)
                instruction = match.group(2)
                if address in starts_set:
                    flush(line_number, line_offset)
                    active_start, active_line, active_byte_start = address, line_number, line_offset
                    seen_methods.add(address)
                    instruction_counts.update(instructions=0, direct=0, indirect=0)
                if active_start is None:
                    continue
                instruction_counts["instructions"] += 1
                counts["instructions"] += 1
                if active_start in starts_with_methods:
                    counts["mapped_instruction_lines"] += 1
                bl = DIRECT_BL_RE.match(instruction)
                if bl:
                    target = int(bl.group(1), 16)
                    instruction_counts["direct"] += 1
                    counts["direct_calls"] += 1
                    db.execute("INSERT INTO direct_calls(caller_start,caller_method_address,caller_method_name,line,instruction_address,target_address,target_method_name,target_status,assembly_path,instruction) VALUES (?,?,?,?,?,?,?,?,?,?)",
                               (active_start, active_start if active_start in starts_with_methods else None,
                                method_name_by_address.get(active_start), line_number, address, target,
                                method_name_by_address.get(target),
                                "mapped_method" if target in starts_with_methods else "not_exact_method_entry",
                                section["path"], instruction))
                elif re.match(r"^blr\s", instruction, re.I):
                    instruction_counts["indirect"] += 1
                    counts["indirect_calls"] += 1
            flush(line_number + 1, stream.tell())
        counts["method_entry_addresses_seen"] += len(seen_methods)
    db.commit()

    mapped_methods = db.execute("SELECT count(*) FROM methods WHERE mapping_status='mapped_to_native_function_start'").fetchone()[0]
    distinct_method_addresses = db.execute("SELECT count(DISTINCT address) FROM methods").fetchone()[0]
    indexed_funcs = db.execute("SELECT count(*) FROM native_functions WHERE disassembly_status='indexed'").fetchone()[0]
    call_targets = db.execute("SELECT target_status,count(*) FROM direct_calls GROUP BY target_status").fetchall()
    report = {
        "title": "IL2CPP 元数据方法与 ARM64 汇编关联索引",
        "sample": "Gossip Harbor 3.98.10; recovered stage-one snapshot",
        "inputs": {"binary": str(binary.relative_to(ROOT)).replace("\\", "/"), "binary_sha256": binary_hash,
                   "metadata": str(metadata.relative_to(ROOT)).replace("\\", "/"), "metadata_sha256": sha256(metadata),
                   "method_map": str(method_script.relative_to(ROOT)).replace("\\", "/"), "method_map_sha256": dumper_hash,
                   "method_map_sha256_matches_prior_dump": dumper_hash == sha256(ROOT / "tools" / "Il2CppDumper" / "Il2CppDumper" / "bin" / "Release" / "net8.0" / "script.json"),
                   "dumper_version": "31 (metadata version 31)",
                   "disassembly_sections": [{"path": s["path"], "bytes": s["bytes"], "lines": s["lines"]} for s in sections]},
        "method_map": {"methods": len(method_rows), "distinct_method_addresses": distinct_method_addresses,
                       "mapped_to_function_start": mapped_methods,
                       "unmapped_or_non_entry": len(method_rows) - mapped_methods},
        "native_functions": {"known_entry_addresses": len(function_starts), "with_disassembly": indexed_funcs,
                             "without_disassembly": len(function_starts) - indexed_funcs},
        "assembly_scan": counts,
        "direct_call_target_resolution": {status: count for status, count in call_targets},
        "database": str(db_path.relative_to(ROOT)).replace("\\", "/"),
        "limitations": [
            "This indexes ARM64 assembly, not recovered C# source or high-level control flow.",
            "Direct BL targets are exact only when they match a method entry address; thunk and shared generic bodies need manual attribution.",
            "BLR targets are indirect and remain unresolved without data-flow or runtime evidence.",
            "Function boundaries follow Il2CppDumper Addresses; shared bodies, aliases, and compiler-generated layout may complicate ownership.",
            "The method map is accepted only for the indexed binary after SHA-256 is recorded; metadata hash is recorded separately by the stage-one inventory.",
        ],
    }
    (REPORT / "stage2_il2cpp_native_index_summary.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    db.close()
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
