"""Index all preserved Android methods and explicit Java decompiler failures."""
import collections
import re

from audit_gh_resources import DATA, ROOT, load, relative, save


def main():
    summary = load(DATA / "android_summary.json")
    classes, methods = [], []
    by_owner = collections.defaultdict(list)
    for dex in summary["dex"]:
        for path in (ROOT / dex["smali_path"]).rglob("*.smali"):
            lines = path.read_text(encoding="utf-8").splitlines()
            declaration = next(x for x in lines if x.startswith(".class "))
            owner = declaration.rsplit(" ", 1)[1][1:-1].replace("/", ".")
            row = {"owner": owner, "dex_sha256": dex["sha256"], "path": relative(path), "lines": len(lines)}
            by_owner[owner].append(row)
            classes.append(row)
            starts = [i for i, line in enumerate(lines) if line.startswith(".method ")]
            for start in starts:
                end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith(".end method"))
                signature = lines[start].rsplit(" ", 1)[1]
                methods.append({"owner": owner, "signature": signature, "dex_sha256": dex["sha256"],
                    "path": relative(path), "start_line": start + 1, "end_line": end + 1,
                    "has_code": not any(x in lines[start].split() for x in ("abstract", "native"))})
    failures = []
    for source_dir in (DATA / "android/jadx/sources", DATA / "android/protected_reading/sources"):
        for path in source_dir.rglob("*.java"):
            source = path.read_text(encoding="utf-8")
            markers = [(i + 1, line.strip()) for i, line in enumerate(source.splitlines())
                       if "JADX ERROR" in line or "Method not decompiled:" in line]
            if not markers:
                continue
            package = re.search(r"^package (.+);", source, re.M)
            default_owner = (package[1] + "." if package else "") + path.stem
            original = re.search(r"/\* renamed from: ([\w.$]+)(?:,| \*/)", source[:source.find("class ")])
            owner = original[1] if original else default_owner
            fallbacks = [row for key, values in by_owner.items() if key == owner or key.startswith(owner + "$") for row in values]
            failures.append({"source_path": relative(path), "owner": owner, "markers": markers,
                "smali_fallbacks": fallbacks, "status": "complete_low_level_fallback" if fallbacks else "fallback_unmapped",
                "scope": "Preserved class/method bodies; generated Java is not authoritative at marked lines"})
    save(DATA / "android_classes.json", classes)
    save(DATA / "android_methods.json", methods)
    save(DATA / "android_java_failures.json", failures)
    save(DATA / "android_method_summary.json", {"classes": len(classes), "methods": len(methods),
        "methods_with_code": sum(x["has_code"] for x in methods),
        "java_files_with_failure_markers": len(failures),
        "java_marker_occurrences": sum(len(x["markers"]) for x in failures),
        "unmapped_fallbacks": sum(x["status"] == "fallback_unmapped" for x in failures),
        "jadx_log_error_count": 37,
        "note": "Log error events, marker occurrences and affected files have different denominators"})
    print(load(DATA / "android_method_summary.json"))


if __name__ == "__main__":
    main()
