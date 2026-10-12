"""Strict reader for this sample's format-1 Lua 5.3 chunks.

The format-1 header omits size_t. Long strings use uint32 lengths.
Conversion changes serialization only; it never repairs instructions.
"""
import struct


OPCODES = "MOVE LOADK LOADKX LOADBOOL LOADNIL GETUPVAL GETTABUP GETTABLE SETTABUP SETUPVAL SETTABLE NEWTABLE SELF ADD SUB MUL MOD POW DIV IDIV BAND BOR BXOR SHL SHR UNM BNOT NOT LEN CONCAT JMP EQ LT LE TEST TESTSET CALL TAILCALL RETURN FORLOOP FORPREP TFORCALL TFORLOOP SETLIST CLOSURE VARARG EXTRAARG".split()


class Chunk:
    def __init__(self, data):
        self.data = data
        self.offset = 0
        self.functions = []
        if self.take(12) != b"\x1bLua\x53\x01\x19\x93\r\n\x1a\n":
            raise ValueError("Unsupported chunk signature/version/format")
        if self.take(4) != bytes([4, 4, 8, 8]):
            raise ValueError("Unsupported scalar sizes")
        if self.take(8) != struct.pack("<q", 0x5678) or self.take(8) != struct.pack("<d", 370.5):
            raise ValueError("Unsupported endian/number encoding")
        self.upvalues = self.take(1)
        self.root = self.proto("0", None)
        if self.offset != len(data):
            raise ValueError(f"Trailing bytes: {len(data) - self.offset}")
        if self.upvalues[0] != len(self.root["upvalues"]) // 2:
            raise ValueError("Main upvalue count mismatch")

    def take(self, size):
        if size < 0 or self.offset + size > len(self.data):
            raise ValueError(f"Truncated chunk at {self.offset}, length {size}")
        result = self.data[self.offset:self.offset + size]
        self.offset += size
        return result

    def uint(self):
        return struct.unpack("<I", self.take(4))[0]

    def string(self):
        size = self.take(1)[0]
        if size == 0:
            return None
        if size == 255:
            size = self.uint()
        if size == 0:
            raise ValueError("Invalid zero long-string length")
        return self.take(size - 1)

    def proto(self, key, inherited_source):
        start = self.offset
        source = self.string()
        first, last = self.uint(), self.uint()
        args = self.take(3)
        code = self.take(self.uint() * 4)
        constants = []
        strings = []
        for _ in range(self.uint()):
            tag = self.take(1)[0]
            if tag == 0:
                value = b""
            elif tag == 1:
                value = self.take(1)
            elif tag in (3, 19):
                value = self.take(8)
            elif tag in (4, 20):
                value = self.string()
                if value is None:
                    raise ValueError("Null string constant")
                strings.append(value.decode("utf-8", errors="replace"))
            else:
                raise ValueError(f"Unsupported constant tag {tag} at {self.offset}")
            constants.append((tag, value))
        upvalues = self.take(self.uint() * 2)
        result = {"key": key, "offset": start, "source": source, "first": first,
                  "last": last, "args": args, "code": code, "constants": constants,
                  "upvalues": upvalues, "strings": strings}
        self.functions.append(result)
        actual_source = source if source is not None else inherited_source
        result["resolved_source"] = actual_source
        result["children"] = [self.proto(f"{key}.{i}", actual_source) for i in range(self.uint())]
        lines = self.uint()
        if lines not in (0, len(code) // 4):
            raise ValueError("Instruction / line table mismatch")
        result["lines"] = self.take(lines * 4)
        result["locals"] = [(self.string(), self.uint(), self.uint()) for _ in range(self.uint())]
        result["upnames"] = [self.string() for _ in range(self.uint())]
        result["end_offset"] = self.offset
        for pc, (instruction,) in enumerate(struct.iter_unpack("<I", code)):
            op = instruction & 63
            if op >= len(OPCODES):
                raise ValueError(f"Unknown opcode {op}")
            bx = instruction >> 14
            if OPCODES[op] == "CLOSURE" and bx >= len(result["children"]):
                raise ValueError(f"Invalid child index at {key}:{pc}")
            if OPCODES[op] == "LOADK" and bx >= len(constants):
                raise ValueError(f"Invalid constant index at {key}:{pc}")
        return result

    def standard(self):
        def integer(n):
            return struct.pack("<I", n)

        def string(value):
            if value is None:
                return b"\0"
            size = len(value) + 1
            return (bytes([size]) if size < 255 else b"\xff" + struct.pack("<Q", size)) + value

        def proto(f):
            parts = [string(f["source"]), integer(f["first"]), integer(f["last"]), f["args"],
                     integer(len(f["code"]) // 4), f["code"], integer(len(f["constants"]))]
            for tag, value in f["constants"]:
                parts.extend([bytes([tag]), string(value) if tag in (4, 20) else value])
            parts.extend([integer(len(f["upvalues"]) // 2), f["upvalues"], integer(len(f["children"]))])
            parts.extend(proto(child) for child in f["children"])
            parts.extend([integer(len(f["lines"]) // 4), f["lines"], integer(len(f["locals"]))])
            for name, first, last in f["locals"]:
                parts.extend([string(name), integer(first), integer(last)])
            parts.append(integer(len(f["upnames"])))
            parts.extend(string(name) for name in f["upnames"])
            return b"".join(parts)

        header = b"\x1bLua\x53\0\x19\x93\r\n\x1a\n" + bytes([4, 8, 4, 8, 8])
        return header + struct.pack("<qd", 0x5678, 370.5) + self.upvalues + proto(self.root)


if __name__ == "__main__":
    import argparse
    from pathlib import Path
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--standard", type=Path)
    args = parser.parse_args()
    chunk = Chunk(args.input.read_bytes())
    print(f"Parsed {len(chunk.functions)} prototypes; consumed {chunk.offset} bytes")
    if args.standard:
        args.standard.parent.mkdir(parents=True, exist_ok=True)
        args.standard.write_bytes(chunk.standard())
