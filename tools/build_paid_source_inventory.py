from pathlib import Path
import hashlib
import json
import re

root = Path("analysis_data/luac_disasm")
patterns = [
    "Model/Bundle/*.luac.txt",
    "Model/Shop/*.luac.txt",
    "Model/InAppPurchase/*.luac.txt",
    "Data/Config/Shop*.luac.txt",
    "Data/Config/BundleConfig.luac.txt",
]
paths = []
for pattern in patterns:
    paths.extend(root.glob(pattern))

rows = []
for path in sorted(set(paths)):
    raw = path.read_bytes()
    text = raw.decode("utf-8", errors="ignore")
    names = []
    for match in re.finditer(r'SETTABLE\s+[^;]*; "([A-Za-z0-9_]+)"', text):
        name = match.group(1)
        if name not in names:
            names.append(name)
    rows.append({
        "path": path.as_posix(),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "bytes": len(raw),
        "function_or_field_names": names,
        "name_count": len(names),
    })

output = Path("analysis_output/logic_recovery/stage3/paid_gate_audit")
output.mkdir(parents=True, exist_ok=True)
(output / "paid_source_inventory.json").write_text(
    json.dumps({
        "version_scope": "GH 3.98.10 recovered client snapshot",
        "files": rows,
        "file_count": len(rows),
        "name_count": sum(row["name_count"] for row in rows),
    }, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
print(f"files={len(rows)} names={sum(row['name_count'] for row in rows)}")
