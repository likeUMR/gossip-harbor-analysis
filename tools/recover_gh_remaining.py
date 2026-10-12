"""Recover nested code and structural metadata from previously opaque files."""
import io
import re
import struct

from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM, CS_MODE_LITTLE_ENDIAN, CS_ARCH_X86, CS_MODE_32, CS_MODE_64, CS_ARCH_ARM64
from elftools.elf.elffile import ELFFile

from audit_gh_resources import DATA, ROOT, load, relative, save, sha, write_bytes


def protobuf(raw):
    offset = 0

    def varint():
        nonlocal offset
        result = 0
        for shift in range(0, 70, 7):
            if offset >= len(raw):
                raise ValueError("Truncated protobuf varint")
            value = raw[offset]
            offset += 1
            result |= (value & 127) << shift
            if value < 128:
                return result
        raise ValueError("Oversized protobuf varint")

    fields = []
    while offset < len(raw):
        start = offset
        tag = varint()
        number, wire = tag >> 3, tag & 7
        if not number:
            raise ValueError("Invalid protobuf field zero")
        item = {"field": number, "wire": wire, "offset": start}
        if wire == 0:
            item["value"] = varint()
        elif wire in (1, 5):
            size = 8 if wire == 1 else 4
            if offset + size > len(raw):
                raise ValueError("Truncated protobuf fixed field")
            item["hex"] = raw[offset:offset + size].hex()
            offset += size
        elif wire == 2:
            size = varint()
            payload = raw[offset:offset + size]
            if len(payload) != size:
                raise ValueError("Truncated protobuf length field")
            offset += size
            item.update({"bytes": size, "hex": payload.hex()})
            try:
                text = payload.decode("utf-8")
                if text.isprintable():
                    item["text"] = text
            except UnicodeDecodeError:
                pass
            if payload and "text" not in item:
                try:
                    item["possible_message"] = protobuf(payload)
                except ValueError:
                    pass
        else:
            raise ValueError(f"Unsupported protobuf wire type {wire}")
        item["end"] = offset
        fields.append(item)
    return fields


def main():
    entries = load(DATA / "apk_entries.json")
    source = next(x for x in entries if x["entry"] == "assets/dic")
    encrypted = (ROOT / source["path"]).read_bytes()
    key = b"dic"
    raw = bytes(value ^ key[index % 3] for index, value in enumerate(encrypted))
    destination = DATA / "nested_code" / sha(raw)
    decoded = destination / "dic.elf"
    write_bytes(decoded, raw)
    elf = ELFFile(io.BytesIO(raw))
    architecture, mode = {"EM_ARM": (CS_ARCH_ARM, CS_MODE_ARM | CS_MODE_LITTLE_ENDIAN),
                          "EM_386": (CS_ARCH_X86, CS_MODE_32), "EM_X86_64": (CS_ARCH_X86, CS_MODE_64),
                          "EM_AARCH64": (CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)}[elf["e_machine"]]
    md = Cs(architecture, mode)
    md.skipdata = True
    sections = []
    for section in elf.iter_sections():
        if not section["sh_flags"] & 4 or section["sh_type"] == "SHT_NOBITS":
            continue
        data = section.data()
        instructions = list(md.disasm_lite(data, section["sh_addr"]))
        target = destination / (section.name + ".asm")
        target.write_text("".join(f"{a:08x}: {m} {o}\n" for a, n, m, o in instructions), encoding="utf-8")
        covered = sum(x[1] for x in instructions)
        if covered != len(data):
            raise ValueError("Incomplete dic instruction coverage")
        sections.append({"name": section.name, "bytes": len(data), "covered_bytes": covered,
                         "lines": len(instructions), "path": relative(target),
                         "decoding": "ELF machine mode; instruction/data boundaries require symbol-guided review"})
    result = {"source": source["path"], "source_sha256": source["sha256"],
              "decoded_path": relative(decoded), "sha256": sha(raw), "bytes": len(raw),
              "machine": elf["e_machine"], "entry": elf["e_entry"], "sections": sections,
              "strings": [x.decode("ascii") for x in re.findall(rb"[ -~]{4,}", raw)],
              "status": "decrypted_elf", "reader": "com.pgl.ssdk.af.a(Context), af.a(byte[],int,byte[])",
              "algorithm": "Each read block XOR with repeating UTF-8 dic; file is shorter than one 4096-byte read block",
              "limitation": "SDK code recovered; executable has not been run"}
    save(destination / "index.json", result)
    save(DATA / "nested_code.json", [result])
    source = next(x for x in entries if "billingclient_heterodyne" in x["entry"])
    raw = (ROOT / source["path"]).read_bytes()
    fields = protobuf(raw)
    def encode_varint(value):
        output = bytearray()
        while value > 127:
            output.append((value & 127) | 128)
            value >>= 7
        output.append(value)
        return bytes(output)
    rebuilt = bytearray()
    for field in fields:
        rebuilt.extend(encode_varint(field["field"] << 3 | field["wire"]))
        if field["wire"] == 0:
            rebuilt.extend(encode_varint(field["value"]))
        else:
            payload = bytes.fromhex(field["hex"])
            if field["wire"] == 2:
                rebuilt.extend(encode_varint(len(payload)))
            rebuilt.extend(payload)
    if bytes(rebuilt) != raw:
        raise ValueError("Billing protobuf re-encoding mismatch")
    target = DATA / "binary_decoded" / (source["sha256"] + ".json")
    save(target, {"source": source["path"], "sha256": source["sha256"], "bytes": len(raw),
                  "consumed_bytes": len(raw), "fields": fields, "roundtrip_bytes_equal": True,
                  "scope": "Complete wire structure; possible_message is structural interpretation, field semantics not inferred"})
    save(DATA / "remaining_binary_recoveries.json", [
        {"path": result["source"], "status": "recovered", "format": "xor_protected_elf",
         "decoded_path": result["decoded_path"], "evidence": result["reader"]},
        {"path": source["path"], "status": "wire_decoded", "format": "billing_protobuf_metadata",
         "decoded_path": relative(target), "evidence": "Complete protobuf wire parsing; schema semantics remain unconfirmed"},
    ])
    print({"dic": result["status"], "dic_sections": len(sections), "billing_bytes": len(raw)})


if __name__ == "__main__":
    main()
