"""Resolve a pinned second DEX frontend to inspect JADX failure methods."""
import collections
import hashlib

from audit_gh_resources import ROOT, save
from bootstrap_jadx import BASE, get, model


def main():
    destination = ROOT / "tools/logic_vendor/dex2jar"
    destination.mkdir(exist_ok=True)
    queue = collections.deque([("de.femtopedia.dex2jar", "dex-tools", "2.4.38")])
    chosen, manifest = {}, []
    while queue:
        group, artifact, version = queue.popleft()
        if (group, artifact) in chosen:
            continue
        chosen[group, artifact] = version
        _, _, dependencies = model(group, artifact, version)
        queue.extend(dependencies)
        url = BASE + group.replace(".", "/") + f"/{artifact}/{version}/{artifact}-{version}.jar"
        target = destination / f"{artifact}-{version}.jar"
        if not target.exists():
            raw = get(url)
            expected = get(url + ".sha1").decode().strip().split()[0]
            if hashlib.sha1(raw).hexdigest() != expected:
                raise ValueError("Maven checksum mismatch")
            target.write_bytes(raw)
        manifest.append({"coordinate": f"{group}:{artifact}:{version}", "url": url,
                         "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
        print(artifact, version, flush=True)
    save(destination / "manifest.json", manifest)


if __name__ == "__main__":
    main()
