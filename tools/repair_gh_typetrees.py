"""Recover stripped MonoBehaviour schemas using reconstructed managed fields."""
import collections
from pathlib import PurePosixPath

import UnityPy
from UnityPy.helpers.TypeTreeGenerator import TypeTreeGenerator

from audit_gh_resources import DATA, ROOT, load, relative, save


def main():
    objects = load(DATA / "unity_objects.json")
    serials = {}
    for obj in objects:
        serials.setdefault(PurePosixPath(obj["serialized_file"].replace("\\", "/")).name.lower(), obj["container_path"])
    failed = collections.defaultdict(list)
    for obj in objects:
        if obj["decode_status"] == "failed":
            failed[obj["container_path"]].append(obj)
    generator = TypeTreeGenerator("2022.3.62f2")
    generator.load_local_dll_folder(str(ROOT / "tools/Il2CppDumper/Il2CppDumper/bin/Release/net8.0/DummyDll"))
    results = []
    changes = {}
    for index, (container, targets) in enumerate(failed.items()):
        env = UnityPy.load(str(ROOT / container))
        env.typetree_generator = generator
        pending = [obj.assets_file for obj in env.objects]
        visited = set()
        for asset in pending:
            if id(asset) in visited:
                continue
            visited.add(id(asset))
            for external in asset.externals:
                name = PurePosixPath(external.path.replace("\\", "/")).name.lower()
                if name in serials:
                    path = ROOT / serials[name]
                    if str(path) not in env.files:
                        try:
                            env.load_file(str(path))
                        except Exception:
                            pass
        wanted = {(obj["serialized_file"], obj["path_id"]): obj for obj in targets}
        for obj in list(env.objects):
            key = (str(obj.assets_file.name), obj.path_id)
            if key not in wanted:
                continue
            row = wanted[key]
            try:
                node = obj.generate_monobehaviour_node()
                tree = obj.read_typetree(node)
                stem = (ROOT / row["raw_path"]).stem
                target = (ROOT / row["raw_path"]).parent.parent / "typetrees" / (stem + ".json")
                save(target, tree)
                updates = {"decode_status": "decoded", "typetree_path": relative(target),
                           "schema_source": "Il2CppDumper DummyDll fields + TypeTreeGeneratorAPI 0.0.10"}
                changes[(row["container_sha256"], row["serialized_file"], row["path_id"])] = updates
                results.append({"container": container, "path_id": obj.path_id, "status": "recovered"})
            except Exception as exc:
                results.append({"container": container, "path_id": obj.path_id, "status": "failed", "error": repr(exc)})
        if (index + 1) % 10 == 0:
            print(f"TypeTree repair: containers {index + 1}/{len(failed)}, recovered={len(changes)}", flush=True)
    for obj in objects:
        key = (obj["container_sha256"], obj["serialized_file"], obj["path_id"])
        if key in changes:
            obj.update(changes[key])
            obj.pop("error", None)
    save(DATA / "unity_objects.json", objects)
    for container in load(DATA / "unity_containers.json"):
        path = ROOT / container["inventory"]
        record = load(path)
        modified = False
        for obj in record["objects"]:
            key = (container["sha256"], obj["serialized_file"], obj["path_id"])
            if key in changes:
                obj.update(changes[key])
                obj.pop("error", None)
                modified = True
        if modified:
            save(path, record)
    save(DATA / "typetree_repairs.json", results)
    print(collections.Counter(x["status"] for x in results))


if __name__ == "__main__":
    main()
