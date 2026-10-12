"""Decode Android resources, preserve smali, and generate Java for review."""
import hashlib
import json
import os
import struct
import subprocess
import zipfile
from pathlib import Path

from audit_gh_resources import DATA, ROOT, SAMPLE, load, relative, save


def main():
    java = next((ROOT / "tools/logic_vendor/jre").glob("**/java.exe"))
    jars = sorted((ROOT / "tools/logic_vendor/jadx_maven").glob("*.jar"))
    classpath = os.pathsep.join(str(p) for p in jars if p.name != "jcommander-1.64.jar")
    smali_classpath = os.pathsep.join(str(p) for p in jars if p.name != "jcommander-2.0.jar")
    rows = []
    destination = DATA / "android"
    destination.mkdir(exist_ok=True)
    dex = [x for x in load(DATA / "apk_entries.json") if x.get("kind") == "android_dex"]
    protected = load(DATA / "appsflyer_recoveries.json") if (DATA / "appsflyer_recoveries.json").exists() else []
    for recovery in protected:
        dex.extend({**member, "entry": recovery["path"] + "!/" + member["name"], "origin": "protected_nested_dex"}
                   for member in recovery["members"] if member["name"].endswith(".dex"))
    for entry in dex:
        raw = (ROOT / entry["path"]).read_bytes()
        strings, types, protos, fields, methods, classes = [struct.unpack_from("<I", raw, i)[0]
                                                        for i in (56, 64, 72, 80, 88, 96)]
        target = destination / "smali" / entry["sha256"]
        row = {"path": entry["path"], "sha256": entry["sha256"], "bytes": len(raw),
               "string_ids": strings, "type_ids": types, "proto_ids": protos,
               "field_ids": fields, "method_ids": methods, "class_defs": classes,
               "signature_valid": raw[12:32] == hashlib.sha1(raw[32:]).digest()}
        if not (target / "audit.json").exists() or not load(target / "audit.json").get("smali_complete"):
            target.mkdir(parents=True, exist_ok=True)
            command = [str(java), "-Xmx2g", "-cp", smali_classpath,
                       "com.android.tools.smali.baksmali.Main", "disassemble", str(ROOT / entry["path"]),
                       "-o", str(target), "-j", "4"]
            result = subprocess.run(command, capture_output=True, timeout=300)
            row.update({"smali_exit": result.returncode,
                        "smali_log": result.stderr.decode("utf-8", "replace")[-3000:]})
            files = list(target.rglob("*.smali"))
            row.update({"smali_files": len(files), "smali_lines": sum(len(p.read_bytes().splitlines()) for p in files),
                        "smali_path": relative(target), "smali_complete": result.returncode == 0 and len(files) == classes})
            save(target / "audit.json", row)
        else:
            row = load(target / "audit.json")
        rows.append(row)
        print(f"DEX {entry['entry']}: classes={classes}, smali={row.get('smali_files')}", flush=True)
    output = destination / "jadx"
    log = destination / "jadx.log"
    command = [str(java), "-Xmx4g", "-cp", classpath, "jadx.cli.JadxCLI", "--show-bad-code",
               "-j", "8", "-d", str(output), *[str(p) for p in sorted(SAMPLE.glob("*.apk"))]]
    protected_output = destination / "protected_reading"
    if protected:
        protected_log = destination / "protected_jadx.log"
        with protected_log.open("wb") as handle:
            nested_result = subprocess.run([str(java), "-Xmx2g", "-cp", classpath, "jadx.cli.JadxCLI",
                "--show-bad-code", "-j", "4", "-d", str(protected_output),
                *[str(ROOT / x["path"]) for x in dex if x.get("origin") == "protected_nested_dex"]],
                stdout=handle, stderr=subprocess.STDOUT, timeout=300)
        files = list((protected_output / "sources").rglob("*.java"))
        save(destination / "protected_jadx_result.json", {"exit": nested_result.returncode,
            "source_files": len(files), "source_lines": sum(len(p.read_bytes().splitlines()) for p in files),
            "log": relative(protected_log)})
    if not (destination / "jadx_result.json").exists():
        with log.open("wb") as handle:
            result = subprocess.run(command, stdout=handle, stderr=subprocess.STDOUT, timeout=900)
        sources = list((output / "sources").rglob("*.java"))
        resultrow = {"exit": result.returncode, "command": command, "log": relative(log),
                     "source_files": len(sources), "source_bytes": sum(p.stat().st_size for p in sources),
                     "source_lines": sum(len(p.read_bytes().splitlines()) for p in sources),
                     "status": "generated_unverified" if result.returncode == 0 else "generated_with_errors"}
        save(destination / "jadx_result.json", resultrow)
    save(DATA / "android_summary.json", {"dex": rows, "jadx": load(destination / "jadx_result.json"),
        "nested_jadx": load(destination / "protected_jadx_result.json") if protected else None,
        "nested_dex_count": sum(x.get("origin") == "protected_nested_dex" for x in dex)})
    print(json.dumps(load(DATA / "android_summary.json"), indent=2))


if __name__ == "__main__":
    main()
