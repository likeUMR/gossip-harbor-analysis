"""Repair evidenced unluac mistakes and require exact original bytecode structure."""
import subprocess

from audit_gh_resources import DATA, ROOT, load, relative, save
from gh_lua import Chunk
from validate_gh_lua import fingerprint


REPAIRS = {
    "TempItem.Model.TempItemModel": [("not self:_CheckLastRoundEndTime() and self:_IsSameChainIdWithNoIntervalAllowed() and self:_CheckLastTempItemChainId(chainId)",
        "self:_CheckLastRoundEndTime() or self:_IsSameChainIdWithNoIntervalAllowed() and self:_CheckLastTempItemChainId(chainId)")],
    "UI.Button.ActivityBundleEntryGroup": [("        bShowExcalmation = not (0 < cnt) or bShowExcalmation or entryLua.HasExclamation and entryLua:HasExclamation()",
        "        if 0 < cnt then\n          bShowExcalmation = bShowExcalmation or entryLua.HasExclamation and entryLua:HasExclamation()\n        end")],
    "UI.Button.FolderButton": [("not MINIGAME_WECHAT and MINIGAME_DOUYIN and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.NotifyTiktok) and not GM.SDKHelper:IsDYNovelRead()",
        "MINIGAME_WECHAT or MINIGAME_DOUYIN and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.NotifyTiktok) and not GM.SDKHelper:IsDYNovelRead()")],
    "UI.Button.HudGeneralButton": [("(not self.m_exclamationGo or not self.m_exclamationGo.activeSelf) and self.m_RedPointWithNumLuaTable and self.m_RedPointWithNumLuaTable.gameObject and self.m_RedPointWithNumLuaTable.gameObject.activeSelf",
        "self.m_exclamationGo and self.m_exclamationGo.activeSelf or self.m_RedPointWithNumLuaTable and self.m_RedPointWithNumLuaTable.gameObject and self.m_RedPointWithNumLuaTable.gameObject.activeSelf")],
    "UI.Button.SettingButton": [("not GM.SDKHelper:HasUnreadCSMsg() and not GM.MoreGameModel:IsStrongTip() and not GM.AccountManager:ShowBindStrongTip() and (CHINA_APP or GLOBAL_APP) and GM.VibrateModel:IsStrongTip()",
        "GM.SDKHelper:HasUnreadCSMsg() or GM.MoreGameModel:IsStrongTip() or GM.AccountManager:ShowBindStrongTip() or (CHINA_APP or GLOBAL_APP) and GM.VibrateModel:IsStrongTip()")],
    "UI.Window.Setting.SettingWindowCN": [("not MINIGAME_WECHAT and MINIGAME_DOUYIN and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.NotifyTiktok)",
        "MINIGAME_WECHAT or MINIGAME_DOUYIN and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.NotifyTiktok)")],
    "UI.SceneView.SceneViewHud": [("0 < (self.m_mapAnchorRootHideCount[EHudAnchorType.TopCenter] or 0)",
        "(self.m_mapAnchorRootHideCount[EHudAnchorType.TopCenter] or 0) > 0")],
    "UI.Window.Shop.ChainEnergyBundleWindow": [("self.m_lockGo:SetActive(playAni or index ~= 1)",
        "self.m_lockGo:SetActive(not not (playAni or index ~= 1))")],
    "OrderBoost.Model.OrderBoostModel": [("            else\n              break\n            end\n          end\n        end\n      ::lbl_359::",
        "            end\n          end\n        else\n          break\n        end\n      ::lbl_359::")],
}


def main():
    rows = []
    modules = load(DATA / "lua_unique_chunks.json")
    updates = {}
    for module in modules:
        if module["name"] not in REPAIRS:
            continue
        target = ROOT / module["source_path"]
        backup = target.with_name("unluac_original.lua")
        if not backup.exists():
            backup.write_bytes(target.read_bytes())
        source = backup.read_text(encoding="utf-8")
        for old, new in REPAIRS[module["name"]]:
            if source.count(old) != 1:
                raise ValueError(f"Unexpected source occurrence: {module['name']}: {old}")
            source = source.replace(old, new)
        candidate = target.with_name("repaired_candidate.lua")
        candidate.write_text(source, encoding="utf-8")
        bytecode = target.with_name("repaired_candidate.luac")
        result = subprocess.run([str(ROOT / "analysis_data/luac-compatible.exe"), "-o", str(bytecode), str(candidate)], capture_output=True)
        equal = result.returncode == 0 and fingerprint(Chunk((ROOT / module["path"]).read_bytes()).root) == fingerprint(Chunk(bytecode.read_bytes()).root)
        row = {"name": module["name"], "original_source": relative(backup), "candidate": relative(candidate),
               "status": "exact_structure_verified" if equal else "candidate_not_exact", "changes": REPAIRS[module["name"]]}
        if equal:
            target.write_text(source, encoding="utf-8")
            updates[module["sha256"]] = {"decompiled_lines": len(source.splitlines()), "source_repair": "exact_structure_verified"}
            cache = target.parent / "index.json"
            cached = load(cache)
            cached.update(updates[module["sha256"]])
            save(cache, cached)
        rows.append(row)
        print(module["name"], row["status"], result.stderr.decode("utf-8", "replace"))
    save(DATA / "lua_source_repairs.json", rows)
    for filename in ("lua_unique_chunks.json", "lua_modules.json"):
        indexed = modules if filename == "lua_unique_chunks.json" else load(DATA / filename)
        for module in indexed:
            module.update(updates.get(module["sha256"], {}))
        save(DATA / filename, indexed)


if __name__ == "__main__":
    main()
