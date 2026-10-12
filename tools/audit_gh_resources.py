"""Exhaustive, provenance-preserving resource audit for the recorded GH sample."""
from __future__ import annotations

import argparse
import collections
import concurrent.futures
import csv
import datetime
import hashlib
import io
import json
import re
import struct
import subprocess
import time
import urllib.request
import zipfile
from pathlib import Path

import UnityPy

from extract_lua_config import decrypt, unpack_modules
from gh_lua import Chunk, OPCODES

ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "apk_extract/gossip_harbor_3.98.10"
DATA = ROOT / "analysis_data/logic_index"
OUT = ROOT / "analysis_output/logic_recovery"
BASE_URL = "https://diary.cdn.mergesigma.com/hotfix/3.98.10/android/"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def relative(path):
    return Path(path).relative_to(ROOT).as_posix()


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, default=str), encoding="utf-8")


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def safe_path(parent, name):
    path = (parent / name).resolve()
    if not path.is_relative_to(parent.resolve()):
        raise ValueError(f"Unsafe path: {name}")
    return path


def write_bytes(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or sha(path.read_bytes()) != sha(data):
        path.write_bytes(data)


def classify(name, data):
    lower = name.lower()
    if re.search(r"\.split\d+$", lower):
        return "unity_split_part"
    if data.startswith((b"UnityFS\0", b"UnityRaw\0", b"UnityWeb\0")):
        return "unity_bundle"
    if data.startswith(b"\x7fELF"):
        return "native_elf"
    if data.startswith(b"dex\n"):
        return "android_dex"
    if data.startswith(b"\xaf\x1b\xb1\xfa"):
        return "il2cpp_metadata"
    if data.startswith(b"\x1bLua"):
        return "lua_bytecode"
    if len(data) >= 20:
        metadata_size, file_size, version, offset = struct.unpack_from(">4I", data)
        if version >= 22 and len(data) >= 48:
            metadata_size, file_size, offset = struct.unpack_from(">IQQ", data, 20)
        if 5 <= version <= 30 and 0 < metadata_size <= len(data) and 0 < offset <= len(data):
            if file_size == len(data) or (version >= 22 and file_size == 0):
                return "unity_serialized"
    if lower.endswith(".bundle"):
        return "bundle_unrecognized"
    if lower.endswith((".ress", ".resource")):
        return "unity_resource_stream"
    if data.startswith(b"\x03\x00\x08\x00"):
        return "android_binary_xml"
    if data.startswith(b"\x02\x00\x0c\x00"):
        return "android_resource_table"
    if data.startswith(b"\xca\xfe\xba\xbe"):
        return "java_class"
    if data.startswith(b"\x1f\x8b"):
        return "gzip"
    if len(data) > 12 and data[4:8] == b"ftyp":
        return "video"
    if lower.endswith((".kotlin_builtins", ".binarypb")):
        return "protobuf_metadata"
    if lower.endswith((".prof", ".profm")):
        return "android_profile"
    if lower == "stamp-cert-sha256":
        return "package_metadata"
    if lower.endswith((".json", ".xml", ".txt", ".csv", ".lua", ".html", ".properties")):
        try:
            data.decode("utf-8")
            return "text"
        except UnicodeDecodeError:
            return "binary_named_text"
    magic = [(b"\x89PNG", "image"), (b"\xff\xd8\xff", "image"),
             (b"RIFF", "riff_media"), (b"OggS", "audio"), (b"PK\x03\x04", "zip"),
             (b"SQLite format 3", "sqlite"), (b"\x03\x00\x08\x00", "android_binary_xml")]
    for prefix, category in magic:
        if data.startswith(prefix):
            return category
    if lower.endswith((".ttf", ".otf")):
        return "font"
    if lower.endswith((".rsa", ".sf", ".mf")) or lower.startswith("meta-inf/"):
        return "package_metadata"
    if not data:
        return "empty"
    try:
        text = data.decode("utf-8")
        if all(c.isprintable() or c in "\r\n\t" for c in text):
            return "text"
    except UnicodeDecodeError:
        pass
    return "unknown_binary"


def scan_apks():
    rows = []
    packages = []
    for apk in sorted(SAMPLE.glob("*.apk")):
        blob = apk.read_bytes()
        packages.append({"path": relative(apk), "bytes": len(blob), "sha256": sha(blob)})
        with zipfile.ZipFile(apk) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                row = {"apk": apk.name, "entry": info.filename, "bytes": info.file_size,
                       "compressed_bytes": info.compress_size, "crc32": f"{info.CRC:08x}"}
                try:
                    data = archive.read(info)
                    target = safe_path(DATA / "sources/apk" / apk.stem, info.filename)
                    write_bytes(target, data)
                    row.update({"sha256": sha(data), "kind": classify(info.filename, data),
                                "path": relative(target), "status": "extracted_crc_verified"})
                except Exception as exc:
                    row.update({"status": "failed", "error": repr(exc)})
                rows.append(row)
        print(f"APK scanned: {apk.name}, total entries={len(rows)}", flush=True)
    save(DATA / "packages.json", packages)
    save(DATA / "apk_entries.json", rows)


def assemble_splits():
    rows = load(DATA / "apk_entries.json")
    groups = collections.defaultdict(list)
    for row in rows:
        if row.get("kind") == "unity_split_part":
            groups[(row["apk"], re.sub(r"\.split\d+$", "", row["entry"]))].append(row)
    assembled = []
    for (apk, name), parts in groups.items():
        parts.sort(key=lambda x: int(x["entry"].rsplit("split", 1)[-1]))
        numbers = [int(x["entry"].rsplit("split", 1)[-1]) for x in parts]
        if numbers != list(range(len(parts))):
            raise ValueError(f"Missing split: {name}: {numbers}")
        blob = b"".join((ROOT / x["path"]).read_bytes() for x in parts)
        path = safe_path(DATA / "sources/assembled" / apk, name)
        write_bytes(path, blob)
        assembled.append({"path": relative(path), "origin": f"{apk}!/{name}",
                          "parts": [x["path"] for x in parts], "sha256": sha(blob),
                          "bytes": len(blob), "kind": classify(name, blob)})
    save(DATA / "assembled_splits.json", assembled)
    return assembled


def acquire_remote(workers, mode):
    catalog = SAMPLE / "runtime/catalog_remote.json"
    data = load(catalog)
    ids = sorted(set(x for x in data["m_InternalIds"] if x.endswith(".bundle")))
    local = {x["entry"].removeprefix("assets/aa/android/"): x for x in load(DATA / "apk_entries.json")
             if x.get("kind") == "unity_bundle"}
    prior_path = DATA / "remote_resources.json"
    prior = {x["internal_id"]: x for x in load(prior_path)} if prior_path.exists() else {}

    def acquire(internal):
        name = internal.split("/android/", 1)[-1]
        row = {"internal_id": internal, "name": name, "catalog": relative(catalog),
               "catalog_sha256": sha(catalog.read_bytes())}
        if name in local and "remoteLoadPathPrefix" not in internal:
            row.update({"status": "local_apk", "path": local[name]["path"],
                        "sha256": local[name]["sha256"], "bytes": local[name]["bytes"]})
            return row
        target = safe_path(DATA / "sources/remote", name)
        existing = prior.get(internal, {})
        if target.exists() and existing.get("sha256") == sha(target.read_bytes()):
            return existing
        if mode == "logic" and not any(x in name for x in ("dynamicconfig", "contentupdate", "lua_")):
            row["status"] = "not_acquired_this_pass"
            return row
        url = BASE_URL + name
        row["url"] = url
        row["url_basis"] = "recorded runtime prefix + catalog bundle relative path"
        for attempt in range(2):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "GH-Resource-Audit/1.0"})
                with urllib.request.urlopen(req, timeout=35) as response:
                    blob = response.read()
                    resolved = response.url
                if classify(name, blob) != "unity_bundle":
                    raise ValueError("Response is not a Unity bundle")
                write_bytes(target, blob)
                row.update({"status": "downloaded", "path": relative(target), "bytes": len(blob),
                            "sha256": sha(blob), "resolved_url": resolved,
                            "retrieved_at": datetime.datetime.now(datetime.timezone.utc).isoformat()})
                return row
            except Exception as exc:
                row.update({"status": "failed", "error": repr(exc)})
        return row

    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        for row in executor.map(acquire, ids):
            rows.append(row)
            if len(rows) % 50 == 0:
                save(prior_path, rows)
                print(f"Remote inventory: {len(rows)}/{len(ids)} {dict(collections.Counter(x['status'] for x in rows))}", flush=True)
    save(prior_path, rows)


