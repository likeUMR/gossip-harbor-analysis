"""Resolve pinned JADX Maven artifacts without installing Maven or Gradle."""
import collections
import hashlib
import json
import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tools/logic_vendor/jadx_maven"
BASE = "https://repo.maven.apache.org/maven2/"
NS = {"m": "http://maven.apache.org/POM/4.0.0"}
CACHE = {}
RESOLVED = {}


def get(url):
    urls = [url]
    if url.startswith(BASE):
        urls.append("https://dl.google.com/dl/android/maven2/" + url.removeprefix(BASE))
    last = None
    for candidate in urls:
        try:
            with urllib.request.urlopen(candidate, timeout=35) as response:
                RESOLVED[url] = response.url
                return response.read()
        except urllib.error.HTTPError as exc:
            last = exc
    raise last


def resolve(value, props):
    for _ in range(12):
        revised = re.sub(r"\$\{([^}]+)\}", lambda m: props.get(m[1], m[0]), value)
        if revised == value:
            return value
        value = revised
    return value


def model(group, artifact, version):
    key = (group, artifact, version)
    if key in CACHE:
        return CACHE[key]
    prefix = BASE + group.replace(".", "/") + f"/{artifact}/{version}/{artifact}-{version}"
    try:
        raw = get(prefix + ".pom")
    except Exception as exc:
        raise RuntimeError(f"POM unavailable: {prefix}.pom") from exc
    node = ET.fromstring(raw)
    text = lambda n, tag, default="": n.findtext("m:" + tag, default, NS)
    props, managed = {}, {}
    parent = node.find("m:parent", NS)
    if parent is not None:
        props, managed, _ = model(text(parent, "groupId"), text(parent, "artifactId"), text(parent, "version"))
        props, managed = dict(props), dict(managed)
    props.update({"project.version": version, "project.groupId": group, "project.artifactId": artifact,
                  "pom.version": version})
    properties = node.find("m:properties", NS)
    if properties is not None:
        props.update({x.tag.split("}")[-1]: x.text or "" for x in properties})
    props = {k: resolve(v, props) for k, v in props.items()}
    for dep in node.findall("m:dependencyManagement/m:dependencies/m:dependency", NS):
        g, a, v = [resolve(text(dep, k), props) for k in ("groupId", "artifactId", "version")]
        if text(dep, "scope") == "import" and v:
            _, imported, _ = model(g, a, v)
            managed.update(imported)
        else:
            managed[(g, a)] = v
    deps = []
    for dep in node.findall("m:dependencies/m:dependency", NS):
        if text(dep, "scope") in ("test", "provided", "system") or text(dep, "optional") == "true":
            continue
        if text(dep, "type", "jar") != "jar":
            continue
        g, a = [resolve(text(dep, k), props) for k in ("groupId", "artifactId")]
        v = resolve(text(dep, "version", managed.get((g, a), "")), props)
        if not v or "${" in v:
            raise ValueError(f"Unresolved Maven dependency: {key}: {g}:{a}:{v}")
        deps.append((g, a, v))
    CACHE[key] = props, managed, deps
    return CACHE[key]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    seeds = [("io.github.skylot", a, "1.5.3") for a in
             ("jadx-cli", "jadx-dex-input", "jadx-java-input", "jadx-plugins-tools", "jadx-app-commons")]
    seeds += [("ch.qos.logback", "logback-classic", "1.5.18")]
    queue = collections.deque(seeds)
    chosen, records = {}, []
    while queue:
        g, a, v = queue.popleft()
        if (g, a) in chosen:
            continue
        chosen[g, a] = v
        _, _, dependencies = model(g, a, v)
        # Optional frontends for other formats and scripting are unnecessary for APK/DEX.
        dependencies = [d for d in dependencies if not (d[0] == "io.github.skylot" and d[1] in {
            "jadx-script-plugin", "jadx-java-convert", "jadx-smali-input", "jadx-rename-mappings",
            "jadx-kotlin-metadata", "jadx-kotlin-source-debug-extension", "jadx-xapk-input", "jadx-aab-input", "jadx-apkm-input"})]
        queue.extend(dependencies)
        url = BASE + g.replace(".", "/") + f"/{a}/{v}/{a}-{v}.jar"
        path = OUT / f"{a}-{v}.jar"
        if not path.exists():
            data = get(url)
            expected = get(url + ".sha1").decode().strip().split()[0]
            if hashlib.sha1(data).hexdigest() != expected:
                raise ValueError(f"Maven checksum mismatch: {url}")
            path.write_bytes(data)
        records.append({"coordinate": f"{g}:{a}:{v}", "url": url,
                        "resolved_url": RESOLVED.get(url, "cached"),
                        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size})
        print(f"JADX dependency: {g}:{a}:{v}", flush=True)
    (OUT / "manifest.json").write_text(json.dumps(records, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
