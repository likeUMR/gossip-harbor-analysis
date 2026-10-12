"""Decode stripped settings with explicit, byte-complete serialization layouts."""
import struct
import urllib.request

import UnityPy

from audit_gh_resources import DATA, ROOT, load, relative, save, sha, write_bytes


class Reader:
    def __init__(self, raw, offset):
        self.raw, self.offset = raw, offset

    def integer(self):
        value = struct.unpack_from("<i", self.raw, self.offset)[0]
        self.offset += 4
        return value

    def boolean(self):
        value = self.raw[self.offset]
        if value not in (0, 1):
            raise ValueError(f"Invalid boolean at {self.offset}")
        self.offset += 1
        self.align()
        return bool(value)

    def align(self):
        end = (self.offset + 3) & ~3
        if any(self.raw[self.offset:end]):
            raise ValueError("Nonzero alignment bytes")
        self.offset = end

    def string(self):
        size = self.integer()
        if size < 0 or self.offset + size > len(self.raw):
            raise ValueError("Invalid serialized string size")
        value = self.raw[self.offset:self.offset + size].decode("utf-8")
        self.offset += size
        self.align()
        return value

    def strings(self):
        count = self.integer()
        if count < 0 or count > len(self.raw) // 4:
            raise ValueError("Invalid array count")
        return [self.string() for _ in range(count)]

    def floating(self):
        value = struct.unpack_from("<f", self.raw, self.offset)[0]
        self.offset += 4
        return value

    def pointer(self):
        file_id, path_id = struct.unpack_from("<iq", self.raw, self.offset)
        self.offset += 12
        return {"m_FileID": file_id, "m_PathID": path_id}

    def packed_booleans(self):
        values = self.raw[self.offset:self.offset + 2]
        if any(x not in (0, 1) for x in values):
            raise ValueError("Invalid packed booleans")
        self.offset += 2
        self.align()
        return [bool(x) for x in values]

    def style(self):
        tree = {"m_Name": self.string()}
        for name in ("m_Normal", "m_Hover", "m_Active", "m_Focused", "m_OnNormal", "m_OnHover", "m_OnActive", "m_OnFocused"):
            tree[name] = {"m_Background": self.pointer(), "m_TextColor": [self.floating() for _ in range(4)]}
        for name in ("m_Border", "m_Margin", "m_Padding", "m_Overflow"):
            tree[name] = dict(zip(("left", "right", "top", "bottom"), [self.integer() for _ in range(4)]))
        tree["m_Font"] = self.pointer()
        for name in ("m_FontSize", "m_FontStyle", "m_Alignment"):
            tree[name] = self.integer()
        tree["m_WordWrap"], tree["m_RichText"] = self.packed_booleans()
        tree["m_TextClipping"], tree["m_ImagePosition"] = self.integer(), self.integer()
        tree["m_ContentOffset"] = [self.floating(), self.floating()]
        tree["m_FixedWidth"], tree["m_FixedHeight"] = self.floating(), self.floating()
        tree["m_StretchWidth"], tree["m_StretchHeight"] = self.packed_booleans()
        if not (0 <= tree["m_FontStyle"] <= 3 and 0 <= tree["m_Alignment"] <= 8 and
                0 <= tree["m_TextClipping"] <= 1 and 0 <= tree["m_ImagePosition"] <= 3):
            raise ValueError("GUIStyle enum outside documented range")
        return tree

    def skin(self):
        tree = {"m_Font": self.pointer()}
        for name in ("m_box", "m_button", "m_toggle", "m_label", "m_textField", "m_textArea", "m_window",
                     "m_horizontalSlider", "m_horizontalSliderThumb", "m_verticalSlider", "m_verticalSliderThumb",
                     "m_horizontalScrollbar", "m_horizontalScrollbarThumb", "m_horizontalScrollbarLeftButton",
                     "m_horizontalScrollbarRightButton", "m_verticalScrollbar", "m_verticalScrollbarThumb",
                     "m_verticalScrollbarUpButton", "m_verticalScrollbarDownButton", "m_ScrollView"):
            tree[name] = self.style()
        count = self.integer()
        if count < 0 or count > len(self.raw) // 352:
            raise ValueError("Invalid custom GUIStyle count")
        tree["m_CustomStyles"] = [self.style() for _ in range(count)]
        tree["m_Settings"] = {"m_DoubleClickSelectsWord": self.boolean(), "m_TripleClickSelectsLine": self.boolean(),
                              "m_CursorColor": [self.floating() for _ in range(4)], "m_CursorFlashSpeed": self.floating(),
                              "m_SelectionColor": [self.floating() for _ in range(4)]}
        return tree