def text_payload(obj):
    raw = obj.get_raw_data()
    name_length = struct.unpack_from("<I", raw)[0]
    offset = (4 + name_length + 3) & ~3
    length = struct.unpack_from("<I", raw, offset)[0]
    if offset + 4 + length > len(raw):
        raise ValueError("TextAsset payload outside raw object")
    return raw[offset + 4:offset + 4 + length]


def scan_unity_one(candidate):
    source = ROOT / candidate["path"]
    digest = sha(source.read_bytes())
    cache = DATA / "unity" / digest / "inventory.json"
    if cache.exists():
        try:
            return candidate, load(cache), relative(cache)
        except (ValueError, OSError):
            pass
    record = {"sha256": digest, "bytes": source.stat().st_size, "objects": [], "files": []}
    try:
        env = UnityPy.load(str(source))
        record["files"] = [{"name": str(k), "type": type(v).__name__} for k, v in env.files.items()]
        for obj in env.objects:
            serial = str(getattr(obj.assets_file, "name", ""))
            serial_id = sha(serial.encode())[:16]
            stem = f"{serial_id}_{obj.path_id}"
            row = {"path_id": obj.path_id, "serialized_file": serial, "type": obj.type.name, "bytes": obj.byte_size}
            try:
                raw = obj.get_raw_data()
                rawpath = cache.parent / "raw" / (stem + ".bin")
                write_bytes(rawpath, raw)
                row.update({"raw_path": relative(rawpath), "sha256": sha(raw), "raw_status": "exported"})
                if obj.type.name == "TextAsset":
                    parsed = obj.read()
                    payload = text_payload(obj)
                    path = cache.parent / "textassets" / (stem + ".bin")
                    write_bytes(path, payload)
                    row.update({"name": parsed.m_Name, "payload_path": relative(path),
                                "payload_bytes": len(payload), "payload_sha256": sha(payload)})
                else:
                    tree = obj.read_typetree()
                    path = cache.parent / "typetrees" / (stem + ".json")
                    save(path, tree)
                    row.update({"name": tree.get("m_Name", ""), "typetree_path": relative(path)})
                row["decode_status"] = "decoded"
            except Exception as exc:
                row.update({"decode_status": "failed", "error": repr(exc)})
            record["objects"].append(row)
        record["status"] = "parsed" if record["objects"] else "parsed_no_objects"
    except Exception as exc:
        record.update({"status": "failed", "error": repr(exc)})
    save(cache, record)
    return candidate, record, relative(cache)


