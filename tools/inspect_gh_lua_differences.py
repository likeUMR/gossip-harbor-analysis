"""Locate source-generation differences at function-prototype granularity."""
from audit_gh_resources import DATA, ROOT, load, save
from gh_lua import Chunk
from validate_gh_lua import fingerprint


def main():
    modules = {x["sha256"]: x for x in load(DATA / "lua_unique_chunks.json")}
    rows = []
    for result in load(DATA / "lua_validation.json"):
        if result["status"] != "compiled_structure_differs":
            continue
        module = modules[result["sha256"]]
        original = Chunk((ROOT / module["path"]).read_bytes())
        compiled = Chunk((ROOT / result["roundtrip_path"]).read_bytes())
        changes = []
        for index, (left, right) in enumerate(zip(original.functions, compiled.functions)):
            if left["code"] != right["code"] or left["constants"] != right["constants"]:
                changes.append({"index": index, "original": left, "compiled": right})
        rows.append({"name": module["name"], "source_path": module["source_path"],
                     "disassembly_path": module["disassembly_path"], "changes": changes})
        print(module["name"], [(x["index"], x["original"].get("line"),
                                len(x["original"]["code"]), len(x["compiled"]["code"])) for x in changes])
    save(DATA / "lua_source_differences.json", rows)


if __name__ == "__main__":
    main()
