"""Decode AQKV tables using the paired native reader's bounds and record sizes."""
import io
import struct

from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
from elftools.elf.elffile import ELFFile
from audit_gh_resources import DATA, ROOT, load, relative, save, write_bytes


def main():
    entries = load(DATA / "apk_entries.json")
    source = next(x for x in entries if x["entry"] == "assets/vkqualitydata.vkq")
    library = next(x for x in entries if x["entry"].endswith("/libvkquality.so"))
    raw = (ROOT / source["path"]).read_bytes()
    header = struct.unpack_from("<22I", raw)
    if raw[:4] != b"AQKV" or len(raw) < 88:
        raise ValueError("Invalid AQKV header")
    # ValidateFile uses these count/offset pairs and strides verbatim.
    layouts = [("device_records", 20, 52, 16), ("gpu_indices", 24, 60, 4),
               ("driver_indices", 28, 64, 4), ("table_4", 32, 68, 20),
               ("table_5", 36, 72, 20), ("table_6", 40, 76, 12),
               ("table_7", 44, 80, 12), ("string_offsets", 48, 84, 4)]
    spans = [{"name": "header", "start": 0, "end": 88}]
    tables = {}
    for name, count_at, offset_at, stride in layouts:
        count, offset = header[count_at // 4], header[offset_at // 4]
        end = offset + count * stride
        if offset < 88 or end > len(raw):
            raise ValueError(f"Invalid {name} extent")
        tables[name] = {"count": count, "offset": offset, "stride": stride,
            "records": [list(struct.unpack_from("<" + "I" * (stride // 4), raw, p))
                        for p in range(offset, end, stride)]}
        spans.append({"name": name, "start": offset, "end": end})
    strings = []
    for (offset,) in tables["string_offsets"]["records"]:
        end = raw.index(b"\0", offset) + 1
        strings.append({"offset": offset, "end": end, "value": raw[offset:end - 1].decode("utf-8")})
        spans.append({"name": "string", "start": offset, "end": end})
    prediction = header[56 // 4]
    spans.append({"name": "prediction_parameters", "start": prediction, "end": prediction + 108})
    tables["prediction_parameters"] = {"offset": prediction,
        "u32": list(struct.unpack_from("<27I", raw, prediction)),
        "f32": list(struct.unpack_from("<27f", raw, prediction))}
    coverage = bytearray(len(raw))
    for span in spans:
        if span["end"] > len(raw):
            raise ValueError("Span outside input")
        coverage[span["start"]:span["end"]] = b"\1" * (span["end"] - span["start"])
    uncovered = [i for i, value in enumerate(coverage) if not value]
    if uncovered:
        raise ValueError(f"Unaccounted AQKV bytes: {uncovered[:20]}")
    rebuilt = bytearray(len(raw))
    struct.pack_into("<22I", rebuilt, 0, *header)
    for table in tables.values():
        if "records" in table:
            for index, record in enumerate(table["records"]):
                struct.pack_into("<" + "I" * len(record), rebuilt, table["offset"] + index * table["stride"], *record)
    struct.pack_into("<27I", rebuilt, prediction, *tables["prediction_parameters"]["u32"])
    for string in strings:
        rebuilt[string["offset"]:string["end"]] = string["value"].encode("utf-8") + b"\0"
    if bytes(rebuilt) != raw:
        raise ValueError("AQKV re-encoding mismatch")
    elf = ELFFile(io.BytesIO((ROOT / library["path"]).read_bytes()))
    text = elf.get_section_by_name(".text")
    md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    evidence = []
    for symbol in elf.get_section_by_name(".dynsym").iter_symbols():
        if "VkQualityPredictionFile" not in symbol.name or not symbol["st_size"]:
            continue
        start = symbol["st_value"] - text["sh_addr"]
        evidence.append(symbol.name + "\n" + "\n".join(
            f"{i.address:x}: {i.mnemonic} {i.op_str}" for i in md.disasm(
                text.data()[start:start + symbol["st_size"]], symbol["st_value"])))
    target = DATA / "binary_decoded" / (source["sha256"] + ".json")
    write_bytes(target.with_suffix(".reader.asm"), "\n\n".join(evidence).encode())
    save(target, {"source": source["path"], "sha256": source["sha256"], "bytes": len(raw),
        "header_u32": header, "tables": tables, "strings": strings,
        "covered_bytes": sum(coverage), "spans": spans, "roundtrip_bytes_equal": True,
        "reader": library["path"], "reader_sha256": library["sha256"],
        "scope": "All bytes assigned to header, strings and fixed records; table_4..7 field semantics require reader review"})
    save(DATA / "vkquality_recovery.json", [{"path": source["path"], "status": "wire_decoded",
        "format": "vulkan_quality_database", "decoded_path": relative(target),
        "evidence": "Native ValidateFile/ParseFileData/GetString layouts; complete byte coverage, record semantics partly pending"}])
    print({"bytes": len(raw), "covered": sum(coverage), "strings": len(strings), "tables": {k: v.get("count") for k, v in tables.items()}})


if __name__ == "__main__":
    main()