def scan_unity(workers=4):
    entries = load(DATA / "apk_entries.json")
    candidates = [{"path": x["path"], "origin": f"{x['apk']}!/{x['entry']}"}
                  for x in entries if x.get("kind") in ("unity_bundle", "unity_serialized", "bundle_unrecognized")]
    candidates.extend(assemble_splits())
    remote = DATA / "remote_resources.json"
    if remote.exists():
        candidates.extend({"path": x["path"], "origin": x["internal_id"]}
                          for x in load(remote) if x["status"] == "downloaded")
    hotfix = SAMPLE / "runtime/contentupdate_luadefault.bundle"
    candidates.append({"path": relative(hotfix), "origin": "recorded_runtime_hotfix"})
    containers = []
    objects = []
    # Deduplicate physical bytes before parallel extraction to avoid cache races.
    unique = {}
    for candidate in candidates:
        unique.setdefault(sha((ROOT / candidate["path"]).read_bytes()), candidate)
    records = {}
    with concurrent.futures.ProcessPoolExecutor(max_workers=workers) as executor:
        for index, (candidate, record, cache) in enumerate(executor.map(scan_unity_one, unique.values())):
            records[record["sha256"]] = (record, cache)
            if (index + 1) % 50 == 0:
                print(f"Unity unique containers: {index + 1}/{len(unique)}", flush=True)
    for candidate in candidates:
        digest = sha((ROOT / candidate["path"]).read_bytes())
        record, cache = records[digest]
        containers.append({**candidate, **{k: v for k, v in record.items() if k != "objects"},
                           "object_count": len(record["objects"]), "inventory": cache})
        objects.extend({**x, "container_sha256": digest, "container_path": candidate["path"],
                        "origin": candidate["origin"]} for x in record["objects"])
    save(DATA / "unity_containers.json", containers)
    save(DATA / "unity_objects.json", objects)


