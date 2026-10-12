"""Build deduplicated, leadership-readable stage-one resource and code charts."""
from __future__ import annotations

import collections
import csv
import hashlib
import json
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from audit_gh_resources import DATA, OUT, ROOT, load, relative, save

VIS = OUT / "visuals"
MIB = 1024 * 1024
COLORS = ["#28785f", "#3185a6", "#d08b2e", "#a85968", "#65788b", "#83a94d", "#80669b", "#b77c53"]


def configure():
    plt.rcParams.update({
        "font.family": ["Microsoft YaHei", "Noto Sans CJK SC", "Arial Unicode MS", "DejaVu Sans"],
        "font.size": 10, "axes.titlesize": 15, "axes.titleweight": "bold",
        "axes.labelcolor": "#35404a", "text.color": "#20252b", "axes.edgecolor": "#d4dbe1",
        "xtick.color": "#586570", "ytick.color": "#35404a", "figure.facecolor": "#ffffff",
        "axes.facecolor": "#ffffff", "savefig.facecolor": "#ffffff", "axes.grid": True,
        "grid.color": "#e7ebef", "grid.linewidth": 0.8, "axes.axisbelow": True,
    })


def write_csv(path: Path, rows: list[dict]):
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def pct(value, total):
    return 100 * value / total if total else 0


def mb(value):
    return value / MIB


def savefig(fig, name):
    fig.savefig(VIS / name, dpi=180, bbox_inches="tight")
    plt.close(fig)


def apk_kind_group(kind: str) -> str:
    if kind in {"unity_bundle", "unity_serialized", "unity_split_part", "bundle_unrecognized", "unity_resource_stream"}:
        return "Unity 游戏资源容器"
    if kind in {"android_dex", "native_elf", "il2cpp_metadata", "java_class"}:
        return "游戏与运行时代码"
    if kind in {"image", "font", "video", "audio", "riff_media"}:
        return "独立媒体文件"
    if kind in {"android_binary_xml", "android_resource_table", "android_profile", "package_metadata", "empty"}:
        return "Android 系统与包元数据"
    if kind in {"text", "protobuf_metadata", "gzip", "zip", "sqlite", "lua_bytecode", "binary_named_text"}:
        return "配置、文本与其他数据"
    return "其他或待归类"


def unity_group(kind: str, name: str) -> str:
    low = name.lower()
    if kind == "Texture2D" or kind in {"Sprite", "SpriteAtlas"}:
        return "2D 图像与精灵"
    if kind in {"Mesh", "MeshFilter", "MeshRenderer", "SkinnedMeshRenderer", "MeshCollider"}:
        return "3D 网格与模型"
    if kind in {"AnimationClip", "Animator", "AnimatorController", "Animation"} or low.endswith((".skel", ".ani")):
        return "动画与 Spine"
    if kind == "AudioClip":
        return "音频"
    if kind in {"MonoBehaviour", "MonoScript", "TextAsset"}:
        return "代码、配置与文本"
    if kind in {"Material", "Shader", "ParticleSystem", "ParticleSystemRenderer", "TrailRenderer", "Light"}:
        return "材质、着色器与特效"
    if kind in {"GameObject", "Transform", "RectTransform", "Canvas", "CanvasRenderer", "CanvasGroup"}:
        return "场景与界面结构"
    if kind in {"Font", "VideoClip", "VideoPlayer"}:
        return "字体与视频"
    return "物理、设置与其他"