def main():
    url = "https://raw.githubusercontent.com/AppLovin/AppLovin-MAX-Unity-Plugin/master/DemoApp/Assets/MaxSdk/Scripts/IntegrationManager/Editor/AppLovinSettings.cs"
    source = DATA / "schema_sources/AppLovinSettings.cs"
    if not source.exists():
        write_bytes(source, urllib.request.urlopen(url, timeout=30).read())
    save(DATA / "schema_sources/AppLovinSettings.provenance.json", {"url": url, "sha256": sha(source.read_bytes()),
         "scope": "Reference field order; sample layout independently required to consume all bytes"})
    objects = load(DATA / "unity_objects.json")
    updates = {}
    attempts = load(DATA / "settings_recoveries.json") if (DATA / "settings_recoveries.json").exists() else []
    for row in objects:
        if row["decode_status"] != "failed":
            continue
        if row["serialized_file"] not in ("44d76a5aa82ee42369424de7de4942b7", "e9b1a80678f5d432cb7137ad1f4cb4b3", "level0", "unity default resources", "sharedassets0.assets"):
            continue
        try:
            env = UnityPy.load(str(ROOT / row["container_path"]))
            obj = next(x for x in env.objects if x.path_id == row["path_id"])
            tree = obj.read_typetree(check_read=False)
            raw = (ROOT / row["raw_path"]).read_bytes()
            reader = Reader(raw, (28 + 4 + len(tree["m_Name"].encode("utf-8")) + 3) & ~3)
            if tree["m_Name"] == "AppLovinSettings":
                fields = [("qualityServiceEnabled", reader.boolean)] + [(x, reader.string) for x in (
                    "sdkKey", "customGradleVersionUrl", "customGradleToolsVersion", "adMobAndroidAppId", "adMobIosAppId")]
                evidence = relative(source)
            elif tree["m_Name"] == "FacebookSettings":
                fields = [("selectedAppIndex", reader.integer)] + [(x, reader.strings) for x in (
                    "clientTokens", "appIds", "appLabels")] + [(x, reader.boolean) for x in (
                    "cookie", "logging", "status", "xfbml", "frictionlessRequests")] + [(x, reader.string) for x in (
                    "androidKeystorePath", "iosURLSuffix")]
                evidence = "dump.cs Facebook.Unity.Settings.FacebookSettings serialized field declaration order"
            elif not tree["m_Name"]:
                fields = [(x, reader.strings) for x in ("m_cdnDomainsOffline", "m_cdnDomainsOnline")] + [
                    (x, reader.string) for x in ("m_testFilePathOffline", "m_testFilePathOnline")] + [("m_testTimeout", reader.integer)]
                evidence = "dump.cs NetworkManager serialized field declaration order"
            else:
                tree.update(reader.skin())
                fields = []
                evidence = "Unity 2022.3 GUISkin field order + native GUIStyle layout; enum, alignment and complete-length validation"
            for name, read in fields:
                tree[name] = read()
            if tree["m_Name"] == "FacebookSettings":
                count = reader.integer()
                tree["appLinkSchemes"] = [reader.strings() for _ in range(count)]
                tree["uploadAccessToken"] = reader.string()
                tree["autoLogAppEventsEnabled"] = reader.boolean()
                tree["advertiserIDCollectionEnabled"] = reader.boolean()
            if reader.offset != len(raw):
                raise ValueError(f"Consumed {reader.offset}/{len(raw)}")
            target = (ROOT / row["raw_path"]).parent.parent / "typetrees" / ((ROOT / row["raw_path"]).stem + ".json")
            save(target, tree)
            change = {"decode_status": "decoded", "typetree_path": relative(target), "schema_source": evidence,
                      "consumed_bytes": reader.offset, "recovery_method": "explicit_serialization_layout"}
            updates[(row["container_sha256"], row["serialized_file"], row["path_id"])] = change
            attempts.append({"path": row["raw_path"], "status": "recovered", "evidence": evidence})
        except Exception as error:
            attempts.append({"path": row["raw_path"], "status": "failed", "error": str(error)})
    for row in objects:
        key = (row["container_sha256"], row["serialized_file"], row["path_id"])
        if key in updates:
            row.update(updates[key])
            row.pop("error", None)
    save(DATA / "unity_objects.json", objects)
    for container in load(DATA / "unity_containers.json"):
        record = load(ROOT / container["inventory"])
        modified = False
        for row in record["objects"]:
            key = (container["sha256"], row["serialized_file"], row["path_id"])
            if key in updates:
                row.update(updates[key])
                row.pop("error", None)
                modified = True
        if modified:
            save(ROOT / container["inventory"], record)
    save(DATA / "settings_recoveries.json", attempts)
    print(attempts)


if __name__ == "__main__":
    main()
