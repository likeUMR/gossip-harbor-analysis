"""Add embedded-resource, type, alias and binary-disposition indexes."""
import bisect
import collections
import re
import struct

from audit_gh_resources import DATA, ROOT, load, relative, safe_path, save, sha, write_bytes


def main():
    objects = load(DATA / "unity_objects.json")
    save(DATA / "textasset_occurrences.json", [{k: x[k] for k in (
        "name", "payload_sha256", "payload_path", "container_path", "origin", "path_id", "serialized_file")}
        for x in objects if "payload_path" in x])
    entries = load(DATA / "apk_entries.json")
    embedded = []
    dispositions = []
    for entry in entries:
        if entry.get("kind") != "unknown_binary":
            continue
        name = entry["entry"]
        raw = (ROOT / entry["path"]).read_bytes()
        row = {"path": entry["path"], "sha256": entry["sha256"], "bytes": len(raw)}
        if name.endswith(".dll-resources.dat"):
            try:
                header_size, count = struct.unpack_from("<II", raw)
                offset, headers = 8, []
                for _ in range(count):
                    size, length = struct.unpack_from("<II", raw, offset)
                    offset += 8
                    resource_name = raw[offset:offset + length].decode("utf-8")
                    offset += length
                    headers.append((resource_name, size))
                if offset != header_size + 4:
                    raise ValueError("Managed-resource directory length mismatch")
                for resource_name, size in headers:
                    payload = raw[offset:offset + size]
                    if len(payload) != size:
                        raise ValueError("Managed-resource payload truncated")
                    target = safe_path(DATA / "managed_resources" / entry["sha256"], resource_name)
                    write_bytes(target, payload)
                    embedded.append({"container": entry["path"], "name": resource_name,
                                     "path": relative(target), "bytes": size, "sha256": sha(payload)})
                    offset += size
                if offset != len(raw):
                    raise ValueError("Managed-resource trailing bytes")
                row.update({"format": "unity_managed_resource_archive", "status": "recovered", "members": count})
            except Exception as exc:
                row.update({"format": "unity_managed_resource_archive", "status": "failed", "error": repr(exc)})
        elif "/appsflyer/internal/" in name and raw.startswith((b"java/lang/Integer", b"java/io/Serializable")):
            row.update({"format": "appsflyer_protected_payload", "status": "opaque",
                        "evidence": "Vendor directory + Java type prefix; protected body not decoded"})
        elif name == "assets/vkqualitydata.vkq" and raw.startswith(b"AQKV"):
            row.update({"format": "vulkan_quality_database", "status": "opaque",
                        "evidence": "AQKV signature and paired libvkquality.so; binary schema not recovered"})
        elif "billingclient_heterodyne" in name:
            row.update({"format": "billing_protobuf_metadata", "status": "identified_not_decoded"})
        else:
            row.update({"format": "unknown_binary", "status": "unknown"})
        dispositions.append(row)
    recovery_by_path = {}
    for filename in ("remaining_binary_recoveries.json", "appsflyer_recoveries.json", "vkquality_recovery.json"):
        if (DATA / filename).exists():
            recovery_by_path.update({x["path"]: x for x in load(DATA / filename)})
    for row in dispositions:
        if row["path"] in recovery_by_path:
            row.update(recovery_by_path[row["path"]])
    save(DATA / "managed_resources.json", embedded)
    save(DATA / "binary_dispositions.json", dispositions)
    dump = (ROOT / "tools/Il2CppDumper/Il2CppDumper/bin/Release/net8.0/dump.cs").read_text(encoding="utf-8-sig")
    images = [(int(start), name) for name, start in re.findall(r"^// Image \d+: (.+?) - (\d+)$", dump, re.M)]
    starts = [x[0] for x in images]
    types = []
    namespace = ""
    for number, line in enumerate(dump.splitlines(), 1):
        if line.startswith("// Namespace:"):
            namespace = line.partition(":")[2].strip()
        match = re.search(r"\b(class|struct|enum|interface)\s+(.+?)\s+// TypeDefIndex: (\d+)", line)
        if match:
            index = int(match[3])
            image = images[bisect.bisect_right(starts, index) - 1][1]
            types.append({"type_index": index, "kind": match[1], "declaration": match[2],
                          "namespace": namespace, "image": image, "dump_line": number})
    save(DATA / "native_types.json", types)
    summary = load(DATA / "native_summary.json")
    summary.update({"type_kinds": dict(collections.Counter(x["kind"] for x in types)),
                    "types_by_image": dict(collections.Counter(x["image"] for x in types)),
                    "parsed_types": len(types)})
    save(DATA / "native_summary.json", summary)
    texts = load(DATA / "textassets.json")
    spine = {x["sha256"]: x for filename in ("spine_skeletons.json", "spine_animations.json")
             for x in load(DATA / filename)}
    for text in texts:
        if text["sha256"] in spine:
            result = spine[text["sha256"]]
            text.update({"status": "spine_" + result["status"], "decoded_path": result.get("decoded_path"),
                         "format": "spine_skeleton" if text["name"].endswith(".skel") else "spine_animation"})
            text.pop("error", None)
    save(DATA / "textassets.json", texts)
    print({"managed_members": len(embedded), "binary_status": dict(collections.Counter(x["status"] for x in dispositions)),
           "types": len(types), "text_status": dict(collections.Counter(x["status"] for x in texts))})


if __name__ == "__main__":
    main()