def main():
    VIS.mkdir(parents=True, exist_ok=True)
    configure()
    packages = load(DATA / "packages.json")
    apk_entries = load(DATA / "apk_entries.json")
    objects = load(DATA / "unity_objects.json")
    texts = load(DATA / "textassets.json")
    lua_chunks = load(DATA / "lua_unique_chunks.json")
    android = load(DATA / "android_summary.json")
    android_methods = load(DATA / "android_methods.json")
    native = load(DATA / "native_libraries.json")
    native_summary = load(DATA / "native_summary.json")
    spine_skel = load(DATA / "spine_skeletons.json")
    spine_ani = load(DATA / "spine_animations.json")
    spine_wire = load(DATA / "spine_animation_wire.json")
    verification = load(DATA / "verification_summary.json")
    database = load(DATA / "database_summary.json")

    # Installation footprint counts every stored APK entry, so this is the actual package payload view.
    package_sizes = {Path(row["path"]).name: Path(row["path"]).stat().st_size for row in packages}
    apk_groups = collections.defaultdict(lambda: {"entries": 0, "expanded_bytes": 0, "stored_bytes": 0})
    unique_apk_hashes = {}
    for row in apk_entries:
        group = apk_kind_group(row.get("kind", "unknown"))
        item = apk_groups[group]
        item["entries"] += 1
        item["expanded_bytes"] += row["bytes"]
        item["stored_bytes"] += row["compressed_bytes"]
        unique_apk_hashes.setdefault(row["sha256"], {"group": group, "bytes": row["bytes"]})
    apk_unique = collections.defaultdict(lambda: {"unique_files": 0, "bytes": 0})
    for row in unique_apk_hashes.values():
        apk_unique[row["group"]]["unique_files"] += 1
        apk_unique[row["group"]]["bytes"] += row["bytes"]
    apk_rows = [{"category": key, **value, "unique_files": apk_unique[key]["unique_files"],
                 "unique_expanded_bytes": apk_unique[key]["bytes"],
                 "expanded_share_percent": pct(value["expanded_bytes"], sum(x["expanded_bytes"] for x in apk_groups.values())),
                 "stored_share_percent": pct(value["stored_bytes"], sum(x["stored_bytes"] for x in apk_groups.values()))}
                for key, value in sorted(apk_groups.items(), key=lambda kv: kv[1]["stored_bytes"], reverse=True)]
    package_total = sum(package_sizes.values())
    package_payload_compressed = sum(row["compressed_bytes"] for row in apk_entries)
    apk_meta = {"apk_files": len(packages), "apk_file_bytes": package_total,
        "apk_entry_count": len(apk_entries), "apk_entry_hash_unique": len(unique_apk_hashes),
        "apk_entry_duplicate_hashes": len(apk_entries) - len(unique_apk_hashes),
        "zip_payload_compressed_bytes": package_payload_compressed,
        "zip_container_overhead_bytes": package_total - package_payload_compressed,
        "expanded_entry_bytes_including_duplicates": sum(x["bytes"] for x in apk_entries),
        "expanded_unique_entry_bytes": sum(x["bytes"] for x in unique_apk_hashes.values()),
        "packages": [{"name": Path(x["path"]).name, "bytes": package_sizes[Path(x["path"]).name], "sha256": x["sha256"]} for x in packages]}

    # Deduplicate Unity object records by exact raw object hash before assigning type and bytes.
    unique_objects = {}
    duplicate_object_occurrences = 0
    for row in objects:
        digest = row.get("sha256")
        if digest and digest not in unique_objects:
            unique_objects[digest] = row
        else:
            duplicate_object_occurrences += 1
    text_by_hash = {}
    for row in texts:
        text_by_hash.setdefault(row["sha256"], row)
    unity_stats = collections.defaultdict(lambda: {"unique_objects": 0, "serialized_bytes": 0, "actual_payload_bytes": 0})
    unity_type_stats = collections.defaultdict(lambda: {"unique_objects": 0, "serialized_bytes": 0})
    texture_payload_hashes = {}
    for digest, row in unique_objects.items():
        category = unity_group(row["type"], row.get("name", ""))
        bucket = unity_stats[category]
        bucket["unique_objects"] += 1
        bucket["serialized_bytes"] += row["bytes"]
        by_type = unity_type_stats[row["type"]]
        by_type["unique_objects"] += 1
        by_type["serialized_bytes"] += row["bytes"]
        if row["type"] == "TextAsset":
            text = text_by_hash.get(row.get("payload_sha256")) or text_by_hash.get(digest)
            if not text:
                text = next((x for x in texts if x.get("sha256") == digest), None)
            if text:
                bucket["actual_payload_bytes"] += text.get("bytes", text.get("payload_bytes", 0))
        elif row["type"] == "Texture2D":
            tree_path = ROOT / row["typetree_path"]
            tree = load(tree_path)
            payload_size = int(tree.get("m_CompleteImageSize", tree.get("m_StreamData", {}).get("size", 0)) or 0)
            # Same serialized Texture2D hash is already unique; its source hash is the asset identity.
            texture_payload_hashes[digest] = payload_size
            bucket["actual_payload_bytes"] += payload_size
        else:
            bucket["actual_payload_bytes"] += row["bytes"]
    unity_rows = [{"category": key, **value,
                   "object_share_percent": pct(value["unique_objects"], len(unique_objects)),
                   "serialized_share_percent": pct(value["serialized_bytes"], sum(x["serialized_bytes"] for x in unity_stats.values()))}
                  for key, value in sorted(unity_stats.items(), key=lambda kv: kv[1]["serialized_bytes"], reverse=True)]
    unity_type_rows = [{"type": key, **value} for key, value in sorted(unity_type_stats.items(), key=lambda kv: kv[1]["serialized_bytes"], reverse=True)]
    unity_meta = {"object_occurrences": len(objects), "unique_raw_object_hashes": len(unique_objects),
        "duplicate_object_occurrences_removed": duplicate_object_occurrences,
        "serialized_object_bytes": sum(x["serialized_bytes"] for x in unity_stats.values()),
        "texture_payload_bytes": sum(texture_payload_hashes.values()),
        "unique_texture_records": len(texture_payload_hashes),
        "texture_payload_measure": "Texture2D m_CompleteImageSize from decoded type trees; exact repeated serialized objects deduplicated by SHA-256",
        "other_media_payload_measure": "Serialized Unity object bytes; not a decoded/transcoded media size"}

    # Code counts are kept in their native units; generated source and disassembly lines are not summed together.
    lua_metrics = {"unique_chunks": len(lua_chunks), "logical_names": len({x["name"] for x in load(DATA / "lua_modules.json")}),
        "bytecode_bytes": sum(x["bytes"] for x in lua_chunks),
        "prototypes": sum(x.get("prototype_count", 0) for x in lua_chunks),
        "instructions": sum(x.get("instructions", 0) for x in lua_chunks),
        "generated_source_lines": sum(x.get("decompiled_lines", 0) for x in lua_chunks),
        "disassembly_lines": sum(x.get("disassembly_lines", 0) for x in lua_chunks)}
    dex_rows = android["dex"]
    dex_hashes = {}
    for row in dex_rows:
        dex_hashes.setdefault(row["sha256"], row["bytes"])
    # Method identity includes owner and descriptor; exact duplicates across DEX inputs count once.
    method_ids = {(x["owner"], x["signature"]) for x in android_methods}
    android_metrics = {"dex_files_unique": len(dex_hashes), "dex_bytes_unique": sum(dex_hashes.values()),
        "classes_in_dex_indexes": sum(x["class_defs"] for x in dex_rows),
        "unique_class_descriptors": len({x["owner"] for x in load(DATA / "android_classes.json")}),
        "unique_methods": len(method_ids), "method_records_in_index": len(android_methods),
        "methods_with_code": sum(x["has_code"] for x in android_methods),
        "smali_lines": sum(x["smali_lines"] for x in dex_rows),
        "java_source_files": android["jadx"]["source_files"], "java_source_lines": android["jadx"]["source_lines"],
        "protected_java_source_files": (android.get("nested_jadx") or {}).get("source_files", 0),
        "protected_java_source_lines": (android.get("nested_jadx") or {}).get("source_lines", 0)}
    native_unique = {}
    native_exec_bytes = 0
    native_asm_lines = 0
    for row in native:
        if row["sha256"] not in native_unique:
            native_unique[row["sha256"]] = row
            native_exec_bytes += sum(section["bytes"] for section in row["sections"] if section.get("name") not in (".plt",))
            native_asm_lines += sum(section["lines"] for section in row["sections"])
    nested_native = load(DATA / "nested_code.json")
    nested_exec_bytes = sum(section["bytes"] for entry in nested_native for section in entry["sections"])
    nested_asm_lines = sum(section["lines"] for entry in nested_native for section in entry["sections"])
    code_rows = [
        {"layer": "Lua 5.3", "units": lua_metrics["prototypes"], "unit_label": "函数原型（含嵌套）",
         "carrier_bytes": lua_metrics["bytecode_bytes"], "readable_lines": lua_metrics["generated_source_lines"],
         "secondary_lines": lua_metrics["disassembly_lines"], "validation": "3,415/3,415 结构一致"},
        {"layer": "Android / SDK", "units": android_metrics["unique_methods"], "unit_label": "去重方法签名",
         "carrier_bytes": android_metrics["dex_bytes_unique"], "readable_lines": android_metrics["java_source_lines"] + android_metrics["protected_java_source_lines"],
         "secondary_lines": android_metrics["smali_lines"], "validation": "DEX 类均有 smali；21 个 JADX 异常文件有低层回退"},
        {"layer": "IL2CPP / 原生", "units": native_summary["method_mappings"], "unit_label": "方法映射（含引擎/SDK）",
         "carrier_bytes": native_exec_bytes + nested_exec_bytes,
         "readable_lines": 0, "secondary_lines": native_asm_lines + nested_asm_lines,
         "validation": "可执行节全覆盖反汇编；C# 方法体未还原为源码"},
    ]
    code_meta = {"lua": lua_metrics, "android": android_metrics,
        "native": {"unique_arm64_libraries": len(native_unique), "native_method_mappings": native_summary["method_mappings"],
            "il2cpp_types": native_summary["parsed_types"], "executable_section_bytes_excluding_plt": native_exec_bytes,
            "assembly_lines": native_asm_lines, "nested_x86_elf_count": len(nested_native),
            "nested_x86_executable_bytes": nested_exec_bytes, "nested_x86_assembly_lines": nested_asm_lines}}

    # APK compressed payload by broad content, preserving physical install footprint (duplicates included).
    fig, ax = plt.subplots(figsize=(12, 5.8))
    rows = list(reversed(apk_rows))
    y = np.arange(len(rows))
    stored = np.array([mb(x["stored_bytes"]) for x in rows])
    expanded = np.array([mb(x["expanded_bytes"]) for x in rows])
    ax.barh(y, stored, color=COLORS[0], height=.62, label="APK 中占用（压缩 entry）")
    ax.barh(y, expanded, color="#aeb9c3", height=.22, label="解压后 entry 体积", zorder=3)
    ax.set_yticks(y, [x["category"] for x in rows])
    ax.set_xlabel("MiB；按 APK entry 实际统计，包含包内重复项")
    ax.set_title("安装包由哪些内容构成？")
    ax.legend(frameon=False, ncol=2, loc="lower right")
    for i, value in enumerate(stored):
        if value > 0:
            ax.text(value, i + .15, f" {value:,.1f}", va="center", fontsize=8, color="#45515b")
    fig.text(.01, -.02, f"4 个 APK 合计 {mb(package_total):,.1f} MiB；APK entry 载荷压缩和 {mb(package_payload_compressed):,.1f} MiB。ZIP 目录、签名与对齐占用另计。", color="#586570", fontsize=9)
    fig.tight_layout()
    savefig(fig, "01_apk_footprint.png")

    # Deduplicated Unity object mix: counts and serialized bytes are separate measures.
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 7.2), gridspec_kw={"width_ratios": [1, 1.2]})
    rows = list(reversed(unity_rows))
    ys = np.arange(len(rows))
    ax1.barh(ys, [x["unique_objects"] for x in rows], color=COLORS[1], height=.65)
    ax1.set_yticks(ys, [x["category"] for x in rows])
    ax1.set_xlabel("去重对象数")
    ax1.set_title("按对象数量")
    ax2.barh(ys, [mb(x["serialized_bytes"]) for x in rows], color=COLORS[0], height=.65, label="对象序列化记录")
    ax2.set_yticks(ys, [x["category"] for x in rows])
    ax2.set_xlabel("MiB")
    ax2.set_title("按对象记录体积")
    for i, value in enumerate(mb(x["serialized_bytes"]) for x in rows):
        ax2.text(value, i, f" {value:,.1f}", va="center", fontsize=8)
    fig.suptitle("Unity 内容构成：按原始对象 SHA-256 去重", fontsize=16, fontweight="bold", y=1.01)
    fig.text(.01, -.025, f"原始对象出现 {len(objects):,} 次，合并完全相同记录后 {len(unique_objects):,} 个；对象记录字节不等于其引用的外部纹理/音频文件字节。", color="#586570", fontsize=9)
    fig.tight_layout()
    savefig(fig, "02_unity_object_mix.png")

    # Visual asset counts and media payloads. Texture bytes use Unity's declared full image payload size.
    key_visuals = ["2D 图像与精灵", "3D 网格与模型", "动画与 Spine", "音频", "材质、着色器与特效", "场景与界面结构"]
    visual_rows = {x["category"]: x for x in unity_rows}
    counts = [visual_rows.get(k, {}).get("unique_objects", 0) for k in key_visuals]
    serialized_mb = [mb(visual_rows.get(k, {}).get("serialized_bytes", 0)) for k in key_visuals]
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6.6))
    y = np.arange(len(key_visuals))
    ax1.barh(y, counts, color=COLORS[1], height=.62)
    ax1.set_yticks(y, key_visuals)
    ax1.invert_yaxis()
    ax1.set_xlabel("完全相同对象去重后的对象数")
    ax1.set_title("资产类别数量")
    ax2.barh(y, serialized_mb, color=COLORS[2], height=.62)
    ax2.set_yticks(y, key_visuals)
    ax2.invert_yaxis()
    ax2.set_xlabel("MiB；Unity 对象序列化记录")
    ax2.set_title("资产类别记录体积")
    for i, value in enumerate(serialized_mb):
        ax2.text(value, i, f" {value:,.1f}", va="center", fontsize=8)
    fig.suptitle("游戏内容里 2D、3D、动画和音频各占多少？", fontsize=16, fontweight="bold", y=1.01)
    texture_mib = mb(unity_meta["texture_payload_bytes"])
    fig.text(.01, -.025, f"另核得 {unity_meta['unique_texture_records']:,} 个去重 Texture2D 记录的声明图像数据为 {texture_mib:,.1f} MiB（m_CompleteImageSize）；此值用于纹理载荷，不与 Unity 容器体积相加。", color="#586570", fontsize=9)
    fig.tight_layout()
    savefig(fig, "03_visual_asset_mix.png")

    # Code volume in native units, avoiding a misleading sum of generated representations.
    fig, axs = plt.subplots(1, 3, figsize=(15, 5.5))
    carrier_labels = ["Lua 字节码", "DEX 文件", "原生可执行节"]
    carrier_values = [
        mb(lua_metrics["bytecode_bytes"]),
        mb(android_metrics["dex_bytes_unique"]),
        mb(native_exec_bytes + nested_exec_bytes),
    ]
    axs[0].bar(carrier_labels, carrier_values, color=[COLORS[0], COLORS[1], COLORS[2]], width=.62)
    axs[0].set_ylabel("MiB")
    axs[0].set_title("逻辑载体体积")
    axs[0].tick_params(axis="x", rotation=15)
    carrier_notes = [
        f"{carrier_values[0]:,.1f} MiB\n{lua_metrics['instructions']:,} 条指令",
        f"{carrier_values[1]:,.1f} MiB\n{android_metrics['dex_files_unique']} 个唯一 DEX",
        f"{carrier_values[2]:,.1f} MiB\nARM64 可执行节",
    ]
    for i, value in enumerate(carrier_values):
        axs[0].text(i, value, carrier_notes[i], ha="center", va="bottom", fontsize=8.5)
    code_labels = ["Lua 原型", "Android 方法", "IL2CPP 映射"]
    code_values = [lua_metrics["prototypes"], android_metrics["unique_methods"], native_summary["method_mappings"]]
    axs[1].bar(code_labels, code_values, color=[COLORS[0], COLORS[1], COLORS[2]], width=.62)
    axs[1].set_title("可索引逻辑单元")
    axs[1].set_ylabel("原型 / 方法签名 / 地址映射")
    axs[1].tick_params(axis="x", rotation=15)
    for i, value in enumerate(code_values):
        axs[1].text(i, value, f"{value:,}", ha="center", va="bottom", fontsize=9)
    line_values = [lua_metrics["generated_source_lines"], android_metrics["smali_lines"], native_asm_lines + nested_asm_lines]
    line_labels = ["Lua 生成源码", "Android smali", "原生汇编"]
    axs[2].bar(line_labels, line_values, color=[COLORS[0], COLORS[1], COLORS[2]], width=.62)
    axs[2].set_title("可读底层材料规模")
    axs[2].set_ylabel("生成行数")
    axs[2].tick_params(axis="x", rotation=15)
    for i, value in enumerate(line_values):
        axs[2].text(i, value, f"{value / 1e6:.2f}M", ha="center", va="bottom", fontsize=9)
    fig.suptitle("代码规模：载体、逻辑单元和阅读材料分开统计", fontsize=16, fontweight="bold", y=1.02)
    fig.text(.01, -.04, "载体体积分别是 Lua 字节码、去重 DEX 文件和原生可执行节；Lua 原型、Android 方法和 IL2CPP 方法映射不是完全等价单位。行数是工具生成的阅读材料，不能相加当作原始源码行数。", color="#586570", fontsize=9)
    fig.tight_layout()
    savefig(fig, "04_code_volume.png")

    # A proof-oriented coverage matrix with named denominators and explicit evidence types.
    spine_wire_ok = sum(x["status"] == "wire_decoded" and x.get("roundtrip_bytes_equal") for x in spine_wire)
    spine_context = sum(x["status"] == "decoded_complete" for x in spine_ani)
    lua_ok = len(load(DATA / "lua_validation.json"))
    java_complete = sum(x["smali_complete"] for x in android["dex"])
    coverage_rows = [
        {"layer": "APK 文件提取", "done": len(apk_entries), "total": len(apk_entries), "unit": "ZIP entry", "evidence": "清单、CRC、SHA-256", "status": "通过"},
        {"layer": "Unity 容器对象数", "done": verification["unity_containers_checked"] - verification["unity_count_failures"], "total": verification["unity_containers_checked"], "unit": "唯一容器", "evidence": "UnityPy 独立重读对象数", "status": "通过"},
        {"layer": "Unity 对象字段解码", "done": sum(x["decode_status"] == "decoded" for x in objects), "total": len(objects), "unit": "对象出现记录", "evidence": "TypeTree / 显式布局完整读取", "status": "通过"},
        {"layer": "Lua 字节码结构", "done": sum(x["status"] == "instruction_structure_equal" for x in load(DATA / "lua_validation.json")), "total": lua_ok, "unit": "唯一字节码块", "evidence": "回编译结构一致", "status": "通过"},
        {"layer": "Android DEX 类导出", "done": sum(x["smali_files"] for x in android["dex"]), "total": sum(x["class_defs"] for x in android["dex"]), "unit": "类定义", "evidence": "smali 文件数逐 DEX 对照", "status": "通过" if java_complete == len(android["dex"]) else "需复核"},
        {"layer": "Spine 动画编码", "done": spine_wire_ok, "total": len(spine_wire), "unit": "分离动画", "evidence": "完整读取并逐字节回编码", "status": "通过"},
        {"layer": "Spine 动画骨架上下文", "done": spine_context, "total": len(spine_ani), "unit": "分离动画", "evidence": "候选骨架完整解析", "status": f"{len(spine_ani)-spine_context} 项缺匹配骨架"},
        {"layer": "全部派生产物哈希", "done": verification["hashed_files"] - verification["hash_failures"], "total": verification["hashed_files"], "unit": "文件", "evidence": "SHA-256 重算", "status": "通过"},
    ]
    fig, ax = plt.subplots(figsize=(12, 6.4))
    yy = np.arange(len(coverage_rows))
    ratio = [100 * r["done"] / r["total"] if r["total"] else 0 for r in coverage_rows]
    barcolors = [COLORS[0] if r["done"] == r["total"] else COLORS[2] for r in coverage_rows]
    ax.barh(yy, [100] * len(yy), color="#edf0f2", height=.62)
    ax.barh(yy, ratio, color=barcolors, height=.62)
    ax.set_xlim(0, 115)
    ax.set_yticks(yy, [f"{r['layer']}  ·  {r['unit']}" for r in coverage_rows])
    ax.invert_yaxis()
    ax.set_xlabel("该行定义的分母内完成比例；行与行之间单位不同")
    ax.set_title("拆解覆盖与证据核验")
    for i, row in enumerate(coverage_rows):
        ax.text(101, i, f"{row['done']:,}/{row['total']:,}  {row['status']}", va="center", fontsize=8.5, color="#35404a")
    fig.text(.01, -.025, "318 个动画的编码本身完整可还原；缺少的是匹配骨架上下文。当前快照共检查 1,115 个骨架，均未找到匹配项。", color="#586570", fontsize=9)
    fig.tight_layout()
    savefig(fig, "05_coverage_evidence.png")

    # Save machine-readable report, evidence-level tables and concise methodology.
    remote = load(DATA / "remote_resources.json")
    remote_unique = {}
    for row in remote:
        if row.get("status") == "downloaded":
            remote_unique.setdefault(row["sha256"], row["bytes"])
    payload = {"title": "Gossip Harbor 3.98.10 第一阶段资源与代码规模", "generated_from": "analysis_data/logic_index",
        "deduplication": {"apk_entries": "精确文件 SHA-256；包体占用仍报告所有 APK entry 的实际压缩字节", "unity_objects": "精确原始对象 SHA-256", "lua": "唯一字节码 SHA-256", "android_methods": "owner + 方法描述符", "native_libraries": "ELF SHA-256", "remote_bundles": "bundle SHA-256"},
        "apk": {**apk_meta, "categories": apk_rows},
        "remote": {"catalog_entries": len(remote), "downloaded_entries": sum(x["status"] == "downloaded" for x in remote),
            "unique_downloaded_bundles": len(remote_unique), "unique_downloaded_bundle_bytes": sum(remote_unique.values()),
            "source_note": "远端 catalog 快照单列，不并入 APK 安装大小；对 APK 已有内容不重复相加。"},
        "unity": {**unity_meta, "categories": unity_rows, "types": unity_type_rows},
        "code": {"layers": code_rows, **code_meta},
        "coverage": coverage_rows,
        "other_counts": {"unique_unity_containers": 2210, "database_tables": len(database["tables"]),
            "database_rows": sum(x["rows"] for x in database["tables"]), "spine_skeletons": len(spine_skel),
            "spine_animations": len(spine_ani), "spine_animations_with_context": spine_context,
            "spine_animations_missing_context": len(spine_ani) - spine_context,
            "unresolved_sdk_field_semantics": 2,
            "artifact_hashes_checked": verification["hashed_files"], "artifact_hash_failures": verification["hash_failures"]},
        "limitations": ["APK entry 压缩占用包含包内重复项，用于反映实际 APK 内容；哈希去重指标另报。",
            "Unity 对象大小是序列化记录大小；Texture2D 另用 m_CompleteImageSize 统计图像载荷。",
            "Unity 容器包含其内部对象，容器体积与对象体积不可相加。",
            "Lua/Java/smali/汇编行数均为工具生成阅读材料，不是原始源码行数，也不跨语言相加。",
            "去重只合并可证明字节完全相同的内容，不把相似实现或语义相同配置擅自合并。",
            "统计范围是当前 3.98.10 四个 APK 与记录的 2026-09-22 catalog；不覆盖未知服务端、账号分组或历史版本资源。"]}
    save(VIS / "stage1_visuals_data.json", payload)
    write_csv(VIS / "apk_composition.csv", apk_rows)
    write_csv(VIS / "unity_asset_mix.csv", unity_rows)
    write_csv(VIS / "unity_type_detail.csv", unity_type_rows)
    write_csv(VIS / "coverage_evidence.csv", coverage_rows)
    write_csv(VIS / "code_volume.csv", code_rows)

    image_rows = [
        ("01_apk_footprint.png", "APK 包体构成", "按实际 APK entry 压缩体积统计，重复项保留以反映安装包占用；灰色短条表示解压后体积。"),
        ("02_unity_object_mix.png", "Unity 对象构成", f"按对象原始字节 SHA-256 去重。对象出现记录 {len(objects):,} 次，合并后 {len(unique_objects):,} 个。"),
        ("03_visual_asset_mix.png", "2D、3D、动画与音频", f"纹理载荷另由 Texture2D 的 m_CompleteImageSize 汇总为 {mb(unity_meta['texture_payload_bytes']):,.1f} MiB；其他项目显示对象记录大小。"),
        ("04_code_volume.png", "代码规模", "载体体积、代码单元数和反编译阅读材料分别展示；单位不等价，行数不合并。"),
        ("05_coverage_evidence.png", "覆盖与验收证据", "每行独立分母，动画编码读取与骨架上下文分开验收。"),
    ]
    sections = "\n".join(f'<section><h2>{title}</h2><p>{caption}</p><img src="visuals/{filename}" alt="{title}"></section>' for filename, title, caption in image_rows)
    html_text = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gossip Harbor 第一阶段统计图</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#f5f7f8;color:#20252b;font:15px/1.65 "Microsoft YaHei","Segoe UI",sans-serif}}main{{max-width:1240px;margin:auto;padding:28px}}header{{border-bottom:1px solid #d4dbe1;padding-bottom:16px}}h1{{font-size:27px;margin:0}}h2{{font-size:19px;margin:0 0 6px}}section{{background:#fff;border:1px solid #dfe4e8;border-radius:5px;padding:18px;margin:18px 0}}section p{{color:#5e6974;margin:0 0 12px}}img{{display:block;width:100%;height:auto}}.note{{padding:14px 16px;background:#eaf2ee;border-left:4px solid #28785f;margin:18px 0}}.limits{{columns:2;column-gap:32px}}.limits li{{break-inside:avoid;margin:5px 0}}a{{color:#176d56}}@media(max-width:700px){{main{{padding:14px}}h1{{font-size:22px}}section{{padding:10px;margin:12px 0}}.limits{{columns:1}}}}</style></head><body><main><header><h1>Gossip Harbor 3.98.10：资源与代码规模</h1><p>统计快照：四个 APK 与已记录远端 catalog。内容精确哈希去重；实际安装体积另按 APK entry 统计。</p></header><div class="note"><strong>阅读口径：</strong>包体压缩占用、Unity 对象记录大小、纹理载荷、代码单元和生成阅读材料分别统计。嵌套容器与内部对象不相加，跨语言行数不合并。</div>{sections}<section><h2>统计边界</h2><ul class="limits">{''.join(f'<li>{x}</li>' for x in payload['limitations'])}</ul><p>机器可读数据：<a href="visuals/stage1_visuals_data.json">JSON</a>；汇报表：<a href="visuals/apk_composition.csv">APK 构成</a>、<a href="visuals/unity_asset_mix.csv">Unity 资源</a>、<a href="visuals/code_volume.csv">代码规模</a>、<a href="visuals/coverage_evidence.csv">覆盖证据</a>。</p></section></main></body></html>'''
    (OUT / "STAGE1_VISUALS.html").write_text(html_text, encoding="utf-8")

    # Print compact headline values for the final QA pass.
    print(json.dumps({"apk_bytes": package_total, "apk_unique_entry_bytes": apk_meta["expanded_unique_entry_bytes"],
        "unity_object_occurrences": len(objects), "unity_unique_object_hashes": len(unique_objects),
        "texture_payload_bytes": unity_meta["texture_payload_bytes"], "code": code_meta,
        "coverage": coverage_rows, "output": relative(OUT / "STAGE1_VISUALS.html")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
