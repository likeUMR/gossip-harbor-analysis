"""Reproduce the captured AFk1rSDK block reader; accept only validated ZIP/DEX output."""
import hashlib
import io
import math
import struct
import zipfile
import zlib

from audit_gh_resources import DATA, ROOT, load, relative, save, sha, write_bytes


def decrypt(raw, key_pair, multiplier, iv, rounds):
    mask = 0xFFFFFFFF
    delta = int((math.sqrt(5) - 1) * 32768)
    if delta >= 32768:
        delta -= 65536
    high, low = key_pair
    keys = (low & mask, (low * multiplier) & mask, (multiplier ^ low) & mask, high & mask)
    blocks = []
    previous = iv
    if len(raw) % 8:
        raise ValueError("Ciphertext block length mismatch")
    for offset in range(0, len(raw), 8):
        cipher = raw[offset:offset + 8]
        left, right = struct.unpack(">II", cipher)
        for index in range(rounds):
            total = (rounds - index) * delta
            right = (right - (((total + left) ^ ((left << 4) + keys[2])) ^ ((left >> 5) + keys[3]))) & mask
            left = (left - ((((right << 4) + keys[0]) ^ (total + right)) ^ ((right >> 5) + keys[1]))) & mask
        plain = struct.pack(">II", left, right)
        blocks.append(bytes(a ^ b for a, b in zip(plain, previous)))
        previous = cipher
    plain = b"".join(blocks)
    padding = plain[-1]
    if padding not in range(1, 9):
        raise ValueError("Invalid stream padding")
    return plain[:-padding]


def main():
    attempts = []
    recovered = []
    for entry in load(DATA / "apk_entries.json"):
        if "/appsflyer/internal/" not in entry["entry"]:
            continue
        raw = (ROOT / entry["path"]).read_bytes()
        prefix = b"java/lang/Integer" if raw.startswith(b"java/lang/Integer") else b"java/io/Serializable"
        try:
            ciphertext = bytearray(raw[len(prefix):])
            if entry["entry"].endswith("2b7867f15e66c02ea-"):
                ciphertext[164] = (ciphertext[7287] - 34) & 255
            elif entry["entry"].endswith("eebc3677933725bab-"):
                ciphertext[164] = (ciphertext[7287] - 34) & 255
            elif entry["entry"].endswith("d1bb394ba89138f2d-"):
                ciphertext[393] = (ciphertext[-1] + 84) & 255
            if entry["entry"].endswith("28445207a6f5af97c-"):
                ciphertext[393] = (ciphertext[3479] + 84) & 255
                params = ((2113892627, 461291458), -2091678486, (38, 96, 106, -118, 84, -88, -26, -119), 16)
            elif entry["entry"].endswith("eebc3677933725bab-"):
                params = ((1847975672, -1763660995), -243011232, (105, -55, -47, -11, -24, -123, -62, 110), 22)
            else:
                params = ((325172741, -1983728058), 578427012, (38, -99, -103, -111, 76, -9, -5, 67), 22)
            if entry["entry"].endswith("d1bb394ba89138f2d-"):
                plain = decrypt_stream(ciphertext, -913485736, -1990295237, 4, -903406016, 870548081)
                params = (None, None, None, 16)
            else:
                plain = decrypt(ciphertext, params[0], params[1], bytes(x & 255 for x in params[2]), 5)
            payload = plain[params[3]:]
            archive = zipfile.ZipFile(io.BytesIO(payload))
            if archive.testzip() is not None:
                raise ValueError("Decrypted ZIP CRC failed")
            directory = DATA / "android/protected_decoded" / entry["sha256"]
            write_bytes(directory / "decrypted.zip", payload)
            members = []
            for name in archive.namelist():
                data = archive.read(name)
                if name.endswith(".dex"):
                    if not data.startswith(b"dex\n") or len(data) != struct.unpack_from("<I", data, 32)[0]:
                        raise ValueError("DEX header/length mismatch")
                    if hashlib.sha1(data[32:]).digest() != data[12:32] or zlib.adler32(data[12:]) != struct.unpack_from("<I", data, 8)[0]:
                        raise ValueError("DEX integrity mismatch")
                target = directory / name
                if not target.resolve().is_relative_to(directory.resolve()):
                    raise ValueError("Invalid archive member path")
                write_bytes(target, data)
                members.append({"name": name, "path": relative(target), "sha256": sha(data), "bytes": len(data)})
            row = {"path": entry["path"], "sha256": entry["sha256"], "status": "recovered",
                   "format": "protected_dex_zip", "members": members,
                   "decrypted_path": relative(directory / "decrypted.zip"),
                   "encrypted_prefix_bytes": len(prefix), "decrypted_preamble_hex": plain[:params[3]].hex(),
                   "evidence": "SDK initializer and nested loader captures + AFk1rSDK/AFk1tSDK algorithms; ZIP CRC and DEX SHA1/Adler32 verified"}
            recovered.append(row)
            attempts.append({"path": entry["path"], "status": "recovered"})
        except Exception as error:
            attempts.append({"path": entry["path"], "status": "failed", "error": str(error)})
    save(DATA / "appsflyer_recoveries.json", recovered)
    save(DATA / "appsflyer_attempts.json", attempts)
    print(attempts)


def decrypt_stream(raw, first, second, block, third, fourth):
    def signed(value):
        value &= (1 << 64) - 1
        return value - (1 << 64) if value >= (1 << 63) else value

    def seed(high, low):
        values = [signed(((high & 0xFFFFFFFF) << 32) | (low & 0xFFFFFFFF))]
        for index in range(1, 4):
            previous = values[-1]
            values.append(signed((previous ^ (previous >> 30)) * 1812433253 + index))
        return values

    a, b = seed(first ^ fourth, block ^ fourth), seed(second ^ fourth, third ^ fourth)
    output = bytearray()
    for offset in range(0, len(raw), block):
        index = (offset // block) % 4
        j = b[(index + 2) % 4]
        following = (index + 3) % 4
        total = signed(signed(a[following] * 2147483085) + j)
        b[following] = (abs(total) // 2147483647) * (-1 if total < 0 else 1)
        total = signed(signed(a[index] * 2147483085) + j)
        a[following] = total - ((abs(total) // 2147483647) * (-1 if total < 0 else 1)) * 2147483647
        output.extend(value ^ ((a[index] >> (position * 8)) & 255)
                      for position, value in enumerate(raw[offset:offset + block]))
    padding = output[-1]
    if not 1 <= padding <= block:
        raise ValueError("Invalid stream padding")
    return bytes(output[:-padding])


if __name__ == "__main__":
    main()
