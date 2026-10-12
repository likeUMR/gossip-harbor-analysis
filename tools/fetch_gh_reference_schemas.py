"""Cache schema reference sources with URL and content fingerprint."""
from audit_gh_resources import DATA, save, sha, write_bytes
from bootstrap_logic_tools import fetch


def main():
    sources = [
        ("unity_2022.3.62f2.json", "https://cdn.jsdelivr.net/gh/AssetRipper/TypeTreeDumps@main/InfoJson/2022.3.62f2.json"),
        ("GUISkin.cs", "https://raw.githubusercontent.com/Unity-Technologies/UnityCsReference/2022.3/Modules/IMGUI/GUISkin.cs"),
    ]
    records = []
    for name, url in sources:
        target = DATA / "schema_sources" / name
        if not target.exists():
            raw, resolved = fetch(url)
            write_bytes(target, raw)
        else:
            resolved = url
        records.append({"name": name, "url": url, "resolved_url": resolved, "sha256": sha(target.read_bytes())})
    save(DATA / "schema_sources/references.json", records)


if __name__ == "__main__":
    main()
