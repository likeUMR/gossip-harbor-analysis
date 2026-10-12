BaseOrderAnimation = {}
BaseOrderAnimation.__index = BaseOrderAnimation

function BaseOrderAnimation:Init(name)
  self.m_name = name
  self.m_state = nil
  if not self.m_bAniInit then
    self.m_animation:Initialize(false)
    self.m_bAniInit = true
  end
end

function BaseOrderAnimation:SetTransparent(transparent)
  if transparent then
    UIUtil.SetAlpha(self.m_animation, 0)
  else
    UIUtil.SetAlpha(self.m_animation, 1)
  end
end

function BaseOrderAnimation:ClearTracks()
  self.m_animation.AnimationState:ClearTracks()
  self.m_animation.Skeleton:SetToSetupPose()
end

function BaseOrderAnimation:SetAnimation(shortName, backStates)
  if not self.m_bAniInit then
    self.m_animation:Initialize(false)
    self.m_bAniInit = true
  end
  if self.m_state == nil then
    self:_SetAnimation(shortName, false)
    self:_AddRepeatAnimation(shortName)
    return
  end
  for _, state in ipairs(backStates) do
    if self.m_state == state then
      self:_SetAnimation(shortName, false)
      self:_AddRepeatAnimation(shortName)
      return
    end
  end
  self:_SetAnimation(shortName, true)
end

function BaseOrderAnimation:_SetAnimation(shortName, isRepeat)
  UIUtil.SetAlpha(self.m_animation, 1)
  local animationName = self:_GetAnimationName(shortName, isRepeat)
  self.m_animation.AnimationState:SetAnimation(0, animationName, isRepeat)
end

function BaseOrderAnimation:_AddRepeatAnimation(shortName)
  local animationName = self:_GetAnimationName(shortName, true)
  self.m_animation.AnimationState:AddAnimation(0, animationName, true, 0)
end

function BaseOrderAnimation:_AddNoRepeatAnimation(shortName)
  local animationName = self:_GetAnimationName(shortName, false)
  self.m_animation.AnimationState:AddAnimation(0, animationName, false, 0)
end

function BaseOrderAnimation:_GetAnimationName(shortName, isRepeat)
  local postfix = isRepeat and "_repeat" or ""
  return self.m_name .. "_" .. shortName .. postfix
end
