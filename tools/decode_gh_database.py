"""Read the recorded database using the key proven by the native initializer."""
import collections
import hashlib
import json
import sqlite3

import sqlcipher3
from elftools.elf.elffile import ELFFile
from elftools.elf.relocation import RelocationSection

from audit_gh_resources import DATA, ROOT, SAMPLE, load, relative, save


def main():
    source = SAMPLE / "runtime/db.sqlite3"
    elfpath = SAMPLE / "native_extracted/lib/arm64-v8a/libil2cpp.so"
    with elfpath.open("rb") as handle:
        elf = ELFFile(handle)
        pointer = next(r["r_addend"] for section in elf.iter_sections() if isinstance(section, RelocationSection)
                       for r in section.iter_relocations() if r["r_offset"] == 0x22CF3A8)
    script = load(ROOT / "tools/Il2CppDumper/Il2CppDumper/bin/Release/net8.0/script.json")
    password = next(x["Value"] for x in script["ScriptString"] if x["Address"] == pointer)
    out = DATA / "database"
    out.mkdir(exist_ok=True)
    copied = out / "encrypted_copy.sqlite3"
    copied.write_bytes(source.read_bytes())
    attempts = []
    for version in (4, 3, 2, 1):
        connection = sqlcipher3.connect(str(copied))
        try:
            connection.execute("PRAGMA key = '" + password.replace("'", "''") + "'")
            connection.execute(f"PRAGMA cipher_compatibility={version}")
            tables = connection.execute("SELECT name,sql FROM sqlite_master WHERE type='table'").fetchall()
            integrity = connection.execute("PRAGMA integrity_check").fetchall()
            target = out / ("decrypted_" + hashlib.sha256(source.read_bytes()).hexdigest()[:12] + ".sqlite3")
            # SQLCipher's export preserves schema and values in a plaintext database.
            if not target.exists():
                connection.execute("ATTACH DATABASE '" + str(target).replace("'", "''") + "' AS plaintext KEY ''")
                connection.execute("SELECT sqlcipher_export('plaintext')").fetchall()
                connection.execute("DETACH DATABASE plaintext")
            with sqlite3.connect(str(target)) as plain:
                if plain.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
                    raise ValueError("Plaintext database integrity check failed")
            rows = []
            for name, schema in tables:
                safe = '"' + name.replace('"', '""') + '"'
                values = connection.execute(f"SELECT * FROM {safe}").fetchall()
                columns = [x[1] for x in connection.execute(f"PRAGMA table_info({safe})")]
                rows.append({"name": name, "schema": schema, "columns": columns, "rows": len(values)})
                save(out / (hashlib.sha256(name.encode()).hexdigest() + ".json"),
                     {"table": name, "columns": columns, "rows": values})
            save(DATA / "database_summary.json", {"status": "decrypted", "compatibility": version,
                 "source": relative(source), "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                 "output": relative(target), "integrity_check": integrity, "tables": rows,
                 "key_evidence": {"initializer_rva": "0x136DE64", "relocation_slot": "0x22CF3A8",
                                  "string_literal_address": hex(pointer)},
                 "scope": "Recorded 2026-09-22 device database; not a complete server configuration snapshot"})
            print(f"Database decrypted: SQLCipher compatibility {version}, tables={len(rows)}")
            return
        except Exception as exc:
            attempts.append({"compatibility": version, "error": repr(exc)})
        finally:
            connection.close()
    save(DATA / "database_summary.json", {"status": "failed", "attempts": attempts})
    print(attempts)


if __name__ == "__main__":
    main()
