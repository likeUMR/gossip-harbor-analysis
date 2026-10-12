import argparse
import struct
from pathlib import Path

import UnityPy


CRYPT_KEY = b"*(Vd7@4&(*)VK~5hjLH-+~N7J!83jkl)*6(&#65gdsw43t515fg(*^)#kJLHG"


def text_asset_bytes(bundle_path: Path, asset_name: str) -> bytes:
    env = UnityPy.load(str(bundle_path))
    obj = next(
        obj
        for obj in env.objects
        if obj.type.name == "TextAsset" and obj.read().m_Name == asset_name
    )
    raw = obj.get_raw_data()
    name_length = struct.unpack_from("<I", raw, 0)[0]
    value_offset = (4 + name_length + 3) & ~3
    value_length = struct.unpack_from("<I", raw, value_offset)[0]
    return raw[value_offset + 4 : value_offset + 4 + value_length]


def decrypt(data: bytes) -> bytes:
    return bytes(value ^ CRYPT_KEY[index % len(CRYPT_KEY)] for index, value in enumerate(data))


def unpack_modules(data: bytes):
    offset = 0
    module_count = struct.unpack_from("<I", data, offset)[0]
    offset += 4
    for _ in range(module_count):
        name_length = struct.unpack_from("<H", data, offset)[0]
        offset += 2
        name = data[offset : offset + name_length].decode("utf-8")
        offset += name_length
        value_length = struct.unpack_from("<I", data, offset)[0]
        offset += 4
        value = data[offset : offset + value_length]
        offset += value_length
        yield name, value
    if offset != len(data):
        raise ValueError(f"Archive ended at {offset}, expected {len(data)} bytes")


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract encrypted Gossip Harbor Lua config modules")
    parser.add_argument("bundle", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--asset-name", default="Lua_Config")
    args = parser.parse_args()

    encrypted = text_asset_bytes(args.bundle, args.asset_name)
    modules = list(unpack_modules(decrypt(encrypted)))
    args.output.mkdir(parents=True, exist_ok=True)
    for name, value in modules:
        output_path = args.output.joinpath(*name.split(".")).with_suffix(".luac")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(value)
    print(f"Extracted {len(modules)} modules to {args.output}")


if __name__ == "__main__":
    main()
