# 阶段三逐函数核销审计

这份清单把已恢复核心模块的每个 Lua 函数列出，并检查领导汇报文档是否至少出现了精确函数名。出现函数名不等于逻辑已经解释；`review_required` 在人工逐函数审阅完成前保持为 true。

函数总数：512

## 分类统计

| 分类 | 函数数 | 文档精确提及 | 未提及 |
|---|---:|---:|---:|
| generator-entry-and-gates | 7 | 4 | 3 |
| generator-lifecycle-and-position | 49 | 6 | 43 |
| lucky | 20 | 0 | 20 |
| merge | 24 | 4 | 20 |
| orders | 123 | 7 | 116 |
| shared-board-or-support | 289 | 14 | 275 |

## 未精确提及函数

| 模块 | 函数 | 源码位置 | 类别 |
|---|---|---|---|
| `ItemSpread` | `ItemSpread.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:25` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanAccelerate` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:100` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:ShowCountdownAnimation` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:104` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:ShowCountDown` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:109` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:OnSpeedUp` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:172` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:_SpeedUp` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:176` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:OnTimeSkip` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:196` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:TryUnlockCdByZroCd` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:216` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:TryUseCDBuff` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:222` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:OnTimeSkipInZeroRestNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:232` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:EmptySpreadCount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:248` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:IsAutoSpread` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:259` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetOpenDuration` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:263` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CostEnergy` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:267` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetCodeWeightPairs` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:275` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetItemRestNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:279` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetStorageRestNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:283` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetSpreadCount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:287` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetSpreadMaxNum` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:291` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetState` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:295` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetStartTimer` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:299` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetWeightType` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:303` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetTransformNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:307` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetAutoSpreadDecrementalRemainTypes` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:311` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:CanSupportCDBuff` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:324` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanSupportSmart` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:331` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanSupportGeneratorBoost` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:335` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanSupportGeneratorBoostCDBuff` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:339` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanSupportBoostDisco` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:344` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CanTestSupportCDFree` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:350` | lucky |
| `ItemSpread` | `ItemSpread:IsDisposable` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:354` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:358` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetNextTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:366` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:_GetTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:374` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetTimerDuration` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:396` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:GetSpeedUpCost` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:412` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:IsChestUsedOnce` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:436` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:CheckLuckyProduce` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:440` | lucky |
| `ItemSpread` | `ItemSpread:TryGenerateLuckyItem` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:454` | lucky |
| `ItemSpread` | `ItemSpread:SafeSpreadItem` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:465` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:SpreadCheckEnergyRatioAndCode` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:486` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:CosetRestNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:558` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:TryGenerateDiscoItem` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:582` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:DealActivityLimit` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:590` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GenerateItemCode` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:599` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetOrderItemCode` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:704` | orders |
| `ItemSpread` | `ItemSpread:_FixedGenerateItemCode` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:747` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:_TryGenerateItemCodeByOrderItem` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:755` | orders |
| `ItemSpread` | `ItemSpread:_TryGenerateItemCodeAll` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:775` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:_TryAutoSpread` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:798` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:CheckEnergy` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:863` | generator-entry-and-gates |
| `ItemSpread` | `ItemSpread:SpreadCostEnergy` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:884` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:TryRemoveSelf` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:930` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:_GetAutoSpreadPosition` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:945` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:_NotifySpreadFailed` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:949` | generator-lifecycle-and-position |
| `ItemSpread` | `ItemSpread:_Log` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:975` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:_FlushLog` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:996` | shared-board-or-support |
| `ItemSpread` | `ItemSpread:GetTestLastSpreadInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:1004` | generator-lifecycle-and-position |
| `MainBoardModel` | `MainBoardModel:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:21` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:InitSpreadRefreshFunc` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:53` | generator-lifecycle-and-position |
| `MainBoardModel` | `MainBoardModel:OnSyncDataFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:119` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:LateInit` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:132` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:Update` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:142` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:LoadFileConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:153` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:UpdatePerSecond` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:166` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetGameMode` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:175` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_SetItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:179` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetCodeCountMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:187` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:HasEnoughItemsToMergeAcquire` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:205` | merge |
| `MainBoardModel` | `MainBoardModel:GenerateItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:210` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:SkipItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:272` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_ShowAffectFailTip` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:413` | merge |
| `MainBoardModel` | `MainBoardModel:_MergeItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:440` | merge |
| `MainBoardModel` | `MainBoardModel:_GetDecreaseBubbleChanceRatio` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:588` | merge |
| `MainBoardModel` | `MainBoardModel:_GetDecreaseBubbleChanceRatio2` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:628` | merge |
| `MainBoardModel` | `MainBoardModel:_HasBubbleItemWithInnerCode` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:667` | merge |
| `MainBoardModel` | `MainBoardModel:_CanBubbleBuyBonus` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:678` | merge |
| `MainBoardModel` | `MainBoardModel:_CanBubbleOrderBonus` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:682` | orders |
| `MainBoardModel` | `MainBoardModel:SellItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:712` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:UndoSellItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:729` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:BreakItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:757` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_LogMove` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:765` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_LogMerge` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:780` | merge |
| `MainBoardModel` | `MainBoardModel:_LogCacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:806` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_TryLogBoardFull` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:812` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:StoreItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:821` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:RetrieveStoredItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:847` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetStoredItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:867` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetStoredItemCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:871` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:IsInventoryFull` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:875` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:BuyStoreSlot` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:879` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetStoreSlotCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:891` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:CanItemStore` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:896` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetFirstUnlockGeneratorItemTipType` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:917` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:IsFirstUnlockGeneratorItemTipType` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:927` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:IsGeneratorFactoryOpen` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:938` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:IsGeneratorFactoryItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:942` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:StoreFactoryItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:946` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetGenFactoryDefaultIndex` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:950` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetGenDataByType` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:954` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetItemGeneratorFactoryModel` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:958` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetOrderModel` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:962` | orders |
| `MainBoardModel` | `MainBoardModel:_RefreshOrderAndCodeData` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:966` | orders |
| `MainBoardModel` | `MainBoardModel:UpdateOrderState` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:975` | orders |
| `MainBoardModel` | `MainBoardModel:CustomerUpgradeActive` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:980` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeCountData` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:992` | orders |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeLackNumMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1016` | orders |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeLackNumMapByLevelSize` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1043` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderBoostOrderCodeLackMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1080` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1202` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderModelType` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1217` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeStateMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1225` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeLackCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1229` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeLackCountMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1233` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeRequireCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1237` | orders |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeRequireCountMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1241` | orders |
| `MainBoardModel` | `MainBoardModel:GetSpecialOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1245` | orders |
| `MainBoardModel` | `MainBoardModel:GetCurrentSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1253` | orders |
| `MainBoardModel` | `MainBoardModel:_FinishSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1258` | orders |
| `MainBoardModel` | `MainBoardModel:_FinishBranchOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1287` | orders |
| `MainBoardModel` | `MainBoardModel.IsInGeneratorChain` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1335` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:CanCreateSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1349` | orders |
| `MainBoardModel` | `MainBoardModel:CreateSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1353` | orders |
| `MainBoardModel` | `MainBoardModel:IsSpecialOrderFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1369` | orders |
| `MainBoardModel` | `MainBoardModel:GetSpecialOrderConfigWithOffset` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1373` | orders |
| `MainBoardModel` | `MainBoardModel:IsBranchOrderFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1377` | orders |
| `MainBoardModel` | `MainBoardModel:GetBranchOrderRequirement` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1381` | orders |
| `MainBoardModel` | `MainBoardModel:GetBranchTypeByRequirementInChain` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1385` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetBranchOrderFinalRewardSlotName` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1394` | orders |
| `MainBoardModel` | `MainBoardModel:TryAcquireCookingFrenzyReward` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1398` | orders |
| `MainBoardModel` | `MainBoardModel:CanItemAffect` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1431` | merge |
| `MainBoardModel` | `MainBoardModel:CanItemSell` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1435` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:UpdateOpeningItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1457` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:HasOpeningItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1471` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_BatchRemoveItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1475` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:RemoveItemsInChainList` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1511` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:TransformItems2Score` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1529` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:TransformItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1597` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:TransformActivityBubble` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1683` | merge |
| `MainBoardModel` | `MainBoardModel:GetItemsOnBoard` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1699` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_CheckCobwebItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1735` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:InitRefreshrestNumberZeroCD` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1777` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:CacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1802` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:CacheItemsFromBoard` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1807` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_PostProcessOnPopCachedItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1812` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_CheckCacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1822` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_UpdateCacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1838` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_XORCaheItemCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1843` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:_BIPaperboxExtraItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1847` | shared-board-or-support |
| `MainBoardModel` | `MainBoardModel:GetPaperBoxRewardConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1861` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:_LogCacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:4` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:7` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItemsFromBoard` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:15` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItemFromSpread` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:39` | generator-lifecycle-and-position |
| `BaseActionBoardModel` | `BaseActionBoardModel:PopCachedItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:48` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:_TryGetNewPosition` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:87` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:_PostProcessOnPopCachedItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:93` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:RemoveCachedItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:96` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:100` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItemCount` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:104` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetAllCacheItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:108` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetItemCacheModel` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:112` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItems` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:116` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:SaveItemProperty` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:120` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:_RemoveItemProperty` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:124` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCodeCountMap` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:136` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:CollectBoardPropertyRewardsWithoutConvert` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:153` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:_CalculateItemCollectRewards` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:161` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPromptConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:264` | shared-board-or-support |
| `BaseActionBoardModel` | `BaseActionBoardModel:InitPaperBoxRewardConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:268` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:298` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardVerticalTiles` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:301` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardPosition` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:305` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxExtraReward` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:309` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:IsPaperBoxExtraRewardFirstAppear` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:314` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:SetPaperBoxExtraRewardAppeared` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:319` | orders |
| `BaseActionBoardModel` | `BaseActionBoardModel:_PostProcessCollapseItem` | `analysis_output/logic_recovery/stage3/Board_Model_Board_BaseActionBoardModel.lua:324` | shared-board-or-support |
| `BaseBoardModel` | `DEFINE_ITEM_EVENT` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:1` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetModelInstance` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:21` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_SetInstance` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:25` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:Init` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:29` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:UpdatePerSecond` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:36` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CreateMatrix` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:42` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CreatePositionFromLocalPosition` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:48` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:54` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_ValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:58` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetInverseYValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:77` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_InverseYValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:81` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetDiagonalValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:100` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_DiagonalValidPositionIterator` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:104` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:PositionIsValid` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:123` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:ToLocalPosition` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:127` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:ToLocalPositionSetZ` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:133` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:IsPositionInteractable` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:139` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GenerateItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:143` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:ReplaceItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:155` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:RemoveItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:160` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:ShockNeighborItems` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:183` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CollapseItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:193` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_PostProcessCollapseItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:221` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:SkipItems` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:224` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:DragItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:228` | merge |
| `BaseBoardModel` | `BaseBoardModel:_MergeItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:232` | merge |
| `BaseBoardModel` | `BaseBoardModel:MergeAll` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:262` | merge |
| `BaseBoardModel` | `BaseBoardModel:GetDistanceInBoard` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:307` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CanItemMove` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:311` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CanItemFall` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:325` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:CanItemMerge` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:329` | merge |
| `BaseBoardModel` | `BaseBoardModel:IsItemPaperBoxLocked` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:359` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetItemPaperBoxUnLockLevel` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:363` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetCurrentPaperBoxLevel` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:367` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:Try2UnlockPaperBoxItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:371` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInCircleOrder` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:383` | orders |
| `BaseBoardModel` | `BaseBoardModel:FindRandomPosition` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:387` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:391` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:IsBoardFull` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:399` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInValidOrder` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:403` | orders |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInSpreadOrder` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:407` | generator-lifecycle-and-position |
| `BaseBoardModel` | `BaseBoardModel:FindEmptySpreadPosition` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:411` | generator-lifecycle-and-position |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInSpreadOrderWithNum` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:479` | generator-lifecycle-and-position |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInDiagonalOrderWithNum` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:483` | orders |
| `BaseBoardModel` | `BaseBoardModel:GetAllBoardItems` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:487` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:FilterItems` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:495` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:GetCostEnergyType` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:499` | generator-lifecycle-and-position |
| `BaseBoardModel` | `BaseBoardModel:GetOrderCodeStateMap` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:503` | orders |
| `BaseBoardModel` | `BaseBoardModel:CountItemsCode` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:521` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_FillMergePairGroup` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:532` | merge |
| `BaseBoardModel` | `BaseBoardModel:FindMergePair` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:587` | merge |
| `BaseBoardModel` | `BaseBoardModel:ResetLogNearestTouchedMergeItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:641` | merge |
| `BaseBoardModel` | `BaseBoardModel:CheckNearestTouchedMergeItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:645` | merge |
| `BaseBoardModel` | `BaseBoardModel:_GetNearestTouchedMergeItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:649` | merge |
| `BaseBoardModel` | `BaseBoardModel:HasOpeningItem` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:677` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:SaveItemProperty` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:681` | shared-board-or-support |
| `BaseBoardModel` | `BaseBoardModel:_RemoveItemProperty` | `analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua:684` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:Init` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:25` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_LoadFileConfig` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:32` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:CalculateItemChainMap` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:45` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_LoadOtherServerConfig` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:71` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_OnStateChanged` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:86` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:LateInit` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:93` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_DropData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:97` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:UpdatePerSecond` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:102` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:GetGeneratorBoostConfig` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:113` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:ReloadFileConfig` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:123` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:Try2ProduceLuckyItem` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:138` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_GetGenerateLuckyItem` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:215` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_GetLevelFitConfig` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:237` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:IsSuperLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:250` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_GetTotalLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:258` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_SetTotalLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:265` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_GetLuckyLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:272` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_SetLuckyLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:279` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearLuckyLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:286` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearTotalLeftSpreadCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:293` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_UseSmartProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:300` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_UpdateSpreadConfigSmartWeight` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:304` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_InitEnergyBoostRatioAdjustData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:333` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:GetAdjustedMaxEnergyBoostRatio` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:338` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:RecordBoostRatioAdjustData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:352` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_IsSpecialModeOn` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:366` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_UpdateSpecialModeData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:370` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearSpecialModeData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:378` | shared-board-or-support |
| `LuckyProduceModel` | `LuckyProduceModel:_GetEnergyCostCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:383` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_AddEnergyCostCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:387` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_GetCurLuckyProduceConfigIndex` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:395` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_CalculateLuckyProduceConfigIndex` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:399` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_CheckLuckyProduceConfigIndex` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:411` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_CheckIfNeedResetEnergyCost` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:419` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_ResetEnergyCost` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:428` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_AddFreeLuckyProduceEnergyCostCount` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:436` | generator-lifecycle-and-position |
| `LuckyProduceModel` | `LuckyProduceModel:_CanFreeLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:451` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_PostProcessOnFreeLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:455` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_Try2TriggerContiLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:460` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_TriggerContiLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:477` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_CLearContiLuckyProduceData` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:484` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_CanContiLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:491` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:_PostProcessOnContiLuckyProduce` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:502` | lucky |
| `LuckyProduceModel` | `LuckyProduceModel:GetTestInfo` | `analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua:520` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:6` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:12` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow:AllowTap` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:22` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow:OnTap` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:26` | generator-entry-and-gates |
| `ItemSwallow` | `ItemSwallow:GetSwallowInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:100` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow:_CreateSwallowInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:104` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow.SwallowInfoToString` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:126` | shared-board-or-support |
| `ItemSwallow` | `ItemSwallow.StringToSwallowInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSwallow.lua:137` | shared-board-or-support |
| `ItemTransform` | `ItemTransform.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:5` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:11` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:UpdatePerSecond` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:22` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:AllowTap` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:32` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:CanAccelerate` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:36` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:ShowCountdownAnimation` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:40` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:OnTap` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:45` | generator-entry-and-gates |
| `ItemTransform` | `ItemTransform:OnSpeedUp` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:59` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:_SpeedUp` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:66` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:GetCodeWeightPairs` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:107` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:GetDuration` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:111` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:GetStartTimer` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:115` | generator-lifecycle-and-position |
| `ItemTransform` | `ItemTransform:GetSpeedUpCost` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:119` | shared-board-or-support |
| `ItemTransform` | `ItemTransform:GetTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:126` | generator-lifecycle-and-position |
| `ItemTransform` | `ItemTransform:GetNextTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:131` | generator-lifecycle-and-position |
| `ItemTransform` | `ItemTransform:_GetTimerAmount` | `analysis_output/logic_recovery/stage3/Board_Model_Item_ItemTransform.lua:136` | generator-lifecycle-and-position |
| `BaseOrder` | `BaseOrder.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:17` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:23` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:41` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:UpdateId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:45` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetRequirements` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:49` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:UpdateRequirements` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:53` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetRequirementFillStates` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:57` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetFilledRequirementCount` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:61` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetState` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:65` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:_SetState` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:69` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:UpdateState` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:82` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:SetFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:130` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetStateChange` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:137` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetStateChangeTime` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:141` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetType` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:145` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetAvatarName` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:149` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetMaxPossibleRewardNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:153` | orders |
| `BaseOrder` | `BaseOrder:GetRewards` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:157` | orders |
| `BaseOrder` | `BaseOrder:GetScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:161` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:_CalculateScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:165` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetGiftRewards` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:175` | orders |
| `BaseOrder` | `BaseOrder:IsBuffGoldDouble` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:179` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetGameMode` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:183` | shared-board-or-support |
| `BaseOrder` | `BaseOrder:GetDiffRange` | `analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:187` | shared-board-or-support |
| `MainOrder` | `MainOrder.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:4` | shared-board-or-support |
| `MainOrder` | `MainOrder:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:10` | shared-board-or-support |
| `MainOrder` | `MainOrder:UpdateRequirements` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:20` | shared-board-or-support |
| `MainOrder` | `MainOrder:SetGiftRewardInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:31` | orders |
| `MainOrder` | `MainOrder:GetInnerType` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:35` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetType` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:39` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetAvatarId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:49` | shared-board-or-support |
| `MainOrder` | `MainOrder:UpdateAvatarId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:53` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetAvatarName` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:57` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetMaxPossibleRewardNumber` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:85` | orders |
| `MainOrder` | `MainOrder:_HasGoldReward` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:106` | orders |
| `MainOrder` | `MainOrder:CanSupportAlbumBuff` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:128` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetOrderRewardByFinishOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:257` | orders |
| `MainOrder` | `MainOrder:IsBuffGoldDouble` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:274` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetGiftRewards` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:278` | orders |
| `MainOrder` | `MainOrder:GetBuffRewards` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:282` | orders |
| `MainOrder` | `MainOrder:GetSupportBuffId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:286` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetCookingFrenzyConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:290` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetCookingBIConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:295` | shared-board-or-support |
| `MainOrder` | `MainOrder:SetOrderBoostFinish` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:304` | orders |
| `MainOrder` | `MainOrder:GetSupportOrderBoost` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:308` | orders |
| `MainOrder` | `MainOrder:IsOrderBoostPro` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:316` | orders |
| `MainOrder` | `MainOrder:GetOrderBoostFinishRound` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:324` | orders |
| `MainOrder` | `MainOrder:IsButterfly` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:332` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetFirstRewardPropertyType` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:337` | orders |
| `MainOrder` | `MainOrder:GetScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:344` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetDiffScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:355` | shared-board-or-support |
| `MainOrder` | `MainOrder:GetTestDiffScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:375` | shared-board-or-support |
| `MainOrder` | `MainOrder:IsLuckyOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:393` | lucky |
| `MainOrder` | `MainOrder:IsBaselineOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:397` | orders |
| `MainOrder` | `MainOrder:GetDiffRange` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrder.lua:401` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel.Create` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:13` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:19` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:LoadFileConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:31` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:SafeCheckConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:89` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:OnSyncDataFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:111` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:LateInit` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:119` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:_RemoveErrorOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:151` | orders |
| `MainOrderModel` | `MainOrderModel:OrderAvatarIsEmpty` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:175` | orders |
| `MainOrderModel` | `MainOrderModel:_CheckSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:183` | orders |
| `MainOrderModel` | `MainOrderModel:UpdatePerSecond` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:258` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:TryRefreshTotalDiffScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:265` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:Destroy` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:280` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:_DBGetOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:284` | orders |
| `MainOrderModel` | `MainOrderModel:_CreateOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:312` | orders |
| `MainOrderModel` | `MainOrderModel:_DBGetLastFinishOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:322` | orders |
| `MainOrderModel` | `MainOrderModel:_DBGetRepeatWeightDecreaseInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:340` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:SaveRepeatWeightDecreaseInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:348` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:_DBAddOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:358` | orders |
| `MainOrderModel` | `MainOrderModel:_RemoveOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:385` | orders |
| `MainOrderModel` | `MainOrderModel:_DBRemoveOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:395` | orders |
| `MainOrderModel` | `MainOrderModel:_DBRemoveCDTimer` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:429` | generator-lifecycle-and-position |
| `MainOrderModel` | `MainOrderModel:_DBUpdateOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:441` | orders |
| `MainOrderModel` | `MainOrderModel:CustomerUpgradeTryFillChestCustomerOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:445` | orders |
| `MainOrderModel` | `MainOrderModel:GetRepeatWeightDecrease` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:605` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:ReduceRepeatWeightDecreaseByChainId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:609` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:ResetRepeatWeightDecreaseByChainId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:622` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:UpdateRepeatWeightDecrease` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:629` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetTotalDiffScore` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:640` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:RemoveOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:644` | orders |
| `MainOrderModel` | `MainOrderModel:_RemoveErrorOrderData` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:657` | orders |
| `MainOrderModel` | `MainOrderModel:GetAvatarId` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:669` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:UpdateRequirements` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:720` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:_OnEnterMainScene` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:745` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:_UpdateBakeOutOrderStatus` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:750` | orders |
| `MainOrderModel` | `MainOrderModel:_UpdateMainOrderStatus` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:769` | orders |
| `MainOrderModel` | `MainOrderModel:_OnBuffPropertyChanged` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:773` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetCodeCountMap` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:777` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:CheckItemCodeProgressUnlock` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:781` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:CanCreateSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:793` | orders |
| `MainOrderModel` | `MainOrderModel:CreateSpecialOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:800` | orders |
| `MainOrderModel` | `MainOrderModel:GetSpecialOrderConfigWithOffset` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:810` | orders |
| `MainOrderModel` | `MainOrderModel:IsSpecialOrderFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:814` | orders |
| `MainOrderModel` | `MainOrderModel:_TryCreateBranchOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:822` | orders |
| `MainOrderModel` | `MainOrderModel:IsBranchOrderFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:833` | orders |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderFinalRewardSlotName` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:837` | orders |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderRequirement` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:845` | orders |
| `MainOrderModel` | `MainOrderModel:_GetBranchOrderFinishMetaKey` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:853` | orders |
| `MainOrderModel` | `MainOrderModel:_SetBranchOrderFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:857` | orders |
| `MainOrderModel` | `MainOrderModel:_AddGiftRewardInfo` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:862` | orders |
| `MainOrderModel` | `MainOrderModel:ForceRefreshOrderForReturnUser` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:877` | orders |
| `MainOrderModel` | `MainOrderModel:GetFixedOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1184` | orders |
| `MainOrderModel` | `MainOrderModel:GetRandomOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1188` | orders |
| `MainOrderModel` | `MainOrderModel:GetRandomOrderConfigBySlot` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1195` | orders |
| `MainOrderModel` | `MainOrderModel:GetChestRandomOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1207` | orders |
| `MainOrderModel` | `MainOrderModel:GetSpecialOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1214` | orders |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1218` | orders |
| `MainOrderModel` | `MainOrderModel:GetLuckyOrderConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1222` | lucky |
| `MainOrderModel` | `MainOrderModel:GetItemCodeConfigMap` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1226` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetItemNumberWeightConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1230` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetAvatarConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1234` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetNormalAvatarConfig` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1238` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetMetaData` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1242` | shared-board-or-support |
| `MainOrderModel` | `MainOrderModel:GetLastFinishOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1246` | orders |
| `MainOrderModel` | `MainOrderModel:_LogOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1250` | orders |
| `MainOrderModel` | `MainOrderModel:_GetLogOrderActionOrderType` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1338` | orders |
| `MainOrderModel` | `MainOrderModel:CanTriggerLucky` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1352` | lucky |
| `MainOrderModel` | `MainOrderModel:CloseTriggerLucky` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1356` | lucky |
| `MainOrderModel` | `MainOrderModel:GetTutorialOrderModel` | `analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:1360` | orders |
| `SlotOrderModel` | `SlotOrderModel:Init` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:4` | shared-board-or-support |
| `SlotOrderModel` | `SlotOrderModel:OnSyncDataFinished` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:9` | shared-board-or-support |
| `SlotOrderModel` | `SlotOrderModel:LateInit` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:13` | shared-board-or-support |
| `SlotOrderModel` | `SlotOrderModel:_DBGetOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:17` | orders |
| `SlotOrderModel` | `SlotOrderModel:_DBAddOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:21` | orders |
| `SlotOrderModel` | `SlotOrderModel:_DBRemoveOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:25` | orders |
| `SlotOrderModel` | `SlotOrderModel:_TryFillOrders` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:29` | orders |
| `SlotOrderModel` | `SlotOrderModel:_TryCreateOrder` | `analysis_output/logic_recovery/stage3/Board_Model_Order_SlotOrderModel.lua:61` | orders |
| `BaseOrderCell` | `BaseOrderCell:GetDisplayRewards` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:4` | orders |
| `BaseOrderCell` | `BaseOrderCell:GetDisplayTray` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:8` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetTestInfoStr` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:12` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetDeliverAudioEffectName` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:15` | orders |
| `BaseOrderCell` | `BaseOrderCell:OnRewardCellInitFinish` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:19` | orders |
| `BaseOrderCell` | `BaseOrderCell:OnAvatarClick` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:35` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetCellType` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:38` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:Init` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:41` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatar` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:60` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatarByName` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:79` | shared-board-or-support |
| `BaseOrderCell` | `self.m_order.GetAvatarName` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:80` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatarByName` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:102` | shared-board-or-support |
| `BaseOrderCell` | `self.m_order.GetAvatarName` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:103` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateRequirementIcons` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:125` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateReward` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:145` | orders |
| `BaseOrderCell` | `BaseOrderCell:_SplitRewards` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:173` | orders |
| `BaseOrderCell` | `BaseOrderCell:_UpdateActivitySpecialRewardView` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:214` | orders |
| `BaseOrderCell` | `BaseOrderCell:_AddSpecialRewards` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:233` | orders |
| `BaseOrderCell` | `BaseOrderCell:_AddOneSpecialReward` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:236` | orders |
| `BaseOrderCell` | `BaseOrderCell:GetSpecialRewardByKey` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:273` | orders |
| `BaseOrderCell` | `BaseOrderCell:_UpdateServeButtonPosition` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:280` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_UpdateTray` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:305` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_OnShowItemTestInfoChanged` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:310` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:OnTestAddItemClicked` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:421` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:_OnTestFinishOrder` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:441` | orders |
| `BaseOrderCell` | `BaseOrderCell:OnDestroy` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:476` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetOrder` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:480` | orders |
| `BaseOrderCell` | `BaseOrderCell:GetIconArea` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:484` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetIcon` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:488` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:GetGoButton` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:492` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:SetOrderIconClickEnabled` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:496` | orders |
| `BaseOrderCell` | `BaseOrderCell:SetGoButtonEnabled` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:502` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:CheckHaveFinshOrderInActivity` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:506` | orders |
| `BaseOrderCell` | `BaseOrderCell:OnOrderStateChanged` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:528` | orders |
| `BaseOrderCell` | `BaseOrderCell:ScrollToOrder` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:554` | orders |
| `BaseOrderCell` | `BaseOrderCell:ScrollToOrderIfNotInView` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:558` | orders |
| `BaseOrderCell` | `BaseOrderCell:PlayEnterAnimation` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:564` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:PlayTrayAnimation` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:584` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:PlayTrayAnimationHide` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:593` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:PlayEnterBoardAnimation` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:604` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:PlayCoinEffect` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:643` | merge |
| `BaseOrderCell` | `BaseOrderCell:PlayLeaveAnimation` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:659` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:SetHandEffectActive` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:665` | shared-board-or-support |
| `BaseOrderCell` | `BaseOrderCell:HideTrayTrans` | `analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:669` | shared-board-or-support |