def classify_module(name):
    parts = name.split(".")
    if name.startswith(("Data.Config.", "Data.", "GameText_", "Story_", "Timeline_")):
        return "data_config"
    if name.startswith("Test.") or any(p.startswith("Test") for p in parts):
        return "test_debug"
    if "View" in parts or "UI" in parts or name.endswith("View") or "Window" in name:
        return "ui_view"
    if "Model" in parts or "Board" in parts or name.endswith("Model"):
        return "model_gameplay"
    if "Config" in name or "Story" in name or "Timeline" in name:
        return "data_config"
    return "support_or_unclassified"


def recover_code(workers):
    objects = load(DATA / "unity_objects.json")
    archives, modules, texts = [], [], []
    seen_payloads = set()
    for obj in objects:
        if "payload_path" not in obj:
            continue
        payload = (ROOT / obj["payload_path"]).read_bytes()
        payload_key = (obj.get("name", ""), obj["payload_sha256"])
        if payload_key in seen_payloads:
            continue
        seen_payloads.add(payload_key)
        rawname = obj.get("name", "")
        row = {"name": rawname, "source": obj["payload_path"], "container": obj["container_path"],
               "sha256": sha(payload), "bytes": len(payload)}
        if rawname.startswith("Lua") or rawname.startswith("lua"):
            if not payload:
                row["status"] = "empty_placeholder"
                archives.append(row)
                continue
            try:
                decoded = decrypt(payload)
                archive_path = DATA / "lua/archives" / (sha(payload) + ".bin")
                write_bytes(archive_path, decoded)
                extracted = list(unpack_modules(decoded))
                if len({name for name, _ in extracted}) != len(extracted):
                    raise ValueError("Duplicate module name inside archive")
                for name, value in extracted:
                    target = safe_path(DATA / "lua/modules" / sha(payload)[:16], name.replace(".", "/") + ".luac")
                    write_bytes(target, value)
                    modules.append({"name": name, "archive": rawname, "archive_sha256": sha(payload),
                                    "origin": obj["origin"], "path": relative(target),
                                    "sha256": sha(value), "bytes": len(value),
                                    "category": classify_module(name)})
                row.update({"status": "recovered", "modules": len(extracted),
                            "decoded_path": relative(archive_path), "decoded_bytes": len(decoded)})
            except Exception as exc:
                row.update({"status": "failed", "error": repr(exc)})
            archives.append(row)
        else:
            # Dynamic story bundles contain individually encrypted chunks, not archives.
            if decrypt(payload[:12]).startswith(b"\x1bLua"):
                payload = decrypt(payload)
                decoded_path = DATA / "lua/standalone" / (sha(payload) + ".luac")
                write_bytes(decoded_path, payload)
                row.update({"encoding": "xor_cycle", "decoded_path": relative(decoded_path)})
            if not payload:
                row["status"] = "empty"
            elif payload.startswith(b"\x1bLua"):
                name = re.sub(r"[^A-Za-z0-9_.-]", "_", rawname)
                modules.append({"name": name, "archive": "standalone", "archive_sha256": sha(payload),
                                "origin": obj["origin"], "path": row.get("decoded_path", obj["payload_path"]),
                                "sha256": sha(payload), "bytes": len(payload), "category": classify_module(name)})
                row["status"] = "lua_bytecode"
            else:
                try:
                    text = payload.decode("utf-8")
                    if any(ord(c) < 32 and c not in "\r\n\t" for c in text):
                        raise ValueError("Binary control characters")
                    row.update({"status": "utf8_text", "lines": len(text.splitlines())})
                    if text.lstrip().startswith(("{", "[")):
                        json.loads(text)
                        row["status"] = "json"
                    target = DATA / "text" / (sha(payload) + (".json" if row["status"] == "json" else ".txt"))
                    write_bytes(target, payload)
                    row["decoded_path"] = relative(target)
                except Exception as exc:
                    row.update({"status": "unknown_payload", "error": repr(exc)})
            texts.append(row)
    save(DATA / "lua_archives.json", archives)
    save(DATA / "textassets.json", texts)
    unique = {}
    for module in modules:
        unique.setdefault(module["sha256"], module)
    luac = ROOT / "analysis_data/luac-compatible.exe"
    java = next(iter((ROOT / "tools/logic_vendor/jre").glob("**/java.exe")), None)
    jar = ROOT / "tools/logic_vendor/unluac.jar"

    def process(module):
        row = dict(module)
        dest = DATA / "lua/decoded" / row["sha256"]
        cache = dest / "index.json"
        if cache.exists():
            prior = load(cache)
            retry_empty = prior.get("decompile_status") == "failed" and prior.get("instructions") == 1
            if not retry_empty and not (java and jar.exists() and prior.get("decompile_status") == "tool_unavailable"):
                return prior
        dest.mkdir(parents=True, exist_ok=True)
        source = ROOT / row["path"]
        try:
            chunk = Chunk(source.read_bytes())
            standard = dest / "standard.luac"
            write_bytes(standard, chunk.standard())
            functions = []
            for f in chunk.functions:
                functions.append({"prototype": f["key"], "offset": f["offset"],
                                  "first_line": f["first"], "last_line": f["last"],
                                  "parameters": f["args"][0], "vararg": bool(f["args"][1]),
                                  "instructions": len(f["code"]) // 4,
                                  "constants": len(f["constants"]), "strings": f["strings"],
                                  "source": (f["resolved_source"] or b"").decode("utf-8", "replace")})
            row.update({"parse_status": "complete", "functions": functions,
                        "prototype_count": len(functions), "standard_path": relative(standard),
                        "instructions": sum(x["instructions"] for x in functions)})
            result = subprocess.run([str(luac), "-l", "-l", str(source)], capture_output=True, timeout=30)
            if result.returncode:
                raise ValueError(result.stderr.decode("utf-8", "replace"))
            disasm = dest / "disassembly.txt"
            write_bytes(disasm, result.stdout)
            row.update({"disassembly_path": relative(disasm),
                        "disassembly_lines": len(result.stdout.splitlines())})
            row["decompile_status"] = "tool_unavailable"
            if java and jar.exists():
                result = subprocess.run([str(java), "-jar", str(jar), str(standard)],
                                        capture_output=True, timeout=60)
                if result.returncode == 0:
                    output = dest / "decompiled.lua"
                    source_text = result.stdout.replace(b"\r\n", b"\n").replace(b"\r", b"")
                    write_bytes(output, source_text)
                    row.update({"decompile_status": "generated_unverified", "source_path": relative(output),
                                "decompiled_lines": len(source_text.splitlines())})
                else:
                    row.update({"decompile_status": "failed", "decompile_error": result.stderr.decode("utf-8", "replace")[-3000:]})
        except Exception as exc:
            row.update({"parse_status": "failed", "error": repr(exc)})
        save(cache, row)
        return row

    decoded = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        for row in executor.map(process, unique.values()):
            decoded.append(row)
            if len(decoded) % 100 == 0:
                print(f"Lua chunks: {len(decoded)}/{len(unique)}", flush=True)
    by_hash = {x["sha256"]: x for x in decoded}
    for module in modules:
        details = by_hash[module["sha256"]]
        module.update({k: v for k, v in details.items() if k not in module and k != "functions"})
    functions = [{**f, "module_sha256": x["sha256"], "module": x["name"],
                  "id": f"{x['sha256']}:{f['prototype']}", "review_status": "unreviewed"}
                 for x in decoded for f in x.get("functions", [])]
    save(DATA / "lua_modules.json", modules)
    save(DATA / "lua_unique_chunks.json", [{k: v for k, v in x.items() if k != "functions"} for x in decoded])
    save(DATA / "lua_functions.json", functions)
    names = collections.defaultdict(list)
    for module in modules:
        names[module["name"]].append({k: module[k] for k in ("archive", "sha256", "path", "origin")})
    save(DATA / "module_variants.json", {k: v for k, v in names.items() if len(v) > 1})


