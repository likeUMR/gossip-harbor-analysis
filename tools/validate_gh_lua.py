"""Check full Lua parsing and generated source against the sample compiler."""
import collections
import concurrent.futures
import subprocess

from audit_gh_resources import DATA, ROOT, load, relative, save
from gh_lua import Chunk


def fingerprint(f):
    return (f["args"], f["code"], tuple(f["constants"]), f["upvalues"],
            tuple(fingerprint(c) for c in f["children"]))


def check(module):
    row = {"sha256": module["sha256"], "name": module["name"]}
    try:
        original = Chunk((ROOT / module["path"]).read_bytes())
        disasm = (ROOT / module["disassembly_path"]).read_text(encoding="utf-8", errors="replace")
        expected_headers = len(original.functions)
        actual_headers = sum(line.startswith(("main <", "function <")) for line in disasm.splitlines())
        row["prototype_count_matches_luac"] = expected_headers == actual_headers
        if "source_path" not in module:
            row["status"] = "no_source"
            return row
        target = (ROOT / module["source_path"]).parent / "roundtrip.luac"
        result = subprocess.run([str(ROOT / "analysis_data/luac-compatible.exe"), "-o", str(target),
                                 str(ROOT / module["source_path"])], capture_output=True, timeout=30)
        row["compile_exit"] = result.returncode
        if result.returncode:
            row.update({"status": "compile_failed", "error": result.stderr.decode("utf-8", "replace")[-2000:]})
        else:
            compiled = Chunk(target.read_bytes())
            exact = fingerprint(original.root) == fingerprint(compiled.root)
            row.update({"status": "instruction_structure_equal" if exact else "compiled_structure_differs",
                        "compiled_prototypes": len(compiled.functions), "roundtrip_path": relative(target)})
    except Exception as exc:
        row.update({"status": "failed", "error": repr(exc)})
    return row


def main():
    modules = load(DATA / "lua_unique_chunks.json")
    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        for row in executor.map(check, modules):
            rows.append(row)
            if len(rows) % 200 == 0:
                print(f"Lua validation: {len(rows)}/{len(modules)}", flush=True)
    save(DATA / "lua_validation.json", rows)
    summary = {"count": len(rows), "statuses": dict(collections.Counter(x["status"] for x in rows)),
               "prototype_mismatches": sum(not x.get("prototype_count_matches_luac", False) for x in rows),
               "definition": "Exact args/opcodes/constants/upvalues/child prototypes comparison; debug data ignored",
               "limitation": "A mismatch does not prove semantic error; source requires disassembly review. No gameplay execution performed."}
    save(DATA / "lua_validation_summary.json", summary)
    print(summary)


if __name__ == "__main__":
    main()
