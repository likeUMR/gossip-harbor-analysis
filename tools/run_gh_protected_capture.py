"""Inspect protected SDK initialization with logged Android compatibility responses."""
import os
import sys
import subprocess
import urllib.request
import zipfile

from audit_gh_resources import DATA, ROOT, load, save, sha


def main():
    vendor = ROOT / "tools/logic_vendor"
    for name, coordinate in (
        ("android-4.1.1.4.jar", "com/google/android/android/4.1.1.4/android-4.1.1.4.jar"),
        ("xmlpull-1.1.3.1.jar", "xmlpull/xmlpull/1.1.3.1/xmlpull-1.1.3.1.jar"),
    ):
        target = vendor / name
        if not target.exists():
            target.write_bytes(urllib.request.urlopen("https://repo.maven.apache.org/maven2/" + coordinate, timeout=30).read())
    java = next((vendor / "jre").rglob("java.exe"))
    dependencies = list((vendor / "dex2jar").glob("*.jar"))
    cp = os.pathsep.join(str(x) for x in dependencies)
    classes = vendor / "capture_classes"
    result = subprocess.run([str(java), "-jar", str(vendor / "ecj-3.38.0.jar"), "-17", "-cp", cp,
                             "-d", str(classes), *[str(x) for x in (ROOT / "tools").glob("Capture*.java")],
                             str(ROOT / "tools/InstrumentReflection.java"), *[str(x) for x in (ROOT / "tools/android_stubs").rglob("*.java")]], capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", "replace"))
    source = DATA / "android/classes-dex2jar.jar"
    instrumented = DATA / "android/classes-instrumented.jar"
    subprocess.run([str(java), "-cp", str(classes) + os.pathsep + cp, "InstrumentReflection",
                    str(source), str(instrumented)], check=True)
    hidden = DATA / "android/protected-loaders.jar"
    with zipfile.ZipFile(hidden, "w") as merged:
        for dex in (DATA / "android/protected_decoded").glob("*/classes.dex"):
            part = dex.with_suffix(".jar")
            subprocess.run([str(java), "-cp", cp, "com.googlecode.dex2jar.tools.Dex2jarCmd", "-f", "-o", str(part), str(dex)], check=True)
            with zipfile.ZipFile(part) as archive:
                for name in archive.namelist():
                    if name.endswith(".class"):
                        merged.writestr(name, archive.read(name))
    subprocess.run([str(java), "-cp", str(classes) + os.pathsep + cp, "InstrumentReflection",
                    str(hidden), str(DATA / "android/protected-loaders-instrumented.jar")], check=True)
    runtime_cp = os.pathsep.join(str(x) for x in (classes, vendor / "android-4.1.1.4.jar", vendor / "xmlpull-1.1.3.1.jar"))
    temp = DATA / "android/capture_temp"
    temp.mkdir(exist_ok=True)
    apk = next(x for x in load(DATA / "packages.json") if x["path"].endswith("/base.apk"))
    result = subprocess.run([str(java), "-noverify", "-Djava.io.tmpdir=" + str(temp),
                             "-Dgh.capture.dir=" + str(DATA / "android/protected_dex"), "-cp", runtime_cp, "CaptureProtected", str(instrumented),
                             str(ROOT / apk["path"]), sys.argv[1] if len(sys.argv) > 1 else "com.appsflyer.internal.AFa1hSDK"], capture_output=True, timeout=45)
    log = result.stdout.decode("utf-8", "replace") + result.stderr.decode("utf-8", "replace")
    (DATA / "android/protected_capture.log").write_text(log, encoding="utf-8")
    target_name = sys.argv[1] if len(sys.argv) > 1 else "com.appsflyer.internal.AFa1hSDK"
    (DATA / f"android/protected_capture_{target_name}.log").write_text(log, encoding="utf-8")
    save(DATA / "android/protected_capture_tools.json", {"source_sha256": sha(source.read_bytes()),
         "instrumented_sha256": sha(instrumented.read_bytes()),
         "compatibility_responses": "Logged default primitive values; not evidence of production behavior",
         "dependencies": [{"path": str(x.relative_to(ROOT)), "sha256": sha(x.read_bytes())} for x in (
             vendor / "android-4.1.1.4.jar", vendor / "xmlpull-1.1.3.1.jar")]})
    print(log[-5000:])


if __name__ == "__main__":
    main()
