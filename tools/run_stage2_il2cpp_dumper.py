"""Run the bundled Il2CppDumper non-interactively for the recovered sample."""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_RUNTIME = ROOT / "tools" / "Il2CppDumper" / "Il2CppDumper" / "bin" / "Release" / "net8.0"
RUNTIME = ROOT / "analysis_data" / "logic_index" / "stage2" / "il2cpp_dumper_runtime"
OUTPUT = ROOT / "analysis_data" / "logic_index" / "stage2" / "il2cpp_dumper_run"
BINARY = ROOT / "analysis_data" / "logic_index" / "sources" / "apk" / "split_config.arm64_v8a" / "lib" / "arm64-v8a" / "libil2cpp.so"
METADATA = ROOT / "apk_extract" / "gossip_harbor_3.98.10" / "base_extracted" / "assets" / "bin" / "Data" / "Managed" / "Metadata" / "global-metadata.dat"


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    if not BINARY.is_file() or not METADATA.is_file():
        raise SystemExit("Expected stage-one libil2cpp.so and global-metadata.dat were not found")
    RUNTIME.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    required = {"Il2CppDumper.exe", "Il2CppDumper.dll", "Il2CppDumper.deps.json",
                "Il2CppDumper.runtimeconfig.json", "config.json"}
    required.update(path.name for path in SOURCE_RUNTIME.glob("*.dll"))
    missing = sorted(name for name in required if not (SOURCE_RUNTIME / name).is_file())
    if missing:
        raise SystemExit("Missing bundled runtime files: " + ", ".join(missing))
    for name in required:
        shutil.copy2(SOURCE_RUNTIME / name, RUNTIME / name)

    config_path = RUNTIME / "config.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))
    config["RequireAnyKey"] = False
    config_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")

    command = [str(RUNTIME / "Il2CppDumper.exe"), str(BINARY), str(METADATA), str(OUTPUT)]
    result = subprocess.run(command, cwd=RUNTIME, text=True, encoding="utf-8", errors="replace",
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    (OUTPUT / "dumper_run.log").write_text(result.stdout, encoding="utf-8")
    script_path = OUTPUT / "script.json"
    dump_path = OUTPUT / "dump.cs"
    if result.returncode != 0 or not script_path.is_file() or not dump_path.is_file():
        raise SystemExit(f"Il2CppDumper failed (exit={result.returncode}); see {OUTPUT / 'dumper_run.log'}")
    script = json.loads(script_path.read_text(encoding="utf-8"))
    summary = {
        "status": "pass",
        "binary": str(BINARY.relative_to(ROOT)).replace("\\", "/"),
        "binary_sha256": file_hash(BINARY),
        "metadata": str(METADATA.relative_to(ROOT)).replace("\\", "/"),
        "metadata_sha256": file_hash(METADATA),
        "method_map": str(script_path.relative_to(ROOT)).replace("\\", "/"),
        "method_map_sha256": file_hash(script_path),
        "method_count": len(script.get("ScriptMethod", [])),
        "native_function_entry_count": len(script.get("Addresses", [])),
        "dump_cs_bytes": dump_path.stat().st_size,
        "dumper_output_log": str((OUTPUT / "dumper_run.log").relative_to(ROOT)).replace("\\", "/"),
        "dumper_output_tail": result.stdout.splitlines()[-10:],
    }
    report_path = ROOT / "analysis_output" / "logic_recovery" / "stage2" / "stage2_il2cpp_dumper_run.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
