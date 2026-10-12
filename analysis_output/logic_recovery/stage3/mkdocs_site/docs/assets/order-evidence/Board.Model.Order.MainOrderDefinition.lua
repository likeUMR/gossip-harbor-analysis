MainOrderDefinition = {}
MainOrderDefinition.FirstOrderAvatarId = 6
MainOrderSlotDefinition = {
  Slot1 = 1,
  Slot2 = 2,
  Slot3 = 3,
  Slot4 = 4,
  Slot5 = 5,
  SpecialSlot = 6,
  BranchSlot = 7,
  Slot8 = 8,
  MainDecorSlot = 9,
  CharacterIntimacySlot = 10,
  TutorialOrder = 11,
  TimedOrderSlot = 13,
  BaselineOrderSlot = 15,
  LuckyOrderSlot = 17,
  ContiorderSlot = 18,
  ExtraCustomerSlot = 19,
  SlotCount = 19
}
MainOrderSlotPriority = {
  tostring(MainOrderSlotDefinition.Slot1),
  tostring(MainOrderSlotDefinition.Slot2),
  tostring(MainOrderSlotDefinition.TutorialOrder),
  tostring(MainOrderSlotDefinition.Slot3),
  tostring(MainOrderSlotDefinition.Slot8),
  tostring(MainOrderSlotDefinition.Slot4),
  tostring(MainOrderSlotDefinition.Slot5),
  tostring(MainOrderSlotDefinition.CharacterIntimacySlot),
  tostring(MainOrderSlotDefinition.BaselineOrderSlot),
  tostring(MainOrderSlotDefinition.ExtraCustomerSlot)
}
MainOrderType = {
  Fixed = 0,
  Random1 = 1,
  Random2 = 2,
  Random3 = 3,
  Random4 = 4,
  Special = 5,
  Random5 = 6,
  Branch = 7,
  Random5New = 9,
  TutorialOrder = 11,
  CharacterIntimacyRandom = 12,
  ReturnUserFree = 13,
  Lucky = 14,
  TimedCustomer = 15,
  TimedOrder = 16,
  BaselineOrder = 18,
  Contiorder = 20,
  ExtraCustomer = 21
}
CanChangeToMainDecorTimeLimitOrder = {
  [MainOrderType.Fixed] = true,
  [MainOrderType.Random1] = true,
  [MainOrderType.Random2] = true,
  [MainOrderType.Random3] = true,
  [MainOrderType.Random4] = true,
  [MainOrderType.Random5] = true,
  [MainOrderType.Random5New] = true,
  [MainOrderType.ReturnUserFree] = true,
  [MainOrderType.CharacterIntimacyRandom] = true,
  [MainOrderType.Lucky] = true,
  [MainOrderType.TimedOrder] = true,
  [MainOrderType.BaselineOrder] = true
}
NormalOrderSlot = {
  [MainOrderSlotDefinition.Slot1] = true,
  [MainOrderSlotDefinition.Slot2] = true,
  [MainOrderSlotDefinition.Slot3] = true,
  [MainOrderSlotDefinition.Slot4] = true,
  [MainOrderSlotDefinition.Slot5] = true,
  [MainOrderSlotDefinition.Slot8] = true
}
MainOrderDBColumnRandomStartTimer = {
  [MainOrderSlotDefinition.Slot1] = "Random1StartTimer",
  [MainOrderSlotDefinition.Slot2] = "Random1StartTimer",
  [MainOrderSlotDefinition.Slot3] = "Random2StartTimer",
  [MainOrderSlotDefinition.Slot4] = "Random3StartTimer",
  [MainOrderSlotDefinition.Slot5] = "Random4StartTimer",
  [MainOrderSlotDefinition.Slot8] = "Random5StartTimer",
  [MainOrderSlotDefinition.CharacterIntimacySlot] = "RandomIntimacyStartTimer"
}
MainOrderDBRandomPoint = {
  [MainOrderType.Random1] = "Random1OrderPoints",
  [MainOrderType.Random2] = "Random2OrderPoints",
  [MainOrderType.Random3] = "Random3OrderPoints",
  [MainOrderType.Random4] = "Random4OrderPoints",
  [MainOrderType.Random5New] = "Random5NewOrderPoints",
  [MainOrderType.CharacterIntimacyRandom] = "CharacterIntimacyRandomOrderPoints"
}
MainOrderSlot3IgnoreCheckInnerType = {
  [MainOrderType.Special] = true,
  [MainOrderType.ExtraCustomer] = true
}
MainOrderTypeSlotMap = {
  [MainOrderType.Random1] = {
    MainOrderSlotDefinition.Slot1,
    MainOrderSlotDefinition.Slot2
  },
  [MainOrderType.Random2] = {
    MainOrderSlotDefinition.Slot3
  },
  [MainOrderType.Random3] = {
    MainOrderSlotDefinition.Slot4
  },
  [MainOrderType.Random4] = {
    MainOrderSlotDefinition.Slot5
  },
  [MainOrderType.Random5New] = {
    MainOrderSlotDefinition.Slot8
  }
}
MainOrderCellType = {
  ChestCustomer = "ChestCustomer"
}
