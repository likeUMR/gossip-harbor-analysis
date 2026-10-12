"""Download reproducible reading tools; never execute downloaded installers."""
import hashlib
import json
import urllib.request
import zipfile
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tools" / "logic_vendor"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "GH-Resource-Audit/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        chunks = []
        total = 0
        started = time.monotonic()
        while True:
            block = response.read(1024 * 1024)
            if not block:
                break
            chunks.append(block)
            total += len(block)
            if total % (10 * 1024 * 1024) == 0:
                print(f"Download: {total // 1024 // 1024} MiB: {url}", flush=True)
            if time.monotonic() - started > 180:
                raise TimeoutError("Download exceeded 180 seconds")
        return b"".join(chunks), response.url


def main():
    OUT.mkdir(exist_ok=True)
    records = []
    jar = OUT / "unluac.jar"
    if not jar.exists() and not (OUT / "unluac_source/src").exists():
        urls = [
            "https://sourceforge.net/projects/unluac/files/Unstable/unluac.jar/download",
            "https://raw.githubusercontent.com/viruscamp/unluac/master/unluac.jar",
        ]
        for url in urls:
            try:
                data, resolved = fetch(url)
                if not data.startswith(b"PK"):
                    raise ValueError("Not a JAR/ZIP")
                jar.write_bytes(data)
                records.append({"tool": "unluac", "url": url, "resolved": resolved,
                                "sha256": hashlib.sha256(data).hexdigest()})
                break
            except Exception as exc:
                print(f"unluac source failed: {url}: {exc}", flush=True)
    java = list(OUT.glob("jre/**/java.exe"))
    if not java:
        api = "https://api.azul.com/metadata/v1/zulu/packages/?java_version=17&os=windows&arch=x86&hw_bitness=64&archive_type=zip&java_package_type=jre&release_status=ga&availability_types=CA&latest=true"
        data, _ = fetch(api)
        package = next(x for x in json.loads(data) if "win_x64" in x["name"] and "-fx-" not in x["name"])
        data, resolved = fetch(package["download_url"])
        digest = hashlib.sha256(data).hexdigest()
        archive = OUT / package["name"]
        archive.write_bytes(data)
        with zipfile.ZipFile(archive) as z:
            target = (OUT / "jre").resolve()
            for info in z.infolist():
                if not (target / info.filename).resolve().is_relative_to(target):
                    raise ValueError("Unsafe JRE entry")
            z.extractall(target)
        records.append({"tool": "Zulu JRE 17", "version": package["name"],
                        "url": package["download_url"], "resolved": resolved, "sha256": digest})
    java = next(OUT.glob("jre/**/java.exe"))
    if not jar.exists() and (OUT / "unluac_source/src").exists():
        ecj = OUT / "ecj-3.38.0.jar"
        if not ecj.exists():
            url = "https://repo.maven.apache.org/maven2/org/eclipse/jdt/ecj/3.38.0/ecj-3.38.0.jar"
            data, resolved = fetch(url)
            ecj.write_bytes(data)
            records.append({"tool": "Eclipse Java compiler 3.38.0", "url": url,
                            "resolved": resolved, "sha256": hashlib.sha256(data).hexdigest()})
        source = OUT / "unluac_source"
        classes = OUT / "unluac_classes"
        classes.mkdir(exist_ok=True)
        files = sorted((source / "src").rglob("*.java"))
        subprocess.run([str(java), "-jar", str(ecj), "-17", "-encoding", "UTF-8", "-d", str(classes),
                        *[str(p) for p in files]], check=True, stdout=subprocess.DEVNULL)
        with zipfile.ZipFile(jar, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("META-INF/MANIFEST.MF", "Manifest-Version: 1.0\nMain-Class: unluac.Main\n\n")
            for file in classes.rglob("*.class"):
                z.write(file, file.relative_to(classes).as_posix())
        commit = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
        records.append({"tool": "unluac compiled from source", "commit": commit,
                        "sha256": hashlib.sha256(jar.read_bytes()).hexdigest()})
    manifest = OUT / "downloads.json"
    prior = json.loads(manifest.read_text()) if manifest.exists() else []
    manifest.write_text(json.dumps(prior + records, indent=2), encoding="utf-8")
    print(json.dumps({"unluac": jar.exists(), "java": [str(p) for p in OUT.glob('jre/**/java.exe')]}, indent=2))


if __name__ == "__main__":
    main()
