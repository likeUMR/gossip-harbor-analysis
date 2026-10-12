ChestCustomOrderRewardCategoryHandler = setmetatable({}, BaseRewardCategoryHandler)
ChestCustomOrderRewardCategoryHandler.__index = ChestCustomOrderRewardCategoryHandler

function ChestCustomOrderRewardCategoryHandler.Create()
  local handler = setmetatable({}, ChestCustomOrderRewardCategoryHandler)
  return handler
end

function ChestCustomOrderRewardCategoryHandler:LogicHandle(rewardDatas)
  local chestCustomModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  for _, reward in ipairs(rewardDatas) do
    chestCustomModel:AcquireChestCustomOrderReward(reward)
  end
end
