"""Decrypt Gossip Harbor's Lua bytecode using the algorithm recovered from IL2CPP.

The native Crypt.CryptBytes implementation is equivalent to:
    bytes[i] ^= key[i % len(key)]
The operation is symmetric, so running this on an already decrypted file
re-encrypts it.  Unity TextAsset containers should be unpacked with
extract_lua_config.py first.
"""
from __future__ import annotations

import argparse
from pathlib import Path


KEY = b"*(Vd7@4&(*)VK~5hjLH-+~N7J!83jkl)*6(&#65gdsw43t515fg(*^)#kJLHG"


def xor_cycle(data: bytes, key: bytes = KEY) -> bytes:
    if not key:
        raise ValueError("key must not be empty")
    return bytes(value ^ key[i % len(key)] for i, value in enumerate(data))


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("output", type=Path)
    args = p.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(xor_cycle(args.input.read_bytes()))
    print(f"wrote {args.output} ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