def native_index():
    dumpdir = ROOT / "tools/Il2CppDumper/Il2CppDumper/bin/Release/net8.0"
    data = load(dumpdir / "script.json")
    methods = data["ScriptMethod"]
    save(DATA / "native_methods.json", [{**x, "recovery_status": "signature_address_only",
                                         "review_status": "unreviewed"} for x in methods])
    text = (dumpdir / "dump.cs").read_text(encoding="utf-8-sig")
    images = re.findall(r"^// Image \d+: (.+?) -", text, re.M)
    save(DATA / "native_summary.json", {"method_mappings": len(methods), "images": images,
         "dump_lines": len(text.splitlines()), "class_declarations": len(re.findall(r"TypeDefIndex:", text)),
         "source": relative(dumpdir / "script.json"), "dump_sha256": sha((dumpdir / "dump.cs").read_bytes()),
         "warning": "dump.cs contains declarations and stub bodies, not recovered C# implementation"})


def disassemble_native():
    from elftools.elf.elffile import ELFFile
    from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
    rows = []
    for entry in load(DATA / "apk_entries.json"):
        if entry.get("kind") != "native_elf":
            continue
        source = ROOT / entry["path"]
        destination = DATA / "native" / entry["sha256"]
        cache = destination / "index.json"
        if cache.exists():
            rows.append(load(cache))
            continue
        destination.mkdir(parents=True, exist_ok=True)
        row = {"path": entry["path"], "sha256": entry["sha256"], "bytes": entry["bytes"], "sections": []}
        try:
            with source.open("rb") as handle:
                elf = ELFFile(handle)
                row["machine"] = elf["e_machine"]
                if elf["e_machine"] != "EM_AARCH64":
                    raise ValueError("Unsupported native architecture")
                md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
                md.skipdata = True
                for section in elf.iter_sections():
                    if not section["sh_flags"] & 4 or section["sh_type"] == "SHT_NOBITS":
                        continue
                    raw = section.data()
                    path = destination / (section.name.replace("/", "_") + ".asm")
                    count = decoded_bytes = data_bytes = 0
                    with path.open("w", encoding="utf-8", newline="\n") as output:
                        for address, size, mnemonic, operands in md.disasm_lite(raw, section["sh_addr"]):
                            output.write(f"{address:016x}: {mnemonic} {operands}\n")
                            count += 1
                            decoded_bytes += size
                            if mnemonic == ".byte":
                                data_bytes += size
                    row["sections"].append({"name": section.name, "address": section["sh_addr"],
                         "bytes": len(raw), "covered_bytes": decoded_bytes, "data_bytes": data_bytes,
                         "lines": count, "path": relative(path), "status": "complete" if decoded_bytes == len(raw) else "partial"})
                row["status"] = "disassembled" if all(x["status"] == "complete" for x in row["sections"]) else "partial"
        except Exception as exc:
            row.update({"status": "failed", "error": repr(exc)})
        save(cache, row)
        rows.append(row)
        print(f"Native: {source.name}: {row['status']}", flush=True)
    save(DATA / "native_libraries.json", rows)