## 直接关联索引（静态线索）

每个函数记录源码区间、方法调用、限定调用和逻辑关键词。它们用于安排人工审阅，不等同于动态调用图，也不证明每个关键词在所有路径都生效。

| 模块 | 函数 | 源码区间 | 直接方法调用 | 逻辑关键词 |
|---|---|---|---|---|
| `ItemSpread` | `ItemSpread.Create` | `25-30` | - | - |
| `ItemSpread` | `ItemSpread:Init` | `31-68` | `GetChainId`, `UpdatePerSecond` | `ItemSpreadState.Closed`, `ItemSpreadState.Initializing`, `ItemSpreadState.Opened`, `Spread_Auto`, `Spread_CostEnergy`, `Spread_InitDuration`, `Spread_InitSpeedUpCost`, `Spread_ItemMaxNumber`, `Spread_ItemRecoveryDuration`, `Spread_ItemSpeedUpCost` |
| `ItemSpread` | `ItemSpread:Update` | `69-75` | `IsAutoSpread`, `Update`, `_TryAutoSpread` | - |
| `ItemSpread` | `ItemSpread:UpdatePerSecond` | `76-99` | `Call`, `CanAccelerate`, `GetBoardModel`, `GetComponent`, `GetLastUpdateTime`, `GetServerTime`, `GetTime`, `GetTimerAmount` | `ItemSpreadState.Initializing`, `ItemSpreadState.Opened`, `ItemSpreadState.Opening`, `m_itemMaxNumber`, `m_itemModel`, `m_itemRestNumber`, `m_startTimer`, `m_state`, `m_storageRestNumber` |
| `ItemSpread` | `ItemSpread:CanAccelerate` | `100-103` | `CanAccelerate` | `m_startTimer` |
| `ItemSpread` | `ItemSpread:ShowCountdownAnimation` | `104-108` | `CanAccelerate`, `GetComponent`, `IsAccelerated`, `ShowCountdownAnimation` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:ShowCountDown` | `109-113` | `GetItemRestNumber`, `GetState`, `IsDisposable`, `ShowCountDown` | `ItemSpreadState.Initializing`, `ItemSpreadState.Opening` |
| `ItemSpread` | `ItemSpread:_UpdateRecoveryState` | `114-141` | `GetBoardModel`, `UpdatePerSecond`, `_UpdateRecoveryState` | `EEventType.ItemOpened`, `ItemSpreadState.Initializing`, `ItemSpreadState.Opened`, `ItemSpreadState.Opening`, `m_itemMaxNumber`, `m_itemModel`, `m_itemRecoveryDuration`, `m_itemRestNumber`, `m_startTimer`, `m_state` |
| `ItemSpread` | `ItemSpread:OnTap` | `142-163` | `CanAccelerate`, `GetBoardModel`, `GetServerTime`, `GetStartTimer`, `GetTimerDuration`, `IsDisposable`, `OnTap`, `TryOpenIOSNotificationWindow` | `m_itemModel`, `m_itemRestNumber` |
| `ItemSpread` | `ItemSpread:OnOpen` | `164-171` | `GetBoardModel`, `GetId`, `LogAction`, `OnOpen`, `UpdatePerSecond` | `EEventType.ItemOpening`, `ItemSpreadState.Opening`, `m_itemModel`, `m_state` |
| `ItemSpread` | `ItemSpread:OnSpeedUp` | `172-175` | `OnSpeedUp`, `_SpeedUp` | - |
| `ItemSpread` | `ItemSpread:_SpeedUp` | `176-195` | `Call`, `Consume`, `GetBoardModel`, `GetCode`, `GetPropertyNum`, `GetSpeedUpCost`, `OnTimeSkip`, `_SpeedUp` | `BoardEventType.LackGem`, `m_itemModel`, `m_startTimer` |
| `ItemSpread` | `ItemSpread:OnTimeSkip` | `196-215` | `GetBoardModel`, `GetServerTime`, `GetTimerDuration`, `GetType`, `LogAction`, `OnTimeSkip`, `PlayEffect`, `UpdatePerSecond` | `m_itemModel`, `m_startTimer` |
| `ItemSpread` | `ItemSpread:TryUnlockCdByZroCd` | `216-221` | `TryUnlockCdByZroCd`, `TryUseCDBuff` | `m_itemRestNumber` |
| `ItemSpread` | `ItemSpread:TryUseCDBuff` | `222-231` | `Call`, `CanSupportCDBuff`, `CanSupportGeneratorBoostCDBuff`, `CanTestSupportCDFree`, `OnTimeSkip`, `TryUseCDBuff` | `m_itemRestNumber` |
| `ItemSpread` | `ItemSpread:OnTimeSkipInZeroRestNumber` | `232-247` | `Call`, `CostEnergy`, `GetBoardModel`, `GetType`, `IsGeneratorItem`, `OnTimeSkip`, `OnTimeSkipInZeroRestNumber` | `m_itemModel`, `m_itemRestNumber` |
| `ItemSpread` | `ItemSpread:EmptySpreadCount` | `248-258` | `Call`, `EmptySpreadCount`, `GetBoardModel`, `UpdatePerSecond` | `m_codeWeightPairs`, `m_itemModel`, `m_itemRestNumber`, `m_storageRestNumber`, `m_weightType` |
| `ItemSpread` | `ItemSpread:IsAutoSpread` | `259-262` | `IsAutoSpread` | `m_auto` |
| `ItemSpread` | `ItemSpread:GetOpenDuration` | `263-266` | `GetOpenDuration` | `m_openDuration` |
| `ItemSpread` | `ItemSpread:CostEnergy` | `267-274` | `CostEnergy` | `m_costEnergy` |
| `ItemSpread` | `ItemSpread:GetCodeWeightPairs` | `275-278` | `GetCodeWeightPairs` | `m_codeWeightPairs` |
| `ItemSpread` | `ItemSpread:GetItemRestNumber` | `279-282` | `GetItemRestNumber` | `m_itemRestNumber` |
| `ItemSpread` | `ItemSpread:GetStorageRestNumber` | `283-286` | `GetStorageRestNumber` | `m_storageRestNumber` |
| `ItemSpread` | `ItemSpread:GetSpreadCount` | `287-290` | `GetSpreadCount` | `m_spreadCount` |
| `ItemSpread` | `ItemSpread:GetSpreadMaxNum` | `291-294` | `GetSpreadMaxNum` | `m_itemMaxNumber` |
| `ItemSpread` | `ItemSpread:GetState` | `295-298` | `GetState` | `m_state` |
| `ItemSpread` | `ItemSpread:GetStartTimer` | `299-302` | `GetStartTimer` | `m_startTimer` |
| `ItemSpread` | `ItemSpread:GetWeightType` | `303-306` | `GetWeightType` | `m_weightType` |
| `ItemSpread` | `ItemSpread:GetTransformNumber` | `307-310` | `GetTransformNumber` | `m_transformNumber` |
| `ItemSpread` | `ItemSpread:GetAutoSpreadDecrementalRemainTypes` | `311-323` | `GetAutoSpreadDecrementalRemainTypes`, `IsAutoSpread` | `m_codeWeightPairs`, `m_itemRestNumber`, `m_weightType` |
| `ItemSpread` | `ItemSpread:CanSupportCDBuff` | `324-330` | `CanSupportCDBuff`, `CostEnergy`, `GetBoardModel`, `IsBuffActiveByType`, `IsDisposable` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:CanSupportSmart` | `331-334` | `CanSupportSmart`, `CostEnergy`, `GetBoardModel`, `GetType`, `IsBuffActiveByType`, `IsDisposable` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:CanSupportGeneratorBoost` | `335-338` | `CanSupportGeneratorBoost`, `CostEnergy`, `GetBoardModel`, `GetStartedActivityByDefinition`, `GetType`, `IsDisposable` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:CanSupportGeneratorBoostCDBuff` | `339-343` | `CanSupportGeneratorBoost`, `CanSupportGeneratorBoostCDBuff`, `GetStartedActivityByDefinition`, `IsNoCDActive` | - |
| `ItemSpread` | `ItemSpread:CanSupportBoostDisco` | `344-349` | `CanSupportBoostDisco`, `CanSupportItem`, `GetBoardModel`, `GetHandler`, `GetType` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:CanTestSupportCDFree` | `350-353` | `CanTestSupportCDFree`, `CostEnergy`, `IsDisposable` | - |
| `ItemSpread` | `ItemSpread:IsDisposable` | `354-357` | `IsDisposable` | `m_itemRecoveryDuration` |
| `ItemSpread` | `ItemSpread:GetTimerAmount` | `358-365` | `GetServerTime`, `GetTimerAmount`, `_GetTimerAmount` | `m_startTimer` |
| `ItemSpread` | `ItemSpread:GetNextTimerAmount` | `366-373` | `GetNextTimerAmount`, `GetServerTime`, `_GetTimerAmount` | `m_startTimer` |
| `ItemSpread` | `ItemSpread:_GetTimerAmount` | `374-395` | `GetTimerDuration`, `GetType`, `_GetTimerAmount` | `m_initDuration`, `m_itemModel`, `m_itemRecoveryDuration`, `m_openDuration`, `m_startTimer`, `m_state`, `m_storageRecoveryDuration`, `m_storageRestNumber` |
| `ItemSpread` | `ItemSpread:GetTimerDuration` | `396-411` | `GetTimerDuration` | `ItemSpreadState.Initializing`, `ItemSpreadState.Opened`, `ItemSpreadState.Opening`, `m_initDuration`, `m_itemRecoveryDuration`, `m_openDuration`, `m_state`, `m_storageRecoveryDuration`, `m_storageRestNumber` |
| `ItemSpread` | `ItemSpread:GetSpeedUpCost` | `412-435` | `GetForceSkipCost`, `GetSpeedUpCost`, `GetTimerAmount` | `ItemSpreadState.Initializing`, `ItemSpreadState.Opened`, `ItemSpreadState.Opening`, `m_initSpeedUpCost`, `m_itemSpeedUpCost`, `m_openSpeedUpCost`, `m_state`, `m_storageRestNumber`, `m_storageSpeedUpCost` |
| `ItemSpread` | `ItemSpread:IsChestUsedOnce` | `436-439` | `IsChestUsedOnce` | `m_itemMaxNumber`, `m_itemRestNumber`, `m_openDuration` |
| `ItemSpread` | `ItemSpread:CheckLuckyProduce` | `440-453` | `CanSupportBoostDisco`, `CheckLuckyProduce`, `GetBoardModel`, `GetModel` | `LuckyProduce`, `m_itemModel` |
| `ItemSpread` | `ItemSpread:TryGenerateLuckyItem` | `454-464` | `GetModel`, `GetModelConfig`, `TryGenerateLuckyItem` | `LuckyProduce` |
| `ItemSpread` | `ItemSpread:SafeSpreadItem` | `465-485` | `LogAction`, `SafeSpreadItem`, `TableToString` | `m_itemMaxNumber`, `m_itemRestNumber`, `m_storageMaxNumber`, `m_storageRestNumber` |
| `ItemSpread` | `ItemSpread:SpreadCheckEnergyRatioAndCode` | `486-557` | `GetBoardModel`, `GetChain`, `GetChainId`, `GetChainLevel`, `GetChainMaxLevel`, `GetCodeCountMap`, `GetModelConfig`, `GetOrderCodeLackCountMap` | `m_itemModel`, `m_testLastSpreadCodeEnergyBoost`, `m_testLastSpreadCodeOrigin`, `m_testLastSpreadFishNetProduceSmartCode` |
| `ItemSpread` | `ItemSpread:CosetRestNumber` | `558-581` | `CosetRestNumber`, `IsDisposable`, `NextEnergyBoostCostIndex` | `OrderItem`, `m_codeWeightPairs`, `m_itemRestNumber`, `m_spreadCount`, `m_weightType` |
| `ItemSpread` | `ItemSpread:TryGenerateDiscoItem` | `582-589` | `GetHandler`, `GetType`, `TryGenerateDiscoItem` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:DealActivityLimit` | `590-598` | `CanSupportBoostDisco`, `DealActivityLimit`, `GetHandler`, `GetType`, `TryUseDiscoItem` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:GenerateItemCode` | `599-632` | `Call`, `CanSupportBoostDisco`, `CheckLuckyProduce`, `CosetRestNumber`, `DealActivityLimit`, `GenerateItemCode`, `GetBoardModel`, `SafeSpreadItem` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:_GenerateItemCode` | `633-703` | `CanSupportGeneratorBoost`, `CanSupportSmart`, `GetBoardModel`, `GetForceSpreadItemCode`, `GetOrderItemCode`, `GetStartedActivityByDefinition`, `IsBuffActive`, `TryExtraProduceItem` | `OrderItem`, `OrderModelType`, `m_SmarOrderConfig`, `m_codeWeightPairs`, `m_itemModel`, `m_itemRestNumber`, `m_storageMaxNumber`, `m_weightType` |
| `ItemSpread` | `ItemSpread:GetOrderItemCode` | `704-746` | `CalculateOrderCodeLackNumMap`, `GetBoardModel`, `GetChainLevel`, `GetOrderBoostOrderCodeLackMap`, `GetOrderItemCode`, `GetOrderModel`, `_FlushLog`, `_Log` | `OrderItemDiffScoreLimit`, `OrderModelType`, `m_itemModel` |
| `ItemSpread` | `ItemSpread:_FixedGenerateItemCode` | `747-754` | `GenerateItemCode`, `GetComponent`, `GetStateType`, `GetType`, `_FixedGenerateItemCode` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:_TryGenerateItemCodeByOrderItem` | `755-774` | `GetChainId`, `GetChainLevel`, `GetModelConfig`, `_Log`, `_TryGenerateItemCodeByOrderItem` | `m_codeWeightPairs` |
| `ItemSpread` | `ItemSpread:_TryGenerateItemCodeAll` | `775-797` | `GetChainGenerators`, `GetChainId`, `GetModelConfig`, `IsUnlocked`, `_Log`, `_TryGenerateItemCodeAll` | `m_codeWeightPairs` |
| `ItemSpread` | `ItemSpread:_TryAutoSpread` | `798-828` | `CacheItemFromSpread`, `EmptySpreadCount`, `GenerateItemCode`, `GetAutoSpreadDecrementalRemainTypes`, `GetBoardModel`, `GetComponent`, `IsDisposable`, `IsServerControlOpen` | `ItemSpreadState.Opened`, `m_itemModel`, `m_itemRestNumber`, `m_spreadCount`, `m_state`, `m_transformNumber`, `m_weightType` |
| `ItemSpread` | `ItemSpread:CheckSpreadState` | `829-846` | `CheckSpreadState`, `IsDisposable`, `_NotifySpreadFailed` | `ItemSpreadState.Closed`, `ItemSpreadState.Initializing`, `ItemSpreadState.Opening`, `m_itemRestNumber`, `m_state` |
| `ItemSpread` | `ItemSpread:CheckSpreadPosAndAuto` | `847-862` | `CheckSpreadPosAndAuto`, `FindEmptyPositionInSpreadOrder`, `GetBoardModel`, `GetPosition`, `IsAutoSpread`, `_GetAutoSpreadPosition`, `_NotifySpreadFailed` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:CheckEnergy` | `863-883` | `Call`, `CanSupportBoostDisco`, `CheckEnergy`, `CostEnergy`, `GetBoardModel`, `GetCostEnergyType`, `GetType`, `HasEnoughEnergy` | `BoardEventType.LackEnergy`, `m_itemModel` |
| `ItemSpread` | `ItemSpread:SpreadCostEnergy` | `884-895` | `Consume`, `EnergyTypeToPropertyType`, `GetBoardModel`, `GetCode`, `GetCostEnergyType`, `SpreadCostEnergy` | `m_itemModel`, `m_testLastCostEnergyCount` |
| `ItemSpread` | `ItemSpread:_TrySpread` | `896-929` | `CheckEnergy`, `CheckSpreadPosAndAuto`, `CheckSpreadState`, `GenerateItemCode`, `GetBoardModel`, `GetItemModel`, `GetModel`, `GetPosition` | `EEventType.VibrationLight`, `LuckyProduce`, `m_itemModel` |
| `ItemSpread` | `ItemSpread:TryRemoveSelf` | `930-944` | `Call`, `GetBoardModel`, `GetComponent`, `IsDisposable`, `RemoveItem`, `TryRemoveSelf` | `BoardEventType.CollapseItem`, `m_itemModel`, `m_itemRestNumber`, `m_spreadCount`, `m_transformNumber` |
| `ItemSpread` | `ItemSpread:_GetAutoSpreadPosition` | `945-948` | `FindSpreadPosition`, `_GetAutoSpreadPosition` | `m_itemModel` |
| `ItemSpread` | `ItemSpread:_NotifySpreadFailed` | `949-959` | `Call`, `GetBoardModel`, `_NotifySpreadFailed` | `BoardEventType.SpreadFailed`, `EEventType.SpreadFailed`, `EEventType.VibrationHeavy`, `m_itemModel` |
| `ItemSpread` | `ItemSpread.GetCostEnergyNum` | `960-974` | `CanEnergyBoost`, `GetEnergyBoostCostNum`, `GetEnergyBoostPowerRatio`, `IsEnergyBoostModeOn` | - |
| `ItemSpread` | `ItemSpread:_Log` | `975-995` | `_Log` | `m_log` |
| `ItemSpread` | `ItemSpread:_FlushLog` | `996-1003` | `_FlushLog` | `m_log` |
| `ItemSpread` | `ItemSpread:GetTestLastSpreadInfo` | `1004-1011` | `GetTestLastSpreadInfo` | `m_testLastCostEnergyCount`, `m_testLastSpreadCodeEnergyBoost`, `m_testLastSpreadCodeOrigin`, `m_testLastSpreadFishNetProduceSmartCode` |
| `MainBoardModel` | `MainBoardModel:Init` | `21-52` | `GetIdGenerator`, `GetTable`, `InitSpreadRefreshFunc` | `Order`, `OrderData`, `OrderMeta`, `OrderMetaData`, `OrderModelType`, `m_codeRequireCount`, `m_codeStateMap`, `m_gameMode`, `m_itemCacheData`, `m_itemCacheModel` |
| `MainBoardModel` | `MainBoardModel:InitSpreadRefreshFunc` | `53-118` | `Call`, `CanSupportBoostDisco`, `CanSupportCDBuff`, `CanSupportGeneratorBoostCDBuff`, `CanSupportSmart`, `GetStartedActivityByDefinition`, `InitRefreshrestNumberZeroCD`, `InitSpreadRefreshFunc` | `BoardEventType.DiscoBoostTrigger`, `BoardEventType.GeneratorBoostBuffActive`, `BoardEventType.SmartBuffConsume`, `BoardEventType.ZeroCDItemBuffConsume`, `EEventType.BuffNoZeroCDPlayAct`, `EEventType.BuffPropertyConsume`, `EEventType.GeneratorBoostBuffActiveLogic`, `EEventType.GeneratorBoostBuffActivePlayed`, `EEventType.SmartBuffItemSpreadAct`, `EEventType.TriggerBoostDiscoActStarted` |
| `MainBoardModel` | `MainBoardModel:OnSyncDataFinished` | `119-131` | `CountItemsCode`, `OnSyncDataFinished`, `UpdateOpeningItem`, `UpdateOrderState` | `m_itemCacheModel`, `m_itemLayerModel`, `m_itemManager`, `m_itemStoreModel`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:LateInit` | `132-141` | `LateInit`, `_BIPaperboxExtraItem`, `_CheckCacheItems`, `_CheckCobwebItems` | `m_itemGeneratorFactoryModel`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:Update` | `142-152` | `DispatchComponentUpdateEvent`, `GetAllBoardItems`, `GetGameMode`, `Update` | `m_gameMode` |
| `MainBoardModel` | `MainBoardModel:LoadFileConfig` | `153-165` | `GetLocalConfig`, `InitPaperBoxRewardConfig`, `LoadFileConfig` | `m_itemLayerModel`, `m_orderModels`, `m_promptConfig` |
| `MainBoardModel` | `MainBoardModel:UpdatePerSecond` | `166-174` | `GetGameMode`, `UpdatePerSecond` | `m_gameMode`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetGameMode` | `175-178` | `GetGameMode` | `m_gameMode` |
| `MainBoardModel` | `MainBoardModel:_SetItem` | `179-186` | `CountItemsCode`, `UpdateOrderState`, `_SetItem` | - |
| `MainBoardModel` | `MainBoardModel:GetCodeCountMap` | `187-204` | `GetCode`, `GetCodeCountMap`, `GetItem`, `GetItemCount` | `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:HasEnoughItemsToMergeAcquire` | `205-209` | `GetCodeCountMap`, `HasEnoughItemsToMergeAcquire` | - |
| `MainBoardModel` | `MainBoardModel:GenerateItems` | `210-229` | `CountItemsCode`, `GenerateItems`, `SaveItemProperty`, `UpdateOrderState`, `_SetItem` | `m_mergeAllIgnoredItems` |
| `MainBoardModel` | `MainBoardModel:FindSpreadPosition` | `230-237` | `FindEmptyPositionInCircleOrder`, `FindRandomPosition`, `FindSpreadPosition`, `GetPosition`, `IsDisposable` | - |
| `MainBoardModel` | `MainBoardModel:SpreadItem` | `238-271` | `CanSupportGeneratorBoost`, `GetActivedBuffString`, `GetCacheData`, `GetCode`, `GetComponent`, `GetEnergyBoostType`, `GetHandler`, `GetStartedActivityByDefinition` | `EEventType.ItemSpread` |
| `MainBoardModel` | `MainBoardModel:SkipItems` | `272-281` | `Call`, `DispatchComponentEvent`, `GetItem`, `GetValidPositionIterator`, `SkipItems` | `BoardEventType.TimeSkip` |
| `MainBoardModel` | `MainBoardModel:DragItem` | `282-334` | `CanItemAffect`, `CanItemMerge`, `CanItemMove`, `CanSwallow`, `DragItem`, `GetComponent`, `GetItem`, `GetPosition` | `EEventType.ItemMoveEnd` |
| `MainBoardModel` | `MainBoardModel:_AffectItem` | `335-412` | `Call`, `CanItemAffect`, `Close`, `CostSplitUseCount`, `FindEmptyPositionInSpreadOrder`, `GenerateItem`, `GetChain`, `GetChainId` | `BoardEventType.MergeItem`, `BoardEventType.SplitItem`, `EEventType.ItemMerged`, `EEventType.ItemShocked` |
| `MainBoardModel` | `MainBoardModel:_ShowAffectFailTip` | `413-425` | `GetSpecialType`, `IsBoardFull`, `ShowPromptWithKey`, `_ShowAffectFailTip` | - |
| `MainBoardModel` | `MainBoardModel:_UpdateAccelerate` | `426-439` | `GetComponent`, `UpdatePerSecond`, `_UpdateAccelerate` | - |
| `MainBoardModel` | `MainBoardModel:_MergeItem` | `440-444` | `_DoMergeItem`, `_LogMerge`, `_MergeItem` | - |
| `MainBoardModel` | `MainBoardModel:_DoMergeItem` | `445-516` | `CanSpreadEnergyBubble`, `CheckMoreUpload`, `FindEmptyPositionInSpreadOrder`, `GenerateType`, `GetBubbleInfo`, `GetBubblePrice`, `GetChainLevel`, `GetConfig` | `BubblePrice`, `BubbleSale`, `BubbleSalePrice`, `BubbleType`, `EEventType.CardItemGenerate`, `m_itemLayerModel`, `m_lastBreakBubbleType` |
| `MainBoardModel` | `MainBoardModel:_TrySpreadBubbleByMerge` | `517-587` | `FindEmptyPositionInSpreadOrder`, `GetBubbleChance`, `GetBubbleDecreaseRatio`, `GetPosition`, `GetType`, `IsBoardFull`, `IsFunctionOpen`, `RecordBubbleDecreaseInfo` | `Bubble`, `BubbleDecreaseModel`, `EEventType.BubbleSpread` |
| `MainBoardModel` | `MainBoardModel:_GetDecreaseBubbleChanceRatio` | `588-627` | `GetChain`, `GetChainId`, `GetCodeCountMap`, `GetGeneralConfByType`, `GetItemCodeConfigMap`, `GetOrderModel`, `GetOrders`, `GetRequirements` | `BubbleOrderDecrease`, `OrderModelType` |
| `MainBoardModel` | `MainBoardModel:_GetDecreaseBubbleChanceRatio2` | `628-666` | `GetChain`, `GetChainId`, `GetCodeCountMap`, `GetGeneralConfByType`, `GetType`, `_GetDecreaseBubbleChanceRatio2` | `Bubble`, `BubbleChainDecreaseLevel`, `BubbleChainDecreaseRatio` |
| `MainBoardModel` | `MainBoardModel:_HasBubbleItemWithInnerCode` | `667-677` | `GetComponent`, `GetInnerItemCode`, `GetItem`, `GetValidPositionIterator`, `_HasBubbleItemWithInnerCode` | - |
| `MainBoardModel` | `MainBoardModel:_CanBubbleBuyBonus` | `678-681` | `HasBubbleBuyBonus`, `_CanBubbleBuyBonus` | `m_lastBreakBubbleType` |
| `MainBoardModel` | `MainBoardModel:_CanBubbleOrderBonus` | `682-711` | `GetCodeCountMap`, `GetGeneralConfByType`, `GetItemCodeConfigMap`, `GetModelConfig`, `GetOrderCodeLackCountMap`, `_CanBubbleOrderBonus` | `BubbleOrderBonus`, `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:SellItem` | `712-728` | `Call`, `GetCode`, `GetSellingPrice`, `LogStore`, `RemoveItem`, `SellItem` | `BoardEventType.SellItem` |
| `MainBoardModel` | `MainBoardModel:UndoSellItem` | `729-756` | `Call`, `Consume`, `FindEmptyPositionInSpreadOrder`, `GetCode`, `GetItem`, `GetPosition`, `GetSellingPrice`, `LogAction` | `BoardEventType.UndoSellItem` |
| `MainBoardModel` | `MainBoardModel:BreakItem` | `757-764` | `BreakItem`, `DispatchComponentEvent`, `GetComponent`, `GetInnerItemCode` | `m_lastBreakBubbleType` |
| `MainBoardModel` | `MainBoardModel:_LogMove` | `765-779` | `GetCode`, `GetX`, `GetY`, `LogAction`, `TableToString`, `_LogMove` | - |
| `MainBoardModel` | `MainBoardModel:_LogMerge` | `780-805` | `CheckNearestTouchedMergeItem`, `GetCode`, `GetComponent`, `GetType`, `LogMerge`, `_LogMerge` | `BubblePrice`, `BubbleSalePrice`, `BubbleType` |
| `MainBoardModel` | `MainBoardModel:_LogCacheItems` | `806-811` | `LogAction`, `_LogCacheItems` | - |
| `MainBoardModel` | `MainBoardModel:_TryLogBoardFull` | `812-820` | `GetGameMode`, `IsBoardFull`, `IsInventoryFull`, `LogAction`, `_TryLogBoardFull` | - |
| `MainBoardModel` | `MainBoardModel:StoreItem` | `821-846` | `AddItem`, `Call`, `CanItemStore`, `CountItemsCode`, `GetCode`, `GetPosition`, `IsInventoryFull`, `LogAction` | `BoardEventType.StoreFailed`, `BoardEventType.StoreItem`, `EEventType.InventoryStoryItem`, `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:RetrieveStoredItem` | `847-866` | `Call`, `FindEmptyPositionInValidOrder`, `GetCode`, `GetItem`, `LogAction`, `RemoveItem`, `RetrieveStoredItem`, `SetPosition` | `BoardEventType.RetrieveStoredItem`, `EEventType.ItemRetrieved`, `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:GetStoredItem` | `867-870` | `GetItem`, `GetStoredItem` | `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:GetStoredItemCount` | `871-874` | `GetItemCount`, `GetStoredItemCount` | `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:IsInventoryFull` | `875-878` | `GetStoreSlotCount`, `GetStoredItemCount`, `IsInventoryFull` | - |
| `MainBoardModel` | `MainBoardModel:BuyStoreSlot` | `879-890` | `BuyStoreSlot`, `Consume`, `GetInventoryCapInNumber`, `GetLocalConfig`, `PlayEffect`, `SetInventoryCap` | `EEventType.InventoryNewSlot` |
| `MainBoardModel` | `MainBoardModel:GetStoreSlotCount` | `891-895` | `GetInventoryCapInNumber`, `GetLocalConfig`, `GetStoreSlotCount` | - |
| `MainBoardModel` | `MainBoardModel:CanItemStore` | `896-916` | `CanItemMove`, `CanItemStore`, `GetComponent`, `GetDuration`, `GetState`, `GetType`, `IsGeneratorFactoryItem`, `IsGeneratorFactoryOpen` | `ItemSpreadState.Opening` |
| `MainBoardModel` | `MainBoardModel:GetFirstUnlockGeneratorItemTipType` | `917-926` | `GetChainId`, `GetFirstUnlockGeneratorItemTipType` | - |
| `MainBoardModel` | `MainBoardModel:IsFirstUnlockGeneratorItemTipType` | `927-937` | `GetChainId`, `IsFirstUnlockGeneratorItemTipType` | - |
| `MainBoardModel` | `MainBoardModel:IsGeneratorFactoryOpen` | `938-941` | `IsGeneratorFactoryOpen`, `IsOpen` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:IsGeneratorFactoryItem` | `942-945` | `IsGeneratorFactoryItem` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:StoreFactoryItem` | `946-949` | `StoreFactoryItem`, `StoreItem` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:GetGenFactoryDefaultIndex` | `950-953` | `GetDefaultIndex`, `GetGenFactoryDefaultIndex` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:GetGenDataByType` | `954-957` | `GetGenDataByType` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:GetItemGeneratorFactoryModel` | `958-961` | `GetItemGeneratorFactoryModel` | `m_itemGeneratorFactoryModel` |
| `MainBoardModel` | `MainBoardModel:GetOrderModel` | `962-965` | `GetOrderModel` | `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:_RefreshOrderAndCodeData` | `966-974` | `CalculateOrderCodeCountData`, `GetCodeCountMap`, `UpdateState`, `_RefreshOrderAndCodeData` | `m_codeStateMap`, `m_orderCodeLackCountMap`, `m_orderCodeRequireCountMap`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:UpdateOrderState` | `975-979` | `UpdateOrderState`, `_RefreshOrderAndCodeData` | `EEventType.OrderStateChanged` |
| `MainBoardModel` | `MainBoardModel:CustomerUpgradeActive` | `980-991` | `CustomerUpgradeActive`, `_RefreshOrderAndCodeData` | `EEventType.CustomerUpgradeActive` |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeCountData` | `992-1015` | `CalculateOrderCodeCountData`, `GetOrders`, `GetRequirements`, `GetState` | `OrderState` |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeLackNumMap` | `1016-1042` | `CalculateOrderCodeLackNumMap`, `GetCodeCountMap`, `GetOrders`, `GetRequirements`, `GetState` | `OrderState` |
| `MainBoardModel` | `MainBoardModel:CalculateOrderCodeLackNumMapByLevelSize` | `1043-1079` | `CalculateOrderCodeLackNumMapByLevelSize`, `GetChainLevel`, `GetCodeCountMap`, `GetOrders`, `GetRequirements`, `GetState` | `OrderState` |
| `MainBoardModel` | `MainBoardModel:GetOrderBoostOrderCodeLackMap` | `1080-1100` | `GetAddOrderBoostScoreByOrder`, `GetCodeCountMap`, `GetModel`, `GetOrderBoostOrderCodeLackMap`, `GetOrders`, `GetRequirements` | `OrderBoost` |
| `MainBoardModel` | `MainBoardModel:FinishOrder` | `1101-1163` | `Call`, `CheckMoreUpload`, `ContainsOrder`, `FinishOrder`, `GetAddSmileScoreBySlot`, `GetBuffRewards`, `GetCurScore`, `GetGameMode` | `BoardEventType.FinishOrder`, `EEventType.ChestCustomerOrderFinish`, `Order`, `OrderBoost`, `OrderBoostSmoke`, `m_gameMode`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:RemoveOrderRequirementItems` | `1164-1201` | `CountItemsCode`, `GetCode`, `GetItem`, `GetItemCount`, `GetRequirements`, `GetValidPositionIterator`, `LogErrorInfo`, `RemoveItem` | `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:GetOrders` | `1202-1216` | `GetOrders` | `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetOrderModelType` | `1217-1224` | `ContainsOrder`, `GetOrderModelType` | `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeStateMap` | `1225-1228` | `GetOrderCodeStateMap` | `m_codeStateMap` |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeLackCount` | `1229-1232` | `GetOrderCodeLackCount` | `m_orderCodeLackCountMap` |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeLackCountMap` | `1233-1236` | `GetOrderCodeLackCountMap` | `m_orderCodeLackCountMap` |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeRequireCount` | `1237-1240` | `GetOrderCodeRequireCount` | `m_orderCodeRequireCountMap` |
| `MainBoardModel` | `MainBoardModel:GetOrderCodeRequireCountMap` | `1241-1244` | `GetOrderCodeRequireCountMap` | `m_orderCodeRequireCountMap` |
| `MainBoardModel` | `MainBoardModel:GetSpecialOrderConfig` | `1245-1252` | `GetInnerType`, `GetSlot`, `GetSpecialOrderConfig` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetCurrentSpecialOrder` | `1253-1257` | `GetCurrentSpecialOrder` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:_FinishSpecialOrder` | `1258-1286` | `Call`, `GetChainId`, `GetComponent`, `GetInnerItemCode`, `GetSpecialOrderConfig`, `GetType`, `SetSlot`, `UpdateOrderState` | `BoardEventType.FinishSpecialOrder`, `Order`, `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:_FinishBranchOrder` | `1287-1334` | `CacheItems`, `Call`, `FindEmptyPositionInValidOrder`, `GenerateItem`, `GetChainId`, `GetComponent`, `GetInnerItemCode`, `GetSpecialOrderConfig` | `BoardEventType.FinishBranchOrder`, `Order`, `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel.IsInGeneratorChain` | `1335-1348` | - | - |
| `MainBoardModel` | `MainBoardModel:CanCreateSpecialOrder` | `1349-1352` | `CanCreateSpecialOrder` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:CreateSpecialOrder` | `1353-1368` | `CreateSpecialOrder`, `GetSpecialOrderConfig` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:IsSpecialOrderFinished` | `1369-1372` | `IsSpecialOrderFinished` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetSpecialOrderConfigWithOffset` | `1373-1376` | `GetSpecialOrderConfigWithOffset` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:IsBranchOrderFinished` | `1377-1380` | `IsBranchOrderFinished` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetBranchOrderRequirement` | `1381-1384` | `GetBranchOrderRequirement` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetBranchTypeByRequirementInChain` | `1385-1393` | `GetBranchTypeByRequirementInChain`, `GetChainId` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:GetBranchOrderFinalRewardSlotName` | `1394-1397` | `GetBranchOrderFinalRewardSlotName` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:TryAcquireCookingFrenzyReward` | `1398-1430` | `AcquireRandomRewards`, `GenerateItems`, `GetCookingFrenzyConfig`, `GetModel`, `TryAcquireCookingFrenzyReward` | `m_gameMode` |
| `MainBoardModel` | `MainBoardModel:CanItemAffect` | `1431-1434` | `CanItemAffect`, `CanSpecialTypeAffect`, `GetSpecialType` | - |
| `MainBoardModel` | `MainBoardModel:CanItemSell` | `1435-1456` | `CanItemSell`, `GetChain`, `GetChainId`, `GetChainLevel`, `GetChainProtectLevel`, `GetSellingPrice`, `GetType`, `IsUnlocked` | - |
| `MainBoardModel` | `MainBoardModel:UpdateOpeningItem` | `1457-1470` | `Call`, `GetAllBoardItems`, `GetComponent`, `GetState`, `UpdateOpeningItem` | `BoardEventType.UpdateOpeningItem`, `ItemSpreadState.Opening`, `m_bHasOpeningItem` |
| `MainBoardModel` | `MainBoardModel:HasOpeningItem` | `1471-1474` | `HasOpeningItem` | `m_bHasOpeningItem` |
| `MainBoardModel` | `MainBoardModel:_BatchRemoveItems` | `1475-1510` | `GetCachedItem`, `GetCachedItemCount`, `GetItem`, `GetStoredItem`, `GetStoredItemCount`, `GetValidPositionIterator`, `RemoveCachedItem`, `RemoveItem` | `EEventType.ChangeCachedItems`, `EEventType.InventoryItemUpdate`, `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:RemoveItemsInChainList` | `1511-1528` | `Call`, `GetChainId`, `GetComponent`, `GetInnerItemCode`, `GetType`, `RemoveItemsInChainList`, `_BatchRemoveItems` | `BoardEventType.BatchRemoveItems` |
| `MainBoardModel` | `MainBoardModel:TransformItems2Score` | `1529-1596` | `Call`, `GetCachedItem`, `GetCachedItemCount`, `GetChainId`, `GetComponent`, `GetInnerItemCode`, `GetItem`, `GetStoredItem` | `BoardEventType.BatchRemoveItems`, `EEventType.ChangeCachedItems`, `EEventType.InventoryItemUpdate`, `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:TransformItems` | `1597-1682` | `AddItem`, `Call`, `GenerateItem`, `GetCachedItem`, `GetCachedItemCount`, `GetCode`, `GetItem`, `GetStoredItem` | `BoardEventType.BatchRemoveItems`, `BoardEventType.TransformItem`, `EEventType.ChangeCachedItems`, `EEventType.InventoryItemUpdate`, `EEventType.ItemTransform`, `m_itemStoreModel` |
| `MainBoardModel` | `MainBoardModel:TransformActivityBubble` | `1683-1698` | `ForceTransform`, `GetChainId`, `GetComponent`, `GetInnerItemCode`, `GetItem`, `GetValidPositionIterator`, `TransformActivityBubble` | - |
| `MainBoardModel` | `MainBoardModel:GetItemsOnBoard` | `1699-1734` | `CheckGeneratorUnlockedByItemType`, `GetChainLevel`, `GetItem`, `GetItemCodeConfigMap`, `GetItemsOnBoard`, `GetType`, `GetValidPositionIterator` | `OrderModelType`, `m_orderModels` |
| `MainBoardModel` | `MainBoardModel:_CheckCobwebItems` | `1735-1776` | `CountItemsCode`, `GetCheckCobwebFinishedInNumber`, `GetCode`, `GetComponent`, `GetInnerItemCode`, `GetItem`, `GetValidPositionIterator`, `IsEnergyBoostModeOn` | - |
| `MainBoardModel` | `MainBoardModel:InitRefreshrestNumberZeroCD` | `1777-1801` | `DispatchComponentEvent`, `GetComponent`, `GetItem`, `GetValidPositionIterator`, `InitRefreshrestNumberZeroCD` | - |
| `MainBoardModel` | `MainBoardModel:CacheItems` | `1802-1806` | `CacheItems`, `_UpdateCacheItems` | - |
| `MainBoardModel` | `MainBoardModel:CacheItemsFromBoard` | `1807-1811` | `CacheItemsFromBoard`, `_UpdateCacheItems` | - |
| `MainBoardModel` | `MainBoardModel:_PostProcessOnPopCachedItem` | `1812-1821` | `GetCachedItemCount`, `LogAction`, `_PostProcessOnPopCachedItem`, `_TryLogBoardFull`, `_UpdateCacheItems` | - |
| `MainBoardModel` | `MainBoardModel:_CheckCacheItems` | `1822-1837` | `GetCachedItemCount`, `GetRecordMainCache`, `LogProject`, `_CheckCacheItems`, `_GetAllCacheItemsForCheck`, `_XORCaheItemCount` | `m_itemCacheModel` |
| `MainBoardModel` | `MainBoardModel:_UpdateCacheItems` | `1838-1842` | `GetCachedItemCount`, `SetRecordMainCache`, `_UpdateCacheItems`, `_XORCaheItemCount` | - |
| `MainBoardModel` | `MainBoardModel:_XORCaheItemCount` | `1843-1846` | `_XORCaheItemCount` | - |
| `MainBoardModel` | `MainBoardModel:_BIPaperboxExtraItem` | `1847-1860` | `GetItem`, `GetPaperBoxExtraReward`, `GetType`, `GetValidPositionIterator`, `LogAction`, `_BIPaperboxExtraItem` | - |
| `MainBoardModel` | `MainBoardModel:GetPaperBoxRewardConfig` | `1861-1863` | `GetLocalConfig`, `GetPaperBoxRewardConfig` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:_LogCacheItems` | `4-6` | `_LogCacheItems` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItems` | `7-14` | `CacheItems`, `PushItems`, `_LogCacheItems` | `EEventType.CacheItems`, `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItemsFromBoard` | `15-38` | `CacheItemsFromBoard`, `GetCode`, `GetId`, `GetItem`, `GetPosition`, `LogAction`, `PushItems`, `_LogCacheItems` | `EEventType.CacheItems`, `m_itemCacheModel`, `m_itemManager` |
| `BaseActionBoardModel` | `BaseActionBoardModel:CacheItemFromSpread` | `39-47` | `CacheItemFromSpread`, `Call`, `PushItems`, `_LogCacheItems` | `BoardEventType.CacheItemFromSpread`, `EEventType.CacheItems`, `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:PopCachedItem` | `48-86` | `Call`, `FindEmptyPositionInValidOrder`, `GenerateItem`, `GetCode`, `GetItem`, `GetType`, `IsBoardFull`, `LogErrorInfo` | `BoardEventType.PopCachedItem`, `EEventType.PopCachedItem`, `m_itemCacheModel`, `m_itemManager`, `m_mergeAllIgnoredItems` |
| `BaseActionBoardModel` | `BaseActionBoardModel:_TryGetNewPosition` | `87-92` | `FindEmptySpreadPosition`, `IsServerControlOpen`, `_TryGetNewPosition` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:_PostProcessOnPopCachedItem` | `93-95` | `_PostProcessOnPopCachedItem` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:RemoveCachedItem` | `96-99` | `RemoveCachedItem`, `RemoveItem` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItem` | `100-103` | `GetCachedItem`, `GetItem` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItemCount` | `104-107` | `GetCachedItemCount`, `GetItemCount` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetAllCacheItems` | `108-111` | `GetAllCacheItems` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetItemCacheModel` | `112-115` | `GetItemCacheModel` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCachedItems` | `116-119` | `GetAllCachedItemsWithSort`, `GetCachedItems` | `m_itemCacheModel` |
| `BaseActionBoardModel` | `BaseActionBoardModel:SaveItemProperty` | `120-123` | `SaveItemProperty`, `SetItem` | `m_itemManager` |
| `BaseActionBoardModel` | `BaseActionBoardModel:_RemoveItemProperty` | `124-135` | `GetId`, `GetItem`, `GetPosition`, `GetType`, `RemoveItem`, `_RemoveItemProperty` | `m_itemLayerModel`, `m_itemManager` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetCodeCountMap` | `136-152` | `GetCachedItem`, `GetCachedItemCount`, `GetCodeCountMap` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:CollectBoardPropertyRewardsWithoutConvert` | `153-160` | `CollectBoardPropertyRewardsWithoutConvert`, `GetItem`, `GetValidPositionIterator`, `_CalculateItemCollectRewards` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:_CalculateItemCollectRewards` | `161-263` | `GetCode`, `GetCodeWeightPairs`, `GetComponent`, `GetModelConfig`, `GetRewards`, `GetSpreadCount`, `GetSpreadMaxNum`, `GetWeightType` | `Spread_WeightType` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPromptConfig` | `264-267` | `GetPromptConfig` | `m_promptConfig` |
| `BaseActionBoardModel` | `BaseActionBoardModel:InitPaperBoxRewardConfig` | `268-297` | `GetPaperBoxRewardConfig`, `GetPaperBoxRewardVerticalTiles`, `InitPaperBoxRewardConfig` | `m_paperboxExtraRewardAppearMap`, `m_paperboxExtraRewardMap` |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardConfig` | `298-300` | `GetPaperBoxRewardConfig` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardVerticalTiles` | `301-304` | `GetPaperBoxRewardVerticalTiles` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxRewardPosition` | `305-308` | `GetPaperBoxRewardPosition` | - |
| `BaseActionBoardModel` | `BaseActionBoardModel:GetPaperBoxExtraReward` | `309-313` | `GetPaperBoxExtraReward`, `GetPaperBoxRewardPosition`, `GetX`, `GetY` | `m_paperboxExtraRewardMap` |
| `BaseActionBoardModel` | `BaseActionBoardModel:IsPaperBoxExtraRewardFirstAppear` | `314-318` | `GetPaperBoxRewardPosition`, `GetX`, `GetY`, `IsPaperBoxExtraRewardFirstAppear` | `m_paperboxExtraRewardAppearMap` |
| `BaseActionBoardModel` | `BaseActionBoardModel:SetPaperBoxExtraRewardAppeared` | `319-323` | `GetPaperBoxRewardPosition`, `GetX`, `GetY`, `SetPaperBoxExtraRewardAppeared` | `m_paperboxExtraRewardAppearMap` |
| `BaseActionBoardModel` | `BaseActionBoardModel:_PostProcessCollapseItem` | `324-335` | `GetPaperBoxExtraReward`, `GetPaperBoxRewardPosition`, `LogAction`, `_PostProcessCollapseItem` | - |
| `BaseBoardModel` | `DEFINE_ITEM_EVENT` | `1-20` | `DispatchComponentEvent` | - |
| `BaseBoardModel` | `BaseBoardModel:GetModelInstance` | `21-24` | `GetModelInstance` | - |
| `BaseBoardModel` | `BaseBoardModel:_SetInstance` | `25-28` | `_SetInstance` | - |
| `BaseBoardModel` | `BaseBoardModel:Init` | `29-35` | `_SetInstance` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:UpdatePerSecond` | `36-41` | `DispatchComponentEvent`, `GetAllBoardItems`, `UpdatePerSecond` | - |
| `BaseBoardModel` | `BaseBoardModel:CreateMatrix` | `42-47` | `CreateMatrix` | - |
| `BaseBoardModel` | `BaseBoardModel:CreatePositionFromLocalPosition` | `48-53` | `CreatePositionFromLocalPosition` | - |
| `BaseBoardModel` | `BaseBoardModel:GetValidPositionIterator` | `54-57` | `GetValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:_ValidPositionIterator` | `58-76` | `GetX`, `GetY`, `_ValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:GetInverseYValidPositionIterator` | `77-80` | `GetInverseYValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:_InverseYValidPositionIterator` | `81-99` | `GetX`, `GetY`, `_InverseYValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:GetDiagonalValidPositionIterator` | `100-103` | `GetDiagonalValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:_DiagonalValidPositionIterator` | `104-122` | `GetX`, `GetY`, `_DiagonalValidPositionIterator` | - |
| `BaseBoardModel` | `BaseBoardModel:PositionIsValid` | `123-126` | `GetX`, `GetY`, `PositionIsValid` | - |
| `BaseBoardModel` | `BaseBoardModel:ToLocalPosition` | `127-132` | `GetX`, `GetY`, `ToLocalPosition` | - |
| `BaseBoardModel` | `BaseBoardModel:ToLocalPositionSetZ` | `133-138` | `GetX`, `GetY`, `ToLocalPositionSetZ` | - |
| `BaseBoardModel` | `BaseBoardModel:IsPositionInteractable` | `139-142` | `IsPositionInteractable`, `PositionIsValid` | - |
| `BaseBoardModel` | `BaseBoardModel:GenerateItem` | `143-154` | `GenerateItem`, `SaveItemProperty`, `_SetItem` | `m_mergeAllIgnoredItems` |
| `BaseBoardModel` | `BaseBoardModel:ReplaceItem` | `155-159` | `GenerateItem`, `GetPosition`, `RemoveItem`, `ReplaceItem` | - |
| `BaseBoardModel` | `BaseBoardModel:RemoveItem` | `160-169` | `GetComponent`, `GetPosition`, `GetState`, `RemoveItem`, `UpdateOpeningItem`, `_RemoveItemProperty`, `_SetItem` | `ItemSpreadState.Opening` |
| `BaseBoardModel` | `BaseBoardModel:SpreadItem` | `170-182` | `Call`, `GenerateItem`, `SpreadItem` | `BoardEventType.SpreadItem` |
| `BaseBoardModel` | `BaseBoardModel:ShockNeighborItems` | `183-192` | `DispatchComponentEvent`, `GetItem`, `ShockNeighborItems` | - |
| `BaseBoardModel` | `BaseBoardModel:CollapseItem` | `193-220` | `Call`, `CanItemMove`, `CollapseItem`, `GetCode`, `GetComponent`, `GetInnerItemCode`, `GetItem`, `LogAction` | `BoardEventType.CollapseItem`, `EEventType.PaperboxDisappear` |
| `BaseBoardModel` | `BaseBoardModel:_PostProcessCollapseItem` | `221-223` | `_PostProcessCollapseItem` | - |
| `BaseBoardModel` | `BaseBoardModel:SkipItems` | `224-227` | `SkipItems` | - |
| `BaseBoardModel` | `BaseBoardModel:DragItem` | `228-231` | `DragItem` | - |
| `BaseBoardModel` | `BaseBoardModel:_MergeItem` | `232-235` | `_DoMergeItem`, `_MergeItem` | - |
| `BaseBoardModel` | `BaseBoardModel:_DoMergeItem` | `236-261` | `Call`, `GetComponent`, `GetMergedType`, `GetType`, `IsUnlocked`, `RemoveItem`, `ReplaceItem`, `ShockNeighborItems` | `BoardEventType.MergeItem`, `EEventType.ItemMerged`, `EEventType.ItemShocked` |
| `BaseBoardModel` | `BaseBoardModel:MergeAll` | `262-306` | `FindMergePair`, `GetComponent`, `GetItem`, `GetItemRestNumber`, `GetOrderCodeRequireCountMap`, `GetValidPositionIterator`, `MergeAll`, `ShowPrompt` | `m_mergeAllIgnoredItems` |
| `BaseBoardModel` | `BaseBoardModel:GetDistanceInBoard` | `307-310` | `GetDistanceInBoard`, `GetX`, `GetY` | - |
| `BaseBoardModel` | `BaseBoardModel:CanItemMove` | `311-324` | `AllowTap`, `CanItemMove`, `GetComponent` | - |
| `BaseBoardModel` | `BaseBoardModel:CanItemFall` | `325-328` | `CanItemFall`, `CanItemMove` | - |
| `BaseBoardModel` | `BaseBoardModel:CanItemMerge` | `329-358` | `CanItemMerge`, `GetComponent`, `GetInnerItemCode`, `GetMergedType`, `GetType`, `IsChestUsedOnce`, `IsGeneratorFactoryItem`, `IsGeneratorFactoryOpen` | - |
| `BaseBoardModel` | `BaseBoardModel:IsItemPaperBoxLocked` | `359-362` | `GetCurrentPaperBoxLevel`, `GetItemPaperBoxUnLockLevel`, `IsItemPaperBoxLocked` | - |
| `BaseBoardModel` | `BaseBoardModel:GetItemPaperBoxUnLockLevel` | `363-366` | `GetItemPaperBoxUnLockLevel` | - |
| `BaseBoardModel` | `BaseBoardModel:GetCurrentPaperBoxLevel` | `367-370` | `GetCurrentPaperBoxLevel` | - |
| `BaseBoardModel` | `BaseBoardModel:Try2UnlockPaperBoxItem` | `371-382` | `GetComponent`, `GetItem`, `GetValidPositionIterator`, `Try2Unlock`, `Try2UnlockPaperBoxItem` | - |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInCircleOrder` | `383-386` | `FindEmptyPositionInCircleOrder` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindRandomPosition` | `387-390` | `FindRandomPosition` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:GetItem` | `391-394` | `GetItem` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:_SetItem` | `395-398` | `SetItem`, `_SetItem` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:IsBoardFull` | `399-402` | `HasEmptyPosition`, `IsBoardFull` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInValidOrder` | `403-406` | `FindEmptyPositionInValidOrder` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInSpreadOrder` | `407-410` | `FindEmptyPositionInSpreadOrder` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindEmptySpreadPosition` | `411-478` | `FilterItems`, `FindEmptyPositionInSpreadOrder`, `FindEmptyPositionInValidOrder`, `FindEmptySpreadPosition`, `GetChainId`, `GetChainLevel`, `GetComponent`, `GetDistanceInBoard` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInSpreadOrderWithNum` | `479-482` | `FindEmptyPositionInSpreadOrderWithNum` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FindEmptyPositionInDiagonalOrderWithNum` | `483-486` | `FindEmptyPositionInDiagonalOrderWithNum` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:GetAllBoardItems` | `487-494` | `GetAllBoardItems`, `GetAllItems` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:FilterItems` | `495-498` | `FilterItems` | `m_itemLayerModel` |
| `BaseBoardModel` | `BaseBoardModel:GetCostEnergyType` | `499-502` | `GetCostEnergyType` | - |
| `BaseBoardModel` | `BaseBoardModel:GetOrderCodeStateMap` | `503-506` | `GetOrderCodeStateMap` | - |
| `BaseBoardModel` | `BaseBoardModel:GetCodeCountMap` | `507-520` | `CountItemsCode`, `GetCodeCountMap` | `m_codeCountMap` |
| `BaseBoardModel` | `BaseBoardModel:CountItemsCode` | `521-531` | `CountItemsCode`, `GetAllBoardItems`, `GetCode` | `m_codeCountMap` |
| `BaseBoardModel` | `BaseBoardModel:_FillMergePairGroup` | `532-586` | `GetComponent`, `GetInnerItemCode`, `GetItem`, `GetMergedType`, `GetType`, `IsChestUsedOnce`, `IsGeneratorFactoryItem`, `IsGeneratorFactoryOpen` | - |
| `BaseBoardModel` | `BaseBoardModel:FindMergePair` | `587-640` | `FindMergePair`, `GetComponent`, `GetType`, `GetValidPositionIterator`, `_FillMergePairGroup`, `_GetNearestTouchedMergeItem` | `m_logNearestTouchedMergeItem` |
| `BaseBoardModel` | `BaseBoardModel:ResetLogNearestTouchedMergeItem` | `641-644` | `ResetLogNearestTouchedMergeItem` | `m_logNearestTouchedMergeItem` |
| `BaseBoardModel` | `BaseBoardModel:CheckNearestTouchedMergeItem` | `645-648` | `CheckNearestTouchedMergeItem` | `m_logNearestTouchedMergeItem` |
| `BaseBoardModel` | `BaseBoardModel:_GetNearestTouchedMergeItem` | `649-676` | `GetDistanceInBoard`, `GetPosition`, `GetType`, `_GetNearestTouchedMergeItem` | - |
| `BaseBoardModel` | `BaseBoardModel:HasOpeningItem` | `677-680` | `HasOpeningItem` | - |
| `BaseBoardModel` | `BaseBoardModel:SaveItemProperty` | `681-683` | `SaveItemProperty` | - |
| `BaseBoardModel` | `BaseBoardModel:_RemoveItemProperty` | `684-685` | `_RemoveItemProperty` | - |
| `LuckyProduceModel` | `LuckyProduceModel:Init` | `25-31` | `_InitEnergyBoostRatioAdjustData`, `_LoadFileConfig` | `EEventType.PropertyConsumed`, `LuckyProduce`, `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_LoadFileConfig` | `32-44` | `GetLocalConfig`, `_LoadFileConfig` | `LuckyProduce`, `LuckyProduceModel`, `m_mapGeneratorType2Config`, `m_spreadConfigs` |
| `LuckyProduceModel` | `LuckyProduceModel:CalculateItemChainMap` | `45-70` | `CalculateItemChainMap`, `GetChainId`, `GetChainLevel`, `GetModelConfig` | `LuckyProduceModel`, `m_spreadConfigs` |
| `LuckyProduceModel` | `LuckyProduceModel:_LoadOtherServerConfig` | `71-85` | `GetInteger`, `_LoadOtherServerConfig` | `LuckyProduceModel`, `LuckyProduceSmart`, `m_arrLuckyProduceConfig`, `m_smartProduceRatio` |
| `LuckyProduceModel` | `LuckyProduceModel:_OnStateChanged` | `86-92` | `_OnStateChanged`, `_UpdateSpecialModeData` | `LuckyProduceModel`, `m_state` |
| `LuckyProduceModel` | `LuckyProduceModel:LateInit` | `93-96` | `CalculateItemChainMap`, `LateInit` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_DropData` | `97-101` | `_ClearSpecialModeData`, `_DropData` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:UpdatePerSecond` | `102-106` | `UpdatePerSecond`, `_CheckIfNeedResetEnergyCost` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_OnPropertyConsumed` | `107-112` | `_AddEnergyCostCount`, `_OnPropertyConsumed` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:GetGeneratorBoostConfig` | `113-122` | `GetGeneratorBoostConfig`, `GetLuckyProduceConfig`, `GetStartedActivityByDefinition` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:ReloadFileConfig` | `123-137` | `CalculateItemChainMap`, `ReloadFileConfig`, `_ClearLuckyLeftSpreadCount`, `_ClearTotalLeftSpreadCount`, `_LoadFileConfig` | `LuckyProduceModel`, `m_spreadConfigs` |
| `LuckyProduceModel` | `LuckyProduceModel:Try2ProduceLuckyItem` | `138-214` | `GetStartedActivityByDefinition`, `GetState`, `GetType`, `HaveAndCanExtraLuckyProduce`, `Try2ProduceLuckyItem`, `_CanContiLuckyProduce`, `_CanFreeLuckyProduce`, `_GetGenerateLuckyItem` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetGenerateLuckyItem` | `215-236` | `_GetGenerateLuckyItem`, `_UpdateSpreadConfigSmartWeight`, `_UseSmartProduce` | `Lucky`, `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetLevelFitConfig` | `237-249` | `GetCurrentLevel`, `_GetLevelFitConfig` | `LuckyProduceModel`, `m_mapGeneratorType2Config` |
| `LuckyProduceModel` | `LuckyProduceModel:IsSuperLuckyProduce` | `250-257` | `IsSuperLuckyProduce`, `_GetLevelFitConfig` | `LuckyProduceModel` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetTotalLeftSpreadCount` | `258-264` | `GetValue`, `_GetTotalLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_SetTotalLeftSpreadCount` | `265-271` | `Set`, `_SetTotalLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetLuckyLeftSpreadCount` | `272-278` | `GetValue`, `_GetLuckyLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_SetLuckyLeftSpreadCount` | `279-285` | `Set`, `_SetLuckyLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearLuckyLeftSpreadCount` | `286-292` | `Remove`, `_ClearLuckyLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearTotalLeftSpreadCount` | `293-299` | `Remove`, `_ClearTotalLeftSpreadCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_UseSmartProduce` | `300-303` | `_UseSmartProduce` | `LuckyProduceModel`, `m_smartProduceRatio` |
| `LuckyProduceModel` | `LuckyProduceModel:_UpdateSpreadConfigSmartWeight` | `304-332` | `CanEnergyBoost`, `GetChainId`, `GetChainLevel`, `GetEnergyBoostPowerRatio`, `GetOrderCodeLackCountMap`, `_UpdateSpreadConfigSmartWeight`, `_UseSmartProduce` | `LuckyProduceModel`, `m_smartProduceRatio` |
| `LuckyProduceModel` | `LuckyProduceModel:_InitEnergyBoostRatioAdjustData` | `333-337` | `_InitEnergyBoostRatioAdjustData` | `LuckyProduceEnergyBoostRatioAdjustData`, `LuckyProduceModel`, `m_cachedBoostRatioAdjustData` |
| `LuckyProduceModel` | `LuckyProduceModel:GetAdjustedMaxEnergyBoostRatio` | `338-351` | `GetAdjustedMaxEnergyBoostRatio`, `IsServerControlOpen` | `LuckyProduceModel`, `m_cachedBoostRatioAdjustData` |
| `LuckyProduceModel` | `LuckyProduceModel:RecordBoostRatioAdjustData` | `352-365` | `IsEnergyBoostTargetItemType`, `IsServerControlOpen`, `RecordBoostRatioAdjustData` | `LuckyProduceEnergyBoostRatioAdjustData`, `LuckyProduceModel`, `m_cachedBoostRatioAdjustData` |
| `LuckyProduceModel` | `LuckyProduceModel:_IsSpecialModeOn` | `366-369` | `_IsSpecialModeOn` | `LuckyProduceModel`, `m_arrLuckyProduceConfig` |
| `LuckyProduceModel` | `LuckyProduceModel:_UpdateSpecialModeData` | `370-377` | `GetValue`, `_CalculateLuckyProduceConfigIndex`, `_UpdateSpecialModeData` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount`, `m_curLuckyProduceConfigIndex`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_ClearSpecialModeData` | `378-382` | `_ClearSpecialModeData` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount`, `m_curLuckyProduceConfigIndex` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetEnergyCostCount` | `383-386` | `GetValue`, `_GetEnergyCostCount` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_AddEnergyCostCount` | `387-394` | `Set`, `_AddEnergyCostCount`, `_CheckLuckyProduceConfigIndex`, `_GetEnergyCostCount`, `_IsSpecialModeOn` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_GetCurLuckyProduceConfigIndex` | `395-398` | `_GetCurLuckyProduceConfigIndex` | `LuckyProduceModel`, `m_curLuckyProduceConfigIndex` |
| `LuckyProduceModel` | `LuckyProduceModel:_CalculateLuckyProduceConfigIndex` | `399-410` | `_CalculateLuckyProduceConfigIndex`, `_GetEnergyCostCount` | `LuckyProduceModel`, `m_arrLuckyProduceConfig` |
| `LuckyProduceModel` | `LuckyProduceModel:_CheckLuckyProduceConfigIndex` | `411-418` | `_AddFreeLuckyProduceEnergyCostCount`, `_CalculateLuckyProduceConfigIndex`, `_CheckLuckyProduceConfigIndex` | `LuckyProduceModel`, `m_arrLuckyProduceConfig`, `m_curLuckyProduceConfigIndex` |
| `LuckyProduceModel` | `LuckyProduceModel:_CheckIfNeedResetEnergyCost` | `419-427` | `GetServerTime`, `GetValue`, `_CheckIfNeedResetEnergyCost`, `_IsSpecialModeOn`, `_ResetEnergyCost` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_ResetEnergyCost` | `428-435` | `GetServerTime`, `Remove`, `Set`, `_ClearSpecialModeData`, `_ResetEnergyCost`, `_UpdateSpecialModeData` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_AddFreeLuckyProduceEnergyCostCount` | `436-450` | `Set`, `_AddFreeLuckyProduceEnergyCostCount` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount`, `m_arrLuckyProduceConfig`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_CanFreeLuckyProduce` | `451-454` | `_CanFreeLuckyProduce`, `_GetEnergyCostCount` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount` |
| `LuckyProduceModel` | `LuckyProduceModel:_PostProcessOnFreeLuckyProduce` | `455-459` | `Set`, `_PostProcessOnFreeLuckyProduce` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_Try2TriggerContiLuckyProduce` | `460-476` | `_GetCurLuckyProduceConfigIndex`, `_IsSpecialModeOn`, `_TriggerContiLuckyProduce`, `_Try2TriggerContiLuckyProduce` | `LuckyProduceModel`, `m_arrLuckyProduceConfig` |
| `LuckyProduceModel` | `LuckyProduceModel:_TriggerContiLuckyProduce` | `477-483` | `GetServerTime`, `Set`, `_TriggerContiLuckyProduce` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_CLearContiLuckyProduceData` | `484-490` | `Remove`, `_CLearContiLuckyProduceData` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_CanContiLuckyProduce` | `491-501` | `GetServerTime`, `GetValue`, `_CLearContiLuckyProduceData`, `_CanContiLuckyProduce` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:_PostProcessOnContiLuckyProduce` | `502-519` | `GetServerTime`, `GetValue`, `Set`, `_PostProcessOnContiLuckyProduce` | `LuckyProduceModel`, `m_dbTable` |
| `LuckyProduceModel` | `LuckyProduceModel:GetTestInfo` | `520-605` | `GetAdjustedMaxEnergyBoostRatio`, `GetEnergyBoostPowerRatio`, `GetServerTime`, `GetState`, `GetTestInfo`, `GetType`, `GetValue`, `IsServerControlOpen` | `LuckyProduceModel`, `m_arrFreeLuckyProduceEnergyCostCount`, `m_arrLuckyProduceConfig`, `m_cachedBoostRatioAdjustData`, `m_dbTable`, `m_mapGeneratorType2Config` |
| `ItemSwallow` | `ItemSwallow.Create` | `6-11` | - | - |
| `ItemSwallow` | `ItemSwallow:Init` | `12-21` | `GetServerTime`, `_CreateSwallowInfo` | `m_allowTap`, `m_generateTime`, `m_swallowInfo` |
| `ItemSwallow` | `ItemSwallow:AllowTap` | `22-25` | `AllowTap` | `m_allowTap` |
| `ItemSwallow` | `ItemSwallow:OnTap` | `26-53` | `Call`, `GetBoardModel`, `GetCode`, `GetItem`, `GetServerTime`, `GetValidPositionIterator`, `OnTap` | `BoardEventType.BatchSwallowItem`, `m_allowTap`, `m_generateTime`, `m_itemModel`, `m_swallowInfo` |
| `ItemSwallow` | `ItemSwallow:CanSwallow` | `54-62` | `CanSwallow`, `GetCode` | `m_swallowInfo` |
| `ItemSwallow` | `ItemSwallow:Swallow` | `63-99` | `Call`, `GetBoardModel`, `GetCode`, `GetComponent`, `GetPosition`, `LogAction`, `RemoveItem`, `SaveItemProperty` | `BoardEventType.SwallowItem`, `EEventType.ItemSwallow`, `m_allowTap`, `m_itemModel`, `m_swallowInfo` |
| `ItemSwallow` | `ItemSwallow:GetSwallowInfo` | `100-103` | `GetSwallowInfo` | `m_swallowInfo` |
| `ItemSwallow` | `ItemSwallow:_CreateSwallowInfo` | `104-125` | `GenerateTargetCode`, `_CreateSwallowInfo` | - |
| `ItemSwallow` | `ItemSwallow.SwallowInfoToString` | `126-136` | - | - |
| `ItemSwallow` | `ItemSwallow.StringToSwallowInfo` | `137-149` | - | - |
| `ItemTransform` | `ItemTransform.Create` | `5-10` | - | - |
| `ItemTransform` | `ItemTransform:Init` | `11-21` | `GetServerTime` | `m_allowTap`, `m_codeWeightPairs`, `m_duration`, `m_speedUpCost`, `m_startTimer` |
| `ItemTransform` | `ItemTransform:UpdatePerSecond` | `22-31` | `Call`, `GetTimerAmount`, `Transform`, `UpdatePerSecond` | `m_duration` |
| `ItemTransform` | `ItemTransform:AllowTap` | `32-35` | `AllowTap` | `m_allowTap` |
| `ItemTransform` | `ItemTransform:CanAccelerate` | `36-39` | `CanAccelerate` | `m_duration`, `m_startTimer` |
| `ItemTransform` | `ItemTransform:ShowCountdownAnimation` | `40-44` | `CanAccelerate`, `GetComponent`, `IsAccelerated`, `ShowCountdownAnimation` | `m_itemModel` |
| `ItemTransform` | `ItemTransform:OnTap` | `45-58` | `Call`, `Consume`, `EnergyTypeToPropertyType`, `GetBoardModel`, `GetCode`, `GetCostEnergyType`, `HasEnoughEnergy`, `OnTap` | `BoardEventType.LackEnergy`, `m_allowTap`, `m_itemModel` |
| `ItemTransform` | `ItemTransform:OnSpeedUp` | `59-65` | `OnSpeedUp`, `_SpeedUp` | `m_duration` |
| `ItemTransform` | `ItemTransform:_SpeedUp` | `66-87` | `Call`, `Consume`, `GetBoardModel`, `GetCode`, `GetPropertyNum`, `GetServerTime`, `GetSpeedUpCost`, `GetType` | `BoardEventType.LackGem`, `m_duration`, `m_itemModel`, `m_startTimer` |
| `ItemTransform` | `ItemTransform:Transform` | `88-106` | `Call`, `GetBoardModel`, `GetCode`, `LogAction`, `ReplaceItem`, `Transform` | `BoardEventType.TransformItem`, `EEventType.ItemTransform`, `m_codeWeightPairs`, `m_itemModel` |
| `ItemTransform` | `ItemTransform:GetCodeWeightPairs` | `107-110` | `GetCodeWeightPairs` | `m_codeWeightPairs` |
| `ItemTransform` | `ItemTransform:GetDuration` | `111-114` | `GetDuration` | `m_duration` |
| `ItemTransform` | `ItemTransform:GetStartTimer` | `115-118` | `GetStartTimer` | `m_startTimer` |
| `ItemTransform` | `ItemTransform:GetSpeedUpCost` | `119-125` | `GetSpeedUpCost`, `GetTimerAmount` | `m_speedUpCost` |
| `ItemTransform` | `ItemTransform:GetTimerAmount` | `126-130` | `GetServerTime`, `GetTimerAmount`, `_GetTimerAmount` | `m_startTimer` |
| `ItemTransform` | `ItemTransform:GetNextTimerAmount` | `131-135` | `GetNextTimerAmount`, `GetServerTime`, `_GetTimerAmount` | `m_startTimer` |
| `ItemTransform` | `ItemTransform:_GetTimerAmount` | `136-138` | `_GetTimerAmount` | `m_duration` |
| `BaseOrder` | `BaseOrder.Create` | `17-22` | - | - |
| `BaseOrder` | `BaseOrder:Init` | `23-40` | `_SetState` | `OrderState`, `m_filledRequirementCount`, `m_id`, `m_requirementFillStates`, `m_requirements` |
| `BaseOrder` | `BaseOrder:GetId` | `41-44` | `GetId` | `m_id` |
| `BaseOrder` | `BaseOrder:UpdateId` | `45-48` | `UpdateId` | `m_id` |
| `BaseOrder` | `BaseOrder:GetRequirements` | `49-52` | `GetRequirements` | `m_requirements` |
| `BaseOrder` | `BaseOrder:UpdateRequirements` | `53-56` | `UpdateRequirements` | `m_requirements` |
| `BaseOrder` | `BaseOrder:GetRequirementFillStates` | `57-60` | `GetRequirementFillStates` | `m_requirementFillStates` |
| `BaseOrder` | `BaseOrder:GetFilledRequirementCount` | `61-64` | `GetFilledRequirementCount` | `m_filledRequirementCount` |
| `BaseOrder` | `BaseOrder:GetState` | `65-68` | `GetState` | `m_state` |
| `BaseOrder` | `BaseOrder:_SetState` | `69-81` | `GetServerTime`, `_SetState` | `OrderState`, `OrderStateChange`, `m_state`, `m_stateChange`, `m_stateChangeTime` |
| `BaseOrder` | `BaseOrder:UpdateState` | `82-111` | `UpdateState`, `_SetState` | `OrderState`, `m_filledRequirementCount`, `m_requirementFillStates`, `m_requirements`, `m_state` |
| `BaseOrder` | `BaseOrder:CanDeliver` | `112-129` | `CanDeliver` | `m_requirements` |
| `BaseOrder` | `BaseOrder:SetFinished` | `130-136` | `GetRewards`, `SetFinished` | `OrderState`, `m_cacheRewards`, `m_state` |
| `BaseOrder` | `BaseOrder:GetStateChange` | `137-140` | `GetStateChange` | `m_stateChange` |
| `BaseOrder` | `BaseOrder:GetStateChangeTime` | `141-144` | `GetStateChangeTime` | `m_stateChangeTime` |
| `BaseOrder` | `BaseOrder:GetType` | `145-148` | `GetType` | - |
| `BaseOrder` | `BaseOrder:GetAvatarName` | `149-152` | `GetAvatarName` | - |
| `BaseOrder` | `BaseOrder:GetMaxPossibleRewardNumber` | `153-156` | `GetMaxPossibleRewardNumber` | - |
| `BaseOrder` | `BaseOrder:GetRewards` | `157-160` | `GetRewards` | - |
| `BaseOrder` | `BaseOrder:GetScore` | `161-164` | `GetRewards`, `GetScore`, `_CalculateScore` | - |
| `BaseOrder` | `BaseOrder:_CalculateScore` | `165-174` | `_CalculateScore` | - |
| `BaseOrder` | `BaseOrder:GetGiftRewards` | `175-178` | `GetGiftRewards` | - |
| `BaseOrder` | `BaseOrder:IsBuffGoldDouble` | `179-182` | `IsBuffGoldDouble` | - |
| `BaseOrder` | `BaseOrder:GetGameMode` | `183-186` | `GetGameMode` | - |
| `BaseOrder` | `BaseOrder:GetDiffRange` | `187-189` | `GetDiffRange` | - |
| `MainOrder` | `MainOrder.Create` | `4-9` | - | - |
| `MainOrder` | `MainOrder:Init` | `10-19` | - | `m_avatarId`, `m_bIsBaseline`, `m_bIsLucky`, `m_diffRange`, `m_innerType`, `m_orderModel` |
| `MainOrder` | `MainOrder:UpdateRequirements` | `20-30` | `ClearOrderReward`, `GetModel`, `GetSlot`, `IsActivityOpen`, `UpdateRequirements` | - |
| `MainOrder` | `MainOrder:SetGiftRewardInfo` | `31-34` | `SetGiftRewardInfo` | `m_giftRewards` |
| `MainOrder` | `MainOrder:GetInnerType` | `35-38` | `GetInnerType` | `m_innerType` |
| `MainOrder` | `MainOrder:GetType` | `39-48` | `GetInnerType`, `GetType` | `OrderType` |
| `MainOrder` | `MainOrder:GetAvatarId` | `49-52` | `GetAvatarId` | `m_avatarId` |
| `MainOrder` | `MainOrder:UpdateAvatarId` | `53-56` | `UpdateAvatarId` | `m_avatarId` |
| `MainOrder` | `MainOrder:GetAvatarName` | `57-84` | `GetAvatarConfig`, `GetAvatarName`, `GetInnerType`, `GetNormalAvatarConfig`, `GetStartedContiorders` | `OrderAvatarName`, `m_avatarId`, `m_contiorderAvatarName`, `m_orderModel` |
| `MainOrder` | `MainOrder:GetMaxPossibleRewardNumber` | `85-105` | `CanAddScore`, `GetBuffRewards`, `GetMaxPossibleRewardNumber`, `GetModel` | - |
| `MainOrder` | `MainOrder:_HasGoldReward` | `106-109` | `GetInnerType`, `IsOpen`, `_HasGoldReward` | - |
| `MainOrder` | `MainOrder:GetPrice` | `110-127` | `GetItemCodeConfigMap`, `GetPrice`, `LogErrorInfo` | `m_bIsBaseline`, `m_orderModel`, `m_requirements` |
| `MainOrder` | `MainOrder:CanSupportAlbumBuff` | `128-135` | `CanSupportAlbumBuff`, `GetDiffScore`, `GetInnerType`, `GetMainOrderScore2AlbumPack`, `GetSlot`, `GetStartedAlbumActivity`, `IsBuffActiveByType` | - |
| `MainOrder` | `MainOrder:GetRewards` | `136-256` | `CanAddScore`, `CanSupportAlbumBuff`, `GetAddScoreByOrder`, `GetDiffScore`, `GetFirstRewardPropertyType`, `GetInnerType`, `GetMainOrderCoinToEventToken`, `GetMainOrderScore2AlbumPack` | `OrderState`, `m_cacheRewards`, `m_state` |
| `MainOrder` | `MainOrder:GetOrderRewardByFinishOrder` | `257-273` | `GetOrderRewardByFinishOrder`, `GetRewards` | - |
| `MainOrder` | `MainOrder:IsBuffGoldDouble` | `274-277` | `IsBuffActiveByType`, `IsBuffGoldDouble`, `_HasGoldReward` | - |
| `MainOrder` | `MainOrder:GetGiftRewards` | `278-281` | `GetGiftRewards` | `m_giftRewards` |
| `MainOrder` | `MainOrder:GetBuffRewards` | `282-285` | `GetBuffRewards` | - |
| `MainOrder` | `MainOrder:GetSupportBuffId` | `286-289` | `GetSupportBuffId` | - |
| `MainOrder` | `MainOrder:GetCookingFrenzyConfig` | `290-294` | `GetCookingFrenzyConfig`, `GetCurBuffConifgByOrder`, `GetModel` | - |
| `MainOrder` | `MainOrder:GetCookingBIConfig` | `295-303` | `GetBIRewardByOrder`, `GetCookingBIConfig`, `GetCurBuffConifgByOrder`, `GetModel` | - |
| `MainOrder` | `MainOrder:SetOrderBoostFinish` | `304-307` | `SetOrderBoostFinish` | `m_bSupportSmile` |
| `MainOrder` | `MainOrder:GetSupportOrderBoost` | `308-315` | `GetAddOrderBoostScoreByOrder`, `GetModel`, `GetSupportOrderBoost` | `OrderBoost`, `m_bSupportSmile` |
| `MainOrder` | `MainOrder:IsOrderBoostPro` | `316-323` | `GetLogicType`, `GetModel`, `IsOrderBoostPro` | `OrderBoost` |
| `MainOrder` | `MainOrder:GetOrderBoostFinishRound` | `324-331` | `GetFinishRound`, `GetModel`, `GetOrderBoostFinishRound`, `GetSupportOrderBoost` | `OrderBoost` |
| `MainOrder` | `MainOrder:IsButterfly` | `332-336` | `GetButterflySlot`, `GetSlot`, `GetStartedButterflyActivity`, `IsButterfly` | - |
| `MainOrder` | `MainOrder:GetFirstRewardPropertyType` | `337-343` | `GetFirstRewardPropertyType`, `GetInnerType`, `GetModel` | - |
| `MainOrder` | `MainOrder:GetScore` | `344-354` | `GetInnerType`, `GetRewards`, `GetScore`, `GetSpecialOrderConfig`, `_CalculateScore` | - |
| `MainOrder` | `MainOrder:GetDiffScore` | `355-374` | `GetDiffScore`, `GetInnerType`, `GetItemCodeConfigMap`, `LogErrorInfo` | `m_orderModel`, `m_requirements` |
| `MainOrder` | `MainOrder:GetTestDiffScore` | `375-392` | `GetInnerType`, `GetItemCodeConfigMap`, `GetTestDiffScore` | `m_orderModel`, `m_requirements` |
| `MainOrder` | `MainOrder:IsLuckyOrder` | `393-396` | `IsLuckyOrder` | `m_bIsLucky` |
| `MainOrder` | `MainOrder:IsBaselineOrder` | `397-400` | `IsBaselineOrder` | `m_bIsBaseline` |
| `MainOrder` | `MainOrder:GetDiffRange` | `401-403` | `GetDiffRange` | `m_diffRange` |
| `MainOrderModel` | `MainOrderModel.Create` | `13-18` | - | - |
| `MainOrderModel` | `MainOrderModel:Init` | `19-30` | - | `EEventType.BranchStart`, `EEventType.ForceTryFillOrders`, `EEventType.LevelUp`, `EEventType.OrderBoostFillOrder`, `m_dbMetaTable`, `m_dbTable`, `m_idGenerator`, `m_tutorialOrderModel` |
| `MainOrderModel` | `MainOrderModel:LoadFileConfig` | `31-88` | `GetLocalConfig`, `LoadFileConfig`, `SafeCheckConfig` | `OrderAvatar`, `OrderBranch`, `OrderFixed`, `OrderItem`, `OrderItemNumberWeight`, `OrderRandom`, `OrderRandomReCall`, `OrderSpecial`, `m_avatarConfig`, `m_branchOrderConfig` |
| `MainOrderModel` | `MainOrderModel:SafeCheckConfig` | `89-110` | `SafeCheckConfig` | `m_avatarConfig` |
| `MainOrderModel` | `MainOrderModel:OnSyncDataFinished` | `111-118` | `OnSyncDataFinished`, `_DBGetLastFinishOrder`, `_DBGetRepeatWeightDecreaseInfo`, `_RemoveErrorOrder` | `m_lastFinishOrder`, `m_mapRepeatWeightDecreaseInfo`, `m_tutorialOrderModel` |
| `MainOrderModel` | `MainOrderModel:LateInit` | `119-150` | `GetStartedAlbumActivity`, `LateInit`, `RemoveOrderReward`, `TryRefreshTotalDiffScore`, `_CheckSpecialOrder`, `_UpdateMainOrderStatus` | `EEventType.BakeOutModeChanged`, `EEventType.BakeOutStateChanged`, `EEventType.BuffPropertyConsume`, `EEventType.BuffPropertyOutTime`, `EEventType.CharacterIntimacyStateChanged`, `EEventType.EnterMainScene`, `m_cacheAlbumRemoveSlot`, `m_tutorialOrderModel` |
| `MainOrderModel` | `MainOrderModel:_RemoveErrorOrder` | `151-174` | `GetModelConfig`, `GetOrders`, `GetRequirements`, `LogAction`, `OrderAvatarIsEmpty`, `_RemoveErrorOrder`, `_RemoveErrorOrderData` | `OrderAvatarIsEmpty`, `m_itemCodeConfigMap` |
| `MainOrderModel` | `MainOrderModel:OrderAvatarIsEmpty` | `175-182` | `GetAvatarName`, `GetSlot`, `OrderAvatarIsEmpty` | `OrderAvatarIsEmpty` |
| `MainOrderModel` | `MainOrderModel:_CheckSpecialOrder` | `183-257` | `CanCreateSpecialOrder`, `CreateSpecialOrder`, `GetChainId`, `GetCodeCountMap`, `GetModelConfig`, `LogAction`, `RefreshFlashSaleAfterSpecialOrderRecovered`, `RemoveItemsInChainList` | `m_boardModel`, `m_orders`, `m_specialOrderConfig` |
| `MainOrderModel` | `MainOrderModel:UpdatePerSecond` | `258-264` | `TryRefreshTotalDiffScore`, `UpdatePerSecond`, `_TryFillOrders` | `m_orders` |
| `MainOrderModel` | `MainOrderModel:TryRefreshTotalDiffScore` | `265-279` | `GetLocaleTime`, `GetValue`, `Set`, `TryRefreshTotalDiffScore` | `m_dbMetaTable`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:Destroy` | `280-283` | `Destroy` | - |
| `MainOrderModel` | `MainOrderModel:_DBGetOrders` | `284-311` | `GetReadOnlyValues`, `GetValue`, `SetGiftRewardInfo`, `_CreateOrder`, `_DBGetOrders` | `m_dbMetaTable`, `m_dbTable` |
| `MainOrderModel` | `MainOrderModel:_CreateOrder` | `312-321` | `_CreateOrder` | - |
| `MainOrderModel` | `MainOrderModel:_DBGetLastFinishOrder` | `322-339` | `GetReadOnlyValues`, `_CreateOrder`, `_DBGetLastFinishOrder` | `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:_DBGetRepeatWeightDecreaseInfo` | `340-347` | `GetValue`, `_DBGetRepeatWeightDecreaseInfo` | `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:SaveRepeatWeightDecreaseInfo` | `348-357` | `Remove`, `SaveRepeatWeightDecreaseInfo`, `Set` | `m_dbMetaTable`, `m_mapRepeatWeightDecreaseInfo` |
| `MainOrderModel` | `MainOrderModel:_DBAddOrder` | `358-384` | `BatchSet`, `GetAvatarId`, `GetDiffRange`, `GetId`, `GetInnerType`, `GetRequirements`, `GetSlot`, `IsBaselineOrder` | `m_dbMetaTable`, `m_dbTable` |
| `MainOrderModel` | `MainOrderModel:_RemoveOrder` | `385-394` | `GetStartedAlbumActivity`, `RemoveOrderReward`, `_DBRemoveOrder`, `_RemoveOrder` | `m_cacheAlbumRemoveSlot` |
| `MainOrderModel` | `MainOrderModel:_DBRemoveOrder` | `395-428` | `ChestOrderFinish`, `GetAvatarId`, `GetId`, `GetInnerType`, `GetModel`, `GetRequirements`, `GetValue`, `Remove` | `m_dbMetaTable`, `m_dbTable`, `m_lastFinishOrder`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:_DBRemoveCDTimer` | `429-440` | `GetMetaData`, `GetValue`, `Remove`, `_DBRemoveCDTimer` | - |
| `MainOrderModel` | `MainOrderModel:_DBUpdateOrder` | `441-444` | `Set`, `_DBUpdateOrder` | `m_dbTable` |
| `MainOrderModel` | `MainOrderModel:CustomerUpgradeTryFillChestCustomerOrders` | `445-526` | `CustomerUpgradeActive`, `CustomerUpgradeTryFillChestCustomerOrders`, `FinishFillChestCustomerOrder`, `Generate`, `GetChestCustomerOrderSlots`, `GetCustomConfigs`, `GetId`, `GetInnerType` | `Order`, `OrderState`, `OrderType`, `m_boardModel`, `m_idGenerator`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:_TryCreateOrder` | `527-559` | `CanCreate`, `CanCreateOrder`, `CreateOrder`, `Generate`, `GetId`, `GetModel`, `GetStartedContiorders`, `GetType` | `EEventType.MainOrderCreated`, `Order`, `OrderType`, `m_idGenerator`, `m_tutorialOrderModel` |
| `MainOrderModel` | `MainOrderModel:FinishOrder` | `560-604` | `FinishOrder`, `GetChainId`, `GetDiffScore`, `GetInnerType`, `GetItemCodeConfigMap`, `GetRandomOrderConfigBySlot`, `GetRequirements`, `GetSlot` | `LuckyTriggerChance`, `m_canTriggerLucky`, `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:GetRepeatWeightDecrease` | `605-608` | `GetRepeatWeightDecrease` | `m_mapRepeatWeightDecreaseInfo` |
| `MainOrderModel` | `MainOrderModel:ReduceRepeatWeightDecreaseByChainId` | `609-621` | `ReduceRepeatWeightDecreaseByChainId`, `SaveRepeatWeightDecreaseInfo` | `m_mapRepeatWeightDecreaseInfo` |
| `MainOrderModel` | `MainOrderModel:ResetRepeatWeightDecreaseByChainId` | `622-628` | `ResetRepeatWeightDecreaseByChainId`, `SaveRepeatWeightDecreaseInfo` | `m_mapRepeatWeightDecreaseInfo` |
| `MainOrderModel` | `MainOrderModel:UpdateRepeatWeightDecrease` | `629-639` | `ReduceRepeatWeightDecreaseByChainId`, `ResetRepeatWeightDecreaseByChainId`, `SaveRepeatWeightDecreaseInfo`, `UpdateRepeatWeightDecrease` | - |
| `MainOrderModel` | `MainOrderModel:GetTotalDiffScore` | `640-643` | `GetTotalDiffScore`, `GetValue` | `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:RemoveOrder` | `644-656` | `Call`, `RemoveOrder`, `SetFinished`, `UpdateOrderState`, `_DBRemoveCDTimer`, `_RemoveOrder` | `BoardEventType.RemoverOrderImmediate`, `Order`, `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:_RemoveErrorOrderData` | `657-668` | `Call`, `UpdateOrderState`, `_DBRemoveCDTimer`, `_RemoveErrorOrderData`, `_RemoveOrder` | `BoardEventType.RemoverOrderImmediate`, `Order`, `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:GetAvatarId` | `669-719` | `CanAcquireToken`, `GetAvatarId`, `GetCurrentLevel`, `GetModel`, `GetValue`, `Set` | `m_avatarConfig`, `m_dbMetaTable`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:UpdateRequirements` | `720-744` | `UpdateOrderState`, `UpdateRequirements`, `_DBUpdateOrder` | `EEventType.OrderStatusChanged`, `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:_OnEnterMainScene` | `745-749` | `_OnEnterMainScene`, `_UpdateBakeOutOrderStatus` | `m_bResourceChecked` |
| `MainOrderModel` | `MainOrderModel:_UpdateBakeOutOrderStatus` | `750-768` | `CanAcquireToken`, `GetAvatarId`, `GetModel`, `GetReadOnlyValues`, `_DBUpdateOrder`, `_UpdateBakeOutOrderStatus`, `_UpdateMainOrderStatus` | `m_avatarConfig`, `m_bResourceChecked`, `m_dbTable`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:_UpdateMainOrderStatus` | `769-772` | `_UpdateMainOrderStatus` | `EEventType.OrderStatusChanged` |
| `MainOrderModel` | `MainOrderModel:_OnBuffPropertyChanged` | `773-776` | `_OnBuffPropertyChanged`, `_UpdateMainOrderStatus` | - |
| `MainOrderModel` | `MainOrderModel:GetCodeCountMap` | `777-780` | `GetCodeCountMap` | `m_boardModel` |
| `MainOrderModel` | `MainOrderModel:CheckItemCodeProgressUnlock` | `781-792` | `CheckItemCodeProgressUnlock`, `GetChain`, `GetChainId`, `GetChainLevel`, `IsUnlocked` | `m_itemCodeConfigMap` |
| `MainOrderModel` | `MainOrderModel:CanCreateSpecialOrder` | `793-799` | `CanCreateSpecialOrder` | `m_orders` |
| `MainOrderModel` | `MainOrderModel:CreateSpecialOrder` | `800-809` | `CreateSpecialOrder`, `UpdateOrderState`, `_DBAddOrder`, `_LogOrderAction` | `EEventType.MainOrderCreated`, `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:GetSpecialOrderConfigWithOffset` | `810-813` | `GetSpecialOrderConfigWithOffset` | - |
| `MainOrderModel` | `MainOrderModel:IsSpecialOrderFinished` | `814-821` | `GetId`, `IsSpecialOrderFinished` | `m_orders` |
| `MainOrderModel` | `MainOrderModel:_TryCreateBranchOrders` | `822-832` | `UpdateOrderState`, `_DBAddOrder`, `_LogOrderAction`, `_TryCreateBranchOrders` | `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:IsBranchOrderFinished` | `833-836` | `GetValue`, `IsBranchOrderFinished`, `_GetBranchOrderFinishMetaKey` | `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderFinalRewardSlotName` | `837-844` | `GetBranchOrderFinalRewardSlotName` | `m_branchOrderConfig` |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderRequirement` | `845-852` | `GetBranchOrderRequirement` | `m_branchOrderConfig` |
| `MainOrderModel` | `MainOrderModel:_GetBranchOrderFinishMetaKey` | `853-856` | `_GetBranchOrderFinishMetaKey` | - |
| `MainOrderModel` | `MainOrderModel:_SetBranchOrderFinished` | `857-861` | `GetSlot`, `Set`, `_GetBranchOrderFinishMetaKey`, `_SetBranchOrderFinished` | `m_branchOrderConfig`, `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:_AddGiftRewardInfo` | `862-876` | `GetCoinToGiftNum`, `GetGiftConfig`, `GetInnerType`, `GetPrice`, `IsOpen`, `IsRandomOrderOpen`, `SetGiftRewardInfo`, `_AddGiftRewardInfo` | - |
| `MainOrderModel` | `MainOrderModel:ForceRefreshOrderForReturnUser` | `877-1183` | `ForceRefreshOrderForReturnUser`, `GetChainLevel`, `GetCodeCountMap`, `GetItemCodeConfigMap`, `GetItemsOnBoard`, `GetOrders`, `GetRequirements`, `ShowTestOrderLog` | `m_boardModel`, `m_orders` |
| `MainOrderModel` | `MainOrderModel:GetFixedOrderConfig` | `1184-1187` | `GetFixedOrderConfig` | `m_fixedOrderConfig` |
| `MainOrderModel` | `MainOrderModel:GetRandomOrderConfig` | `1188-1194` | `GetRandomOrderConfig`, `IsInReturnRewardTime`, `IsOpen` | `m_randomOrderConfig`, `m_randomOrderRecallConfig` |
| `MainOrderModel` | `MainOrderModel:GetRandomOrderConfigBySlot` | `1195-1206` | `GetModel`, `GetRandomOrderConfig`, `GetRandomOrderConfigBySlot`, `IsChestCustomerOrder`, `IsInReturnRewardTime`, `IsOpen` | `m_chestRandomOrderConfig`, `m_chestRandomOrderRecallConfig` |
| `MainOrderModel` | `MainOrderModel:GetChestRandomOrderConfig` | `1207-1213` | `GetChestRandomOrderConfig`, `IsInReturnRewardTime`, `IsOpen` | `m_chestRandomOrderConfig`, `m_chestRandomOrderRecallConfig` |
| `MainOrderModel` | `MainOrderModel:GetSpecialOrderConfig` | `1214-1217` | `GetSpecialOrderConfig` | `m_specialOrderConfig` |
| `MainOrderModel` | `MainOrderModel:GetBranchOrderConfig` | `1218-1221` | `GetBranchOrderConfig` | `m_branchOrderConfig` |
| `MainOrderModel` | `MainOrderModel:GetLuckyOrderConfig` | `1222-1225` | `GetLuckyOrderConfig` | `m_luckyOrderConfig` |
| `MainOrderModel` | `MainOrderModel:GetItemCodeConfigMap` | `1226-1229` | `GetItemCodeConfigMap` | `m_itemCodeConfigMap` |
| `MainOrderModel` | `MainOrderModel:GetItemNumberWeightConfig` | `1230-1233` | `GetItemNumberWeightConfig` | `m_itemNumberWeightConfig` |
| `MainOrderModel` | `MainOrderModel:GetAvatarConfig` | `1234-1237` | `GetAvatarConfig` | `m_avatarConfig` |
| `MainOrderModel` | `MainOrderModel:GetNormalAvatarConfig` | `1238-1241` | `GetNormalAvatarConfig` | `m_normalAvatarConfigs` |
| `MainOrderModel` | `MainOrderModel:GetMetaData` | `1242-1245` | `GetMetaData` | `m_dbMetaTable` |
| `MainOrderModel` | `MainOrderModel:GetLastFinishOrder` | `1246-1249` | `GetLastFinishOrder` | `m_lastFinishOrder` |
| `MainOrderModel` | `MainOrderModel:_LogOrder` | `1250-1337` | `CanSupportAlbumBuff`, `GetBuffRewards`, `GetChestRandomOrderConfig`, `GetCookingBIConfig`, `GetDiffRange`, `GetDiffScore`, `GetGenerateItemByOrder`, `GetId` | - |
| `MainOrderModel` | `MainOrderModel:_GetLogOrderActionOrderType` | `1338-1351` | `GetInnerType`, `_GetLogOrderActionOrderType` | - |
| `MainOrderModel` | `MainOrderModel:CanTriggerLucky` | `1352-1355` | `CanTriggerLucky` | `m_canTriggerLucky` |
| `MainOrderModel` | `MainOrderModel:CloseTriggerLucky` | `1356-1359` | `CloseTriggerLucky` | `m_canTriggerLucky` |
| `MainOrderModel` | `MainOrderModel:GetTutorialOrderModel` | `1360-1362` | `GetTutorialOrderModel` | `m_tutorialOrderModel` |
| `SlotOrderModel` | `SlotOrderModel:Init` | `4-8` | - | `m_slotCount` |
| `SlotOrderModel` | `SlotOrderModel:OnSyncDataFinished` | `9-12` | `OnSyncDataFinished`, `_DBGetOrders` | `m_orders` |
| `SlotOrderModel` | `SlotOrderModel:LateInit` | `13-16` | `LateInit`, `_TryFillOrders` | - |
| `SlotOrderModel` | `SlotOrderModel:_DBGetOrders` | `17-20` | `_DBGetOrders` | - |
| `SlotOrderModel` | `SlotOrderModel:_DBAddOrder` | `21-24` | `_DBAddOrder` | - |
| `SlotOrderModel` | `SlotOrderModel:_DBRemoveOrder` | `25-28` | `_DBRemoveOrder` | - |
| `SlotOrderModel` | `SlotOrderModel:_TryFillOrders` | `29-60` | `GetState`, `UpdateOrderState`, `_DBAddOrder`, `_LogOrderAction`, `_RemoveOrder`, `_TryCreateOrder`, `_TryFillOrders` | `OrderState`, `m_boardModel`, `m_orders`, `m_slotCount` |
| `SlotOrderModel` | `SlotOrderModel:_TryCreateOrder` | `61-64` | `_TryCreateOrder` | - |
| `SlotOrderModel` | `SlotOrderModel:FinishOrder` | `65-74` | `ContainsOrder`, `FinishOrder`, `SetFinished`, `_LogOrderAction`, `_TryFillOrders` | `EEventType.OrderFinished` |
| `BaseOrderCell` | `BaseOrderCell:GetDisplayRewards` | `4-7` | `GetDisplayRewards`, `GetRewards` | `m_order` |
| `BaseOrderCell` | `BaseOrderCell:GetDisplayTray` | `8-11` | `GetDisplayTray` | - |
| `BaseOrderCell` | `BaseOrderCell:GetTestInfoStr` | `12-14` | `GetTestInfoStr` | - |
| `BaseOrderCell` | `BaseOrderCell:GetDeliverAudioEffectName` | `15-18` | `GetDeliverAudioEffectName` | - |
| `BaseOrderCell` | `BaseOrderCell:OnRewardCellInitFinish` | `19-21` | `OnRewardCellInitFinish` | - |
| `BaseOrderCell` | `BaseOrderCell:OnGoButtonClicked` | `22-34` | `CanDeliver`, `FinishOrder`, `GetBoardView`, `GetCodeCountMap`, `OnGoButtonClicked`, `OpenView`, `PlayEffect` | `m_bGoButtonEnabled`, `m_order`, `m_orderArea` |
| `BaseOrderCell` | `BaseOrderCell:OnAvatarClick` | `35-37` | `OnAvatarClick` | - |
| `BaseOrderCell` | `BaseOrderCell:GetCellType` | `38-40` | `GetCellType` | - |
| `BaseOrderCell` | `BaseOrderCell:Init` | `41-59` | `GetInnerType`, `GetState`, `PlayEnterAnimation`, `_OnShowItemTestInfoChanged`, `_UpdateAvatar`, `_UpdateRequirementIcons`, `_UpdateReward`, `_UpdateServeButtonPosition` | `OrderState`, `m_firstShowDeliver`, `m_inited`, `m_order`, `m_orderArea`, `m_showDeliver` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatar` | `60-78` | `GetAvatarName`, `GetConfig`, `GetLuaTable`, `LoadPrefab`, `OnOrderStateChanged`, `_UpdateAvatar` | `m_avatar`, `m_avatarName`, `m_avatarTransform`, `m_bAvatarUpdateStateAfterLoad`, `m_order` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatarByName` | `79-79` | `_UpdateAvatarByName` | - |
| `BaseOrderCell` | `self.m_order.GetAvatarName` | `80-101` | `GetConfig`, `GetLuaTable`, `LoadPrefab`, `OnOrderStateChanged` | `m_avatar`, `m_avatarName`, `m_avatarTransform`, `m_bAvatarUpdateStateAfterLoad`, `m_order` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateAvatarByName` | `102-102` | `_UpdateAvatarByName` | - |
| `BaseOrderCell` | `self.m_order.GetAvatarName` | `103-124` | `GetConfig`, `GetLuaTable`, `LoadPrefab`, `OnOrderStateChanged` | `m_avatar`, `m_avatarName`, `m_avatarTransform`, `m_bAvatarUpdateStateAfterLoad`, `m_order` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateRequirementIcons` | `125-144` | `GetLuaTable`, `GetRequirements`, `SetActive`, `_UpdateRequirementIcons` | `m_iconArea`, `m_iconPrefab`, `m_icons`, `m_order` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateReward` | `145-172` | `GetDisplayRewards`, `GetLuaTable`, `OnRewardCellInitFinish`, `SetActive`, `_SplitRewards`, `_UpdateActivitySpecialRewardView`, `_UpdateReward` | `m_rewardCells`, `m_rewardPrefab`, `m_rewards` |
| `BaseOrderCell` | `BaseOrderCell:_SplitRewards` | `173-213` | `GetActivityModelByType`, `GetModel`, `GetStartedAlbumActivity`, `GetStartedAvenueActivity`, `GetStartedComboActivity`, `GetStartedExpedActivity`, `GetStartedRingActivity`, `GetStartedRoadActivity` | - |
| `BaseOrderCell` | `BaseOrderCell:_UpdateActivitySpecialRewardView` | `214-232` | `IsNull`, `SetActive`, `_AddSpecialRewards`, `_UpdateActivitySpecialRewardView` | `m_specialRewardNodeRectTrans`, `m_specialRewardObjects` |
| `BaseOrderCell` | `BaseOrderCell:_AddSpecialRewards` | `233-235` | `_AddSpecialRewards` | - |
| `BaseOrderCell` | `BaseOrderCell:_AddOneSpecialReward` | `236-272` | `GetConfig`, `GetLuaTable`, `LoadPrefab`, `SetActive`, `_AddOneSpecialReward` | `m_specialRewardNodeRectTrans`, `m_specialRewardObjectPosInfo`, `m_specialRewardObjects` |
| `BaseOrderCell` | `BaseOrderCell:GetSpecialRewardByKey` | `273-279` | `GetSpecialRewardByKey` | `m_specialRewardObjects` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateServeButtonPosition` | `280-304` | `GetMaxPossibleRewardNumber`, `_UpdateServeButtonPosition` | `m_button`, `m_order`, `m_rewards` |
| `BaseOrderCell` | `BaseOrderCell:_UpdateTray` | `305-309` | `GetDisplayTray`, `_UpdateTray` | `m_TrayImg` |
| `BaseOrderCell` | `BaseOrderCell:_OnShowItemTestInfoChanged` | `310-420` | `AddComponent`, `Find`, `GetBoardView`, `GetComponent`, `GetDiffRange`, `GetDiffScore`, `GetHud`, `GetHudButton` | `m_arrScore2RewardConfig`, `m_bUpdateTestInfoDisplay`, `m_order`, `m_orderArea`, `m_orderGenerateRights`, `m_testText` |
| `BaseOrderCell` | `BaseOrderCell:OnTestAddItemClicked` | `421-440` | `AddItemOnBoard`, `CacheItems`, `CanDeliver`, `FindEmptyPositionInValidOrder`, `GetBoardView`, `GetCodeCountMap`, `GetRequirements`, `OnTestAddItemClicked` | `m_order`, `m_orderArea` |
| `BaseOrderCell` | `BaseOrderCell:_OnTestFinishOrder` | `441-475` | `AddItemOnBoard`, `CanDeliver`, `Find`, `FindEmptyPositionInValidOrder`, `GetBoardView`, `GetCodeCountMap`, `GetRequirements`, `GetState` | `OrderState`, `m_order`, `m_orderArea`, `m_testFinishingOrder` |
| `BaseOrderCell` | `BaseOrderCell:OnDestroy` | `476-479` | `OnDestroy` | - |
| `BaseOrderCell` | `BaseOrderCell:GetOrder` | `480-483` | `GetOrder` | `m_order` |
| `BaseOrderCell` | `BaseOrderCell:GetIconArea` | `484-487` | `GetIconArea` | `m_iconArea` |
| `BaseOrderCell` | `BaseOrderCell:GetIcon` | `488-491` | `GetIcon` | `m_icons` |
| `BaseOrderCell` | `BaseOrderCell:GetGoButton` | `492-495` | `GetGoButton` | `m_button` |
| `BaseOrderCell` | `BaseOrderCell:SetOrderIconClickEnabled` | `496-501` | `SetClickEnabled`, `SetOrderIconClickEnabled` | `m_icons` |
| `BaseOrderCell` | `BaseOrderCell:SetGoButtonEnabled` | `502-505` | `SetGoButtonEnabled` | `m_bGoButtonEnabled` |
| `BaseOrderCell` | `BaseOrderCell:CheckHaveFinshOrderInActivity` | `506-527` | `CheckHaveFinshOrderInActivity`, `GetCurDoingBuff`, `GetModel`, `GetOrder`, `GetState`, `IsChestCustomerOrder`, `IsPlayFinishRewardAnimation` | `OrderModelType`, `OrderState` |
| `BaseOrderCell` | `BaseOrderCell:OnOrderStateChanged` | `528-553` | `CheckHaveFinshOrderInActivity`, `GetDeliverAudioEffectName`, `GetGameMode`, `GetState`, `OnOrderStateChanged`, `PlayEffect`, `ScrollToOrder`, `SetActive` | `OrderState`, `m_avatar`, `m_button`, `m_firstShowDeliver`, `m_icons`, `m_order`, `m_playingAnimation`, `m_radianceGo`, `m_showDeliver`, `m_starEffectGo` |
| `BaseOrderCell` | `BaseOrderCell:ScrollToOrder` | `554-557` | `ScrollToOrder`, `ScrollToRectTransformMiddle` | `m_orderArea` |
| `BaseOrderCell` | `BaseOrderCell:ScrollToOrderIfNotInView` | `558-563` | `OrderIsInView`, `ScrollToOrderIfNotInView`, `ScrollToRectTransformMiddle` | `OrderIsInView`, `m_orderArea` |
| `BaseOrderCell` | `BaseOrderCell:PlayEnterAnimation` | `564-583` | `Append`, `GetState`, `InsertCallback`, `OnOrderStateChanged`, `PlayEnterAnimation`, `PlayTrayAnimation`, `SetTransparent` | `OrderState`, `m_avatar`, `m_bAvatarUpdateStateAfterLoad`, `m_order`, `m_playingAnimation` |
| `BaseOrderCell` | `BaseOrderCell:PlayTrayAnimation` | `584-592` | `Append`, `DOScale`, `PlayTrayAnimation`, `SetActive` | `m_tray` |
| `BaseOrderCell` | `BaseOrderCell:PlayTrayAnimationHide` | `593-603` | `Append`, `DOScale`, `OnComplete`, `PlayTrayAnimationHide`, `SetActive` | `m_tray` |
| `BaseOrderCell` | `BaseOrderCell:PlayEnterBoardAnimation` | `604-642` | `ClearTracks`, `DOFade`, `GetComponent`, `GetState`, `Insert`, `InsertCallback`, `OnOrderStateChanged`, `PlayEnterAnimation` | `OrderState`, `m_avatar`, `m_bAvatarUpdateStateAfterLoad`, `m_button`, `m_order`, `m_playingAnimation`, `m_radianceGo`, `m_rewards`, `m_starEffectGo`, `m_tray` |
| `BaseOrderCell` | `BaseOrderCell:PlayCoinEffect` | `643-658` | `GetLuaTable`, `PlayCoinEffect`, `PlayEffect`, `SetActive` | `m_SpecialRewardsRectTrans`, `m_coinEffectPrefab`, `m_rewards`, `m_specialRewardObjects`, `m_tray` |
| `BaseOrderCell` | `BaseOrderCell:PlayLeaveAnimation` | `659-664` | `PlayLeaveAnimation` | `m_avatar` |
| `BaseOrderCell` | `BaseOrderCell:SetHandEffectActive` | `665-668` | `SetActive`, `SetHandEffectActive` | `m_handEffectGo` |
| `BaseOrderCell` | `BaseOrderCell:HideTrayTrans` | `669-671` | `HideTrayTrans` | `m_tray` |

## 使用口径

- `source-confirmed` 表示函数来自已恢复源码。
- `mentioned` 只表示文档中出现了函数名，不证明触发链、分支、状态、副作用和配表已经完整解释。
- `unmentioned` 必须在阶段三出口前归属到操作链、后台入口、工具代码、遗留逻辑或明确的未追踪项。
