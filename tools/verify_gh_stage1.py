"""Independent container counts and on-disk hash checks for stage-one artifacts."""
import collections
import concurrent.futures
import hashlib
import zipfile

import UnityPy

from audit_gh_resources import DATA, ROOT, SAMPLE, load, save, sha


def container_count(row):
    try:
        env = UnityPy.load(str(ROOT / row["path"]))
        files = []
        def walk(value):
            children = getattr(value, "files", {})
            if isinstance(children, dict):
                for child in children.values():
                    walk(child)
            objects = getattr(value, "objects", None)
            if isinstance(objects, dict):
                files.append({"name": str(getattr(value, "name", "")), "object_count": len(objects)})
        for value in env.files.values():
            walk(value)
        count = sum(x["object_count"] for x in files)
        return {"path": row["path"], "expected_objects": count, "exported_objects": row["object_count"],
                "serialized_files": files, "status": "pass" if count == row["object_count"] else "failed"}
    except Exception as exc:
        return {"path": row["path"], "status": "failed", "error": repr(exc)}


def hash_check(row):
    try:
        path = ROOT / row["path"]
        raw = path.read_bytes()
        if sha(raw) != row["sha256"] or (row.get("bytes") is not None and len(raw) != row["bytes"]):
            raise ValueError("Hash/size mismatch")
        return None
    except Exception as exc:
        return {"path": row["path"], "error": repr(exc)}


def main():
    entries = load(DATA / "apk_entries.json")
    packages = []
    for apk in SAMPLE.glob("*.apk"):
        with zipfile.ZipFile(apk) as z:
            names = [x.filename for x in z.infolist() if not x.is_dir()]
            indexed = [x["entry"] for x in entries if x["apk"] == apk.name]
            packages.append({"apk": apk.name, "zip_entries": len(names), "indexed_entries": len(indexed),
                             "crc_failure": z.testzip(), "names_match": collections.Counter(names) == collections.Counter(indexed)})
    containers = load(DATA / "unity_containers.json")
    unique = {x["sha256"]: x for x in containers}
    counts = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=4) as executor:
        for row in executor.map(container_count, unique.values()):
            counts.append(row)
            if len(counts) % 250 == 0:
                print(f"Independent Unity count: {len(counts)}/{len(unique)}", flush=True)
    save(DATA / "container_verification.json", counts)
    objects = load(DATA / "unity_objects.json")
    targets = {x["path"]: x for x in entries if "path" in x}
    for x in containers:
        targets[x["path"]] = {"path": x["path"], "sha256": x["sha256"], "bytes": x["bytes"]}
    for x in objects:
        if "raw_path" in x:
            targets[x["raw_path"]] = {"path": x["raw_path"], "sha256": x["sha256"], "bytes": x["bytes"]}
        if "payload_path" in x:
            targets[x["payload_path"]] = {"path": x["payload_path"], "sha256": x["payload_sha256"], "bytes": x["payload_bytes"]}
    for recovery in load(DATA / "appsflyer_recoveries.json"):
        for member in recovery["members"]:
            targets[member["path"]] = member
    for code in load(DATA / "nested_code.json"):
        targets[code["decoded_path"]] = {"path": code["decoded_path"], "sha256": code["sha256"], "bytes": code["bytes"]}
    derived_paths = set()
    for row in load(DATA / "lua_unique_chunks.json"):
        derived_paths.update(row[k] for k in ("source_path", "disassembly_path") if row.get(k))
    for row in objects:
        if row.get("typetree_path"):
            derived_paths.add(row["typetree_path"])
    for filename in ("spine_skeletons.json", "spine_animations.json", "spine_animation_wire.json", "binary_dispositions.json"):
        for row in load(DATA / filename):
            derived_paths.update(row[k] for k in ("decoded_path", "full_decoded_path") if row.get(k))
    for dex in load(DATA / "android_summary.json")["dex"]:
        derived_paths.update(str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / dex["smali_path"]).rglob("*.smali"))
    for library in load(DATA / "native_libraries.json"):
        derived_paths.update(section["path"] for section in library["sections"])
    for code in load(DATA / "nested_code.json"):
        derived_paths.update(section["path"] for section in code["sections"])
    derived_paths.update(str(p.relative_to(ROOT)).replace("\\", "/") for p in (DATA / "binary_decoded").glob("*.json"))
    derived_paths.update(str(p.relative_to(ROOT)).replace("\\", "/") for p in (DATA / "binary_decoded").glob("*.asm"))
    derived = []
    for path in sorted(derived_paths):
        raw = (ROOT / path).read_bytes()
        row = {"path": path, "sha256": sha(raw), "bytes": len(raw)}
        derived.append(row)
        targets[path] = row
    save(DATA / "derived_artifact_manifest.json", {"scope": "Post-recovery reproducible artifact snapshot; hash consistency is not semantic verification", "files": derived})
    print(f"Derived artifact manifest: {len(derived)}", flush=True)
    failures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as executor:
        for index, result in enumerate(executor.map(hash_check, targets.values())):
            if result:
                failures.append(result)
            if (index + 1) % 100000 == 0:
                print(f"Artifact SHA-256 checks: {index + 1}/{len(targets)}", flush=True)
    save(DATA / "artifact_hash_failures.json", failures)
    summary = {"packages": packages, "unity_containers_checked": len(counts),
               "unity_count_failures": sum(x["status"] != "pass" for x in counts),
               "hashed_files": len(targets), "hash_failures": len(failures),
               "derived_files": len(derived),
               "all_checks_pass": not failures and all(x["status"] == "pass" for x in counts)
                 and all(x["crc_failure"] is None and x["names_match"] for x in packages),
               "limitation": "Hash checks prove artifact consistency, not undiscovered remote/server resources or source-code semantics"}
    save(DATA / "verification_summary.json", summary)
    print(summary)


if __name__ == "__main__":
    main()