def report():
    packages = load(DATA / "packages.json")
    entries = load(DATA / "apk_entries.json")
    containers = load(DATA / "unity_containers.json")
    objects = load(DATA / "unity_objects.json")
    modules = load(DATA / "lua_modules.json")
    chunks = load(DATA / "lua_unique_chunks.json")
    for row in chunks:
        row["category"] = classify_module(row["name"])
    for row in modules:
        row["category"] = classify_module(row["name"])
    save(DATA / "lua_unique_chunks.json", chunks)
    save(DATA / "lua_modules.json", modules)
    functions = load(DATA / "lua_functions.json")
    texts = load(DATA / "textassets.json")
    archives = load(DATA / "lua_archives.json")
    remote = load(DATA / "remote_resources.json") if (DATA / "remote_resources.json").exists() else []
    native = load(DATA / "native_summary.json")
    native_libraries = load(DATA / "native_libraries.json")
    android = load(DATA / "android_summary.json")
    validation = load(DATA / "lua_validation_summary.json")
    validation_rows = load(DATA / "lua_validation.json")
    database = load(DATA / "database_summary.json")
    dispositions = load(DATA / "binary_dispositions.json")
    spine_skeletons = load(DATA / "spine_skeletons.json")
    spine_animations = load(DATA / "spine_animations.json")
    spine_wire = load(DATA / "spine_animation_wire.json")
    spine_dependencies = load(DATA / "spine_dependency_checks.json")
    android_methods = load(DATA / "android_method_summary.json")
    nested_code = load(DATA / "nested_code.json")
    issues = []

    def issue(category, severity, items, note):
        if items:
            issues.append({"category": category, "severity": severity, "count": len(items),
                           "note": note, "items": items})

    issue("apk_extract_failed", "blocking", [x for x in entries if x["status"] == "failed"], "APK entry could not be extracted")
    issue("unresolved_apk_binary", "blocking", [x for x in dispositions if x["status"] not in ("recovered", "wire_decoded")], "Protected or unidentified body has not been decoded")
    issue("binary_field_semantics", "readability", [x for x in dispositions if x["status"] == "wire_decoded"], "Complete binary structures are available; original field names/semantic roles require reader analysis")
    issue("unity_container_failed", "blocking", [x for x in containers if x["status"] != "parsed"], "Container failed or yielded no objects")
    issue("unity_object_decode_failed", "blocking", [x for x in objects if x["decode_status"] != "decoded"], "Raw preservation is not equivalent to decoded fields")
    issue("lua_archive_failed", "blocking", [x for x in archives if x["status"] == "failed"], "Lua archive not recovered")
    issue("lua_parse_failed", "blocking", [x for x in chunks if x["parse_status"] != "complete"], "Bytecode parsing did not consume complete chunk")
    issue("unresolved_textasset_payload", "blocking", [x for x in texts if x["status"] in ("unknown_payload", "spine_failed", "spine_decoded_ambiguous")], "Known animation format still requires successful full decoding with its skeleton context")
    issue("remote_not_acquired", "blocking", [x for x in remote if x["status"] not in ("downloaded", "local_apk")], "Recorded catalog entry has no acquired bundle")
    issue("lua_source_not_generated", "readability", [x for x in chunks if x.get("decompile_status") != "generated_unverified"], "Bytecode remains available when parsing succeeded")
    issue("native_disassembly_failed", "blocking", [x for x in native_libraries if x["status"] != "disassembled"], "Executable native sections lack complete instruction coverage")
    issue("native_high_level_source", "readability", [native], "All executable sections have disassembly; C# implementations and control-flow reconstruction remain review work")
    issue("android_smali_failed", "blocking", [x for x in android["dex"] if not x["smali_complete"]], "DEX class count does not match smali export")
    java_failures = load(DATA / "android_java_failures.json")
    issue("android_java_errors", "readability", java_failures, "Explicit source markers indexed and all mapped to complete smali; generated Java is not authoritative at marked lines")
    issue("android_fallback_unmapped", "blocking", [x for x in java_failures if x["status"] == "fallback_unmapped"], "Failed generated Java lacks an indexed low-level fallback")
    issue("animation_wire_failed", "blocking", [x for x in spine_wire if x["status"] != "wire_decoded" or not x.get("roundtrip_bytes_equal")], "Encoded animation timeline could not be recovered and byte-for-byte reproduced")
    issue("lua_source_structure_differs", "readability", [x for x in validation_rows if x["status"] != "instruction_structure_equal"], "Generated source differs from original bytecode; review disassembly before relying on it")
    issue("encrypted_runtime_database", "blocking", [database] if database["status"] != "decrypted" else [], "Recorded database has not been decrypted")
    categories = collections.defaultdict(lambda: {"files": 0, "bytes": 0, "instructions": 0, "decompiled_lines": 0})
    for x in chunks:
        row = categories[x["category"]]
        row["files"] += 1
        row["bytes"] += x["bytes"]
        row["instructions"] += x.get("instructions", 0)
        row["decompiled_lines"] += x.get("decompiled_lines", 0)
    for row in categories.values():
        row["file_percent"] = 100 * row["files"] / len(chunks) if chunks else 0
    summary = {
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "sample": "Gossip Harbor 3.98.10", "stage_complete": not any(x["severity"] == "blocking" for x in issues),
        "packages": len(packages), "apk_entries": len(entries), "apk_expanded_bytes": sum(x["bytes"] for x in entries),
        "apk_kinds": dict(collections.Counter(x.get("kind", "failed") for x in entries)),
        "unity_container_occurrences": len(containers), "unity_unique_containers": len({x["sha256"] for x in containers}),
        "unity_objects_occurrences": len(objects), "unity_object_types": dict(collections.Counter(x["type"] for x in objects)),
        "lua_archives": [{k: x.get(k) for k in ("name", "status", "modules", "bytes")} for x in archives],
        "module_occurrences": len(modules), "module_names": len({x["name"] for x in modules}),
        "unique_bytecode_chunks": len(chunks), "bytecode_bytes": sum(x["bytes"] for x in chunks),
        "function_prototypes_including_main": len(functions),
        "nested_function_prototypes": sum(x["prototype"] != "0" for x in functions),
        "bytecode_instructions": sum(x.get("instructions", 0) for x in chunks),
        "decompiled_lines": sum(x.get("decompiled_lines", 0) for x in chunks),
        "disassembly_lines": sum(x.get("disassembly_lines", 0) for x in chunks),
        "original_source_lines": None,
        "decompile_status": dict(collections.Counter(x.get("decompile_status", "not_attempted") for x in chunks)),
        "categories": dict(categories), "remote_status": dict(collections.Counter(x["status"] for x in remote)),
        "remote_download_bytes": sum(x.get("bytes", 0) for x in remote if x["status"] == "downloaded"),
        "native": native, "native_library_count": len(native_libraries),
        "native_disassembly_lines": sum(s["lines"] for x in native_libraries for s in x["sections"]),
        "android": {"dex_count": len(android["dex"]), "class_definitions": sum(x["class_defs"] for x in android["dex"]),
                    "smali_files": sum(x["smali_files"] for x in android["dex"]),
                    "smali_lines": sum(x["smali_lines"] for x in android["dex"]), "jadx": android["jadx"],
                    "nested_dex_count": android["nested_dex_count"], "nested_jadx": android["nested_jadx"],
                    "method_index": android_methods},
        "lua_validation": validation, "database": database,
        "spine_skeleton_status": dict(collections.Counter(x["status"] for x in spine_skeletons)),
        "spine_animation_status": dict(collections.Counter(x["status"] for x in spine_animations)),
        "binary_disposition_status": dict(collections.Counter(x["status"] for x in dispositions)),
        "spine_wire_status": dict(collections.Counter(x["status"] for x in spine_wire)),
        "spine_dependency_status": dict(collections.Counter(x["status"] for x in spine_dependencies)),
        "nested_native_code": nested_code,
        "phase_one_boundary": "All listed bodies acquired and decoded at least structurally; 318 animation contexts cannot be restored from the acquired snapshot because no matching skeleton exists among all 1115. This does not prove historical/server resources are globally unavailable.",
        "issues": [{k: v for k, v in x.items() if k != "items"} for x in issues],
        "definitions": {"unique_chunks": "SHA-256 deduplication, not semantic deduplication",
                        "categories": "Path/name classification; provisional until function review",
                        "lines": "Generated decompiled/disassembly lines; original source LOC unknown",
                        "functions": "Parsed Lua prototypes, includes anonymous/nested functions and chunk main",
                        "remote": "Recorded 2026-09-22 catalog, fetched bytes timestamped separately; not current account configuration",
                        "decompilation": "Generated source is unverified until compilation/bytecode comparison"}}
    save(DATA / "issues.json", issues)
    save(OUT / "stage1_summary.json", summary)
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / "lua_module_inventory.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        fields = ["name", "archive", "category", "bytes", "sha256", "prototype_count", "instructions", "decompiled_lines", "parse_status", "decompile_status", "path", "source_path", "disassembly_path"]
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(modules)
    print(json.dumps({k: summary[k] for k in ("stage_complete", "apk_entries", "module_occurrences", "unique_bytecode_chunks", "function_prototypes_including_main", "decompile_status", "remote_status", "issues")}, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("step", choices=["apk", "remote", "unity", "code", "native", "assembly", "report", "all"])
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--remote-mode", choices=["all", "logic"], default="all")
    args = parser.parse_args()
    actions = {"apk": scan_apks, "remote": lambda: acquire_remote(args.workers, args.remote_mode),
               "unity": lambda: scan_unity(min(args.workers, 4)), "code": lambda: recover_code(args.workers),
               "native": native_index, "assembly": disassemble_native, "report": report}
    DATA.mkdir(parents=True, exist_ok=True)
    if args.step == "all":
        for action in actions.values():
            action()
    else:
        actions[args.step]()


if __name__ == "__main__":
    main()
