"""Extract non-visual Unity Addressables content from the Gossip Harbor APK.

This intentionally skips textures, sprites, meshes, animation, audio and video.
It exports TextAsset bytes and MonoBehaviour typetrees so numeric/config data can
be searched without expanding the artwork-heavy bundles.
"""
from __future__ import annotations

import io
import json
import os
import re
import zipfile
from pathlib import Path

import UnityPy


APK = Path(__file__).resolve().parents[1] / "apk_extract" / "gossip_harbor_3.98.10" / "base.apk"
OUT = APK.parent / "nonvisual_configs"

KEYWORDS = re.compile(
    r"(?i)(order|generator|bubble|freeze|shop|smile|task|energy|reward|coin|gem|chest|price|cost|cooldown|lucky|produce|drop|weight|prob|level|item|merge|board|chain|star|exp|experience|gold)"
)
SKIP_TYPES = {
    "Texture2D", "Sprite", "Mesh", "MeshFilter", "MeshRenderer", "SkinnedMeshRenderer",
    "AudioClip", "VideoClip", "AnimationClip", "Animator", "AnimatorController",
    "ParticleSystem", "ParticleSystemRenderer", "Material", "Shader", "Font", "TMP_FontAsset",
}


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value.encode("utf-8", "replace").decode("utf-8"))


def relevant(bundle: str, names: list[str], fields: list[str]) -> bool:
    haystack = " ".join([bundle, *names, *fields])
    return bool(KEYWORDS.search(haystack))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    text_dir = OUT / "textassets"
    text_dir.mkdir(exist_ok=True)
    rows = []

    with zipfile.ZipFile(APK) as apk:
        bundles = [n for n in apk.namelist() if n.startswith("assets/aa/android/") and n.endswith(".bundle")]
        for bundle_name in bundles:
            try:
                env = UnityPy.load(io.BytesIO(apk.read(bundle_name)))
            except Exception as exc:
                rows.append({"bundle": bundle_name, "error": repr(exc)})
                continue

            names: list[str] = []
            fields: set[str] = set()
            objects = []
            for obj in env.objects:
                typ = obj.type.name
                if typ in SKIP_TYPES:
                    continue
                try:
                    data = obj.read()
                    obj_name = str(getattr(data, "m_Name", "") or "")
                except Exception:
                    obj_name = ""
                if obj_name:
                    names.append(obj_name)

                if typ == "TextAsset":
                    try:
                        payload = data.m_Script
                        if isinstance(payload, str):
                            payload = payload.encode("utf-8", "replace")
                        filename = f"{safe_name(Path(bundle_name).stem)}__{safe_name(obj_name or 'unnamed')}.bin"
                        (text_dir / filename).write_bytes(payload)
                        objects.append({"type": typ, "name": obj_name, "file": str(Path("textassets") / filename), "size": len(payload)})
                    except Exception as exc:
                        objects.append({"type": typ, "name": obj_name, "error": repr(exc)})
                    continue

                if typ == "MonoBehaviour":
                    try:
                        tree = obj.read_typetree()
                        fields.update(str(k) for k in tree.keys())
                        if relevant(bundle_name, [obj_name], list(tree.keys())):
                            objects.append({"type": typ, "name": obj_name, "typetree": tree})
                    except Exception as exc:
                        objects.append({"type": typ, "name": obj_name, "error": repr(exc)})

            if objects and relevant(bundle_name, names, list(fields)):
                rows.append({"bundle": bundle_name, "objects": objects, "names": names[:300], "fields": sorted(fields)})

    (OUT / "index.json").write_text(json.dumps(rows, ensure_ascii=True, indent=2, default=str), encoding="utf-8")
    summary = {
        "apk": str(APK),
        "bundle_count": len(bundles),
        "relevant_bundle_count": sum(1 for row in rows if "objects" in row),
        "textasset_count": sum(sum(1 for obj in row.get("objects", []) if obj.get("type") == "TextAsset") for row in rows),
        "typetree_count": sum(sum(1 for obj in row.get("objects", []) if "typetree" in obj) for row in rows),
        "output": str(OUT),
    }
    (OUT / "summary.json").write_text(json.dumps(summary, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=True, indent=2))


if __name__ == "__main__":
    main()
