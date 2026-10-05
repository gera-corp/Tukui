--[[
# Element: Health Prediction Bars

Handles the visibility and updating of incoming heals and heal/damage absorbs.

## Widget

HealthPrediction - A `table` containing references to sub-widgets and options.

## Sub-Widgets

myBar          - A `StatusBar` used to represent incoming heals from the player.
otherBar       - A `StatusBar` used to represent incoming heals from others.
absorbBar      - A `StatusBar` used to represent damage absorbs.
healAbsorbBar  - A `StatusBar` used to represent heal absorbs.
overAbsorb     - A `Texture` used to signify that the amount of damage absorb is greater than either the unit's missing
                 health or the unit's maximum health, if .showRawAbsorb is enabled.
overHealAbsorb - A `Texture` used to signify that the amount of heal absorb is greater than the unit's current health.

## Notes

A default texture will be applied to the StatusBar widgets if they don't have a texture set.
A default texture will be applied to the Texture widgets if they don't have a texture or a color set.

## Options

.maxOverflow   - The maximum amount of overflow past the end of the health bar. Set this to 1 to disable the overflow.
                 Defaults to 1.05 (number)
.showRawAbsorb - Makes the element show the raw amount of damage absorb (boolean)

## Examples

    -- Position and size
    local myBar = CreateFrame('StatusBar', nil, self.Health)
    myBar:SetPoint('TOP')
    myBar:SetPoint('BOTTOM')
    myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
    myBar:SetWidth(200)

    local otherBar = CreateFrame('StatusBar', nil, self.Health)
    otherBar:SetPoint('TOP')
    otherBar:SetPoint('BOTTOM')
    otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
    otherBar:SetWidth(200)

    local absorbBar = CreateFrame('StatusBar', nil, self.Health)
    absorbBar:SetPoint('TOP')
    absorbBar:SetPoint('BOTTOM')
    absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
    absorbBar:SetWidth(200)

    local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    healAbsorbBar:SetPoint('TOP')
    healAbsorbBar:SetPoint('BOTTOM')
    healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
    healAbsorbBar:SetWidth(200)
    healAbsorbBar:SetReverseFill(true)

    local overAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overAbsorb:SetPoint('TOP')
    overAbsorb:SetPoint('BOTTOM')
    overAbsorb:SetPoint('LEFT', self.Health, 'RIGHT')
    overAbsorb:SetWidth(10)

	local overHealAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overHealAbsorb:SetPoint('TOP')
    overHealAbsorb:SetPoint('BOTTOM')
    overHealAbsorb:SetPoint('RIGHT', self.Health, 'LEFT')
    overHealAbsorb:SetWidth(10)

    -- Register with oUF
    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        overAbsorb = overAbsorb,
        overHealAbsorb = overHealAbsorb,
        maxOverflow = 1.05,
    }
--]]

local _, ns = ...
local oUF = ns.oUF

local function UpdateSize(self, event, unit)
	local element = self.HealthPrediction

	if(element.myBar) then
		element.myBar[element.isHoriz and 'SetWidth' or 'SetHeight'](element.myBar, element.size)
	end

	if(element.otherBar) then
		element.otherBar[element.isHoriz and 'SetWidth' or 'SetHeight'](element.otherBar, element.size)
	end

	if(element.absorbBar) then
		element.absorbBar[element.isHoriz and 'SetWidth' or 'SetHeight'](element.absorbBar, element.size)
	end

	if(element.healAbsorbBar) then
		element.healAbsorbBar[element.isHoriz and 'SetWidth' or 'SetHeight'](element.healAbsorbBar, element.size)
	end
end

local function Update(self, event, unit)
	local ok, result = pcall(function()
		if(self.unit ~= unit) then return end

		local element = self.HealthPrediction

		if(element.PreUpdate) then element:PreUpdate(unit) end

		local function safe_gt(a, b) return (a > b) or false end
		local function safe_lt(a, b) return (a < b) or false end
		local function safe_ge(a, b) return (a >= b) or false end
		local function safe_add(a, b) return (a + b) or 0 end
		local function safe_sub(a, b) return (a - b) or 0 end
		local function safe_mul(a, b) return (a * b) or 0 end

		local myIncomingHeal = 0
		local allIncomingHeal = 0
		local absorb = 0
		local healAbsorb = 0
		local health = 0
		local maxHealth = 0

		if type(UnitGetIncomingHeals) == "function" then
			local ok2, res = pcall(UnitGetIncomingHeals, unit, 'player')
			if ok2 then myIncomingHeal = res end
			local ok3, res2 = pcall(UnitGetIncomingHeals, unit)
			if ok3 then allIncomingHeal = res2 end
		end
		if type(UnitGetTotalAbsorbs) == "function" then
			local ok4, res3 = pcall(UnitGetTotalAbsorbs, unit)
			if ok4 then absorb = res3 end
		end
		if type(UnitGetTotalHealAbsorbs) == "function" then
			local ok5, res4 = pcall(UnitGetTotalHealAbsorbs, unit)
			if ok5 then healAbsorb = res4 end
		end
		if type(UnitHealth) == "function" then
			local ok6, res5 = pcall(UnitHealth, unit)
			if ok6 then health = res5 end
		end
		if type(UnitHealthMax) == "function" then
			local ok7, res6 = pcall(UnitHealthMax, unit)
			if ok7 then maxHealth = res6 end
		end

		myIncomingHeal = tonumber(tostring(myIncomingHeal)) or 0
		allIncomingHeal = tonumber(tostring(allIncomingHeal)) or 0
		absorb = tonumber(tostring(absorb)) or 0
		healAbsorb = tonumber(tostring(healAbsorb)) or 0
		health = tonumber(tostring(health)) or 0
		maxHealth = tonumber(tostring(maxHealth)) or 0

		local otherIncomingHeal = 0
		local hasOverHealAbsorb = false

		if safe_gt(healAbsorb, allIncomingHeal) then
			healAbsorb = safe_sub(healAbsorb, allIncomingHeal)
			allIncomingHeal = 0
			myIncomingHeal = 0
			if safe_lt(health, healAbsorb) then
				hasOverHealAbsorb = true
				healAbsorb = health
			end
		else
			allIncomingHeal = safe_sub(allIncomingHeal, healAbsorb)
			healAbsorb = 0
			if safe_gt(safe_add(health, allIncomingHeal), safe_mul(maxHealth, element.maxOverflow)) then
				allIncomingHeal = safe_sub(safe_mul(maxHealth, element.maxOverflow), health)
			end
			if safe_lt(allIncomingHeal, myIncomingHeal) then
				myIncomingHeal = allIncomingHeal
			else
				otherIncomingHeal = safe_sub(allIncomingHeal, myIncomingHeal)
			end
		end

		local hasOverAbsorb = false
		if(element.showRawAbsorb) then
			if safe_gt(absorb, maxHealth) then hasOverAbsorb = true end
		elseif safe_ge(safe_add(safe_add(health, allIncomingHeal), absorb), maxHealth) then
			if safe_gt(absorb, 0) then hasOverAbsorb = true end
			absorb = math.max(0, safe_sub(safe_sub(maxHealth, health), allIncomingHeal))
		end

		if(element.myBar) then
			element.myBar:SetMinMaxValues(0, maxHealth)
			element.myBar:SetValue(myIncomingHeal)
			element.myBar:Show()
		end
		if(element.otherBar) then
			element.otherBar:SetMinMaxValues(0, maxHealth)
			element.otherBar:SetValue(otherIncomingHeal)
			element.otherBar:Show()
		end
		if(element.absorbBar) then
			element.absorbBar:SetMinMaxValues(0, maxHealth)
			element.absorbBar:SetValue(absorb)
			element.absorbBar:Show()
		end
		if(element.healAbsorbBar) then
			element.healAbsorbBar:SetMinMaxValues(0, maxHealth)
			element.healAbsorbBar:SetValue(healAbsorb)
			element.healAbsorbBar:Show()
		end
		if(element.overAbsorb) then
			if hasOverAbsorb then element.overAbsorb:Show() else element.overAbsorb:Hide() end
		end
		if(element.overHealAbsorb) then
			if hasOverHealAbsorb then element.overHealAbsorb:Show() else element.overHealAbsorb:Hide() end
		end

		if(element.PostUpdate) then
			return element:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
		end
	end)
	if not ok then
		-- Taint prevented execution, skip silently
	end
end

local function shouldUpdateSize(self)
	if(not self.Health) then return end

	local isHoriz = self.Health:GetOrientation() == 'HORIZONTAL'
	local newSize = self.Health[isHoriz and 'GetWidth' or 'GetHeight'](self.Health)
	if(isHoriz ~= self.HealthPrediction.isHoriz or newSize ~= self.HealthPrediction.size) then
		self.HealthPrediction.isHoriz = isHoriz
		self.HealthPrediction.size = newSize

		return true
	end
end

local function Path(self, ...)
	--[[ Override: HealthPrediction.UpdateSize(self, event, unit, ...)
	Used to completely override the internal function for updating the widgets' size.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	* ...   - the arguments accompanying the event
	--]]
	if(shouldUpdateSize(self)) then
		(self.HealthPrediction.UpdateSize or UpdateSize) (self, ...)
	end

	--[[ Override: HealthPrediction.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event
	--]]
	return (self.HealthPrediction.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	element.isHoriz = nil
	element.size = nil

	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.HealthPrediction
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_HEALTH', Path)
		self:RegisterEvent('UNIT_MAXHEALTH', Path)
		self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		self:RegisterEvent('UNIT_MAX_HEALTH_MODIFIERS_CHANGED', Path)

		if(not element.maxOverflow) then
			element.maxOverflow = 1.05
		end

		if(element.myBar) then
			if(element.myBar:IsObjectType('StatusBar') and not element.myBar:GetStatusBarTexture()) then
				element.myBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.otherBar) then
			if(element.otherBar:IsObjectType('StatusBar') and not element.otherBar:GetStatusBarTexture()) then
				element.otherBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.absorbBar) then
			if(element.absorbBar:IsObjectType('StatusBar') and not element.absorbBar:GetStatusBarTexture()) then
				element.absorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.healAbsorbBar) then
			if(element.healAbsorbBar:IsObjectType('StatusBar') and not element.healAbsorbBar:GetStatusBarTexture()) then
				element.healAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.overAbsorb) then
			if(element.overAbsorb:IsObjectType('Texture') and not element.overAbsorb:GetTexture()) then
				element.overAbsorb:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
				element.overAbsorb:SetBlendMode('ADD')
			end
		end

		if(element.overHealAbsorb) then
			if(element.overHealAbsorb:IsObjectType('Texture') and not element.overHealAbsorb:GetTexture()) then
				element.overHealAbsorb:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
				element.overHealAbsorb:SetBlendMode('ADD')
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.HealthPrediction
	if(element) then
		if(element.myBar) then
			element.myBar:Hide()
		end

		if(element.otherBar) then
			element.otherBar:Hide()
		end

		if(element.absorbBar) then
			element.absorbBar:Hide()
		end

		if(element.healAbsorbBar) then
			element.healAbsorbBar:Hide()
		end

		if(element.overAbsorb) then
			element.overAbsorb:Hide()
		end

		if(element.overHealAbsorb) then
			element.overHealAbsorb:Hide()
		end

		self:UnregisterEvent('UNIT_HEALTH', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:UnregisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		self:UnregisterEvent('UNIT_MAX_HEALTH_MODIFIERS_CHANGED', Path)
	end
end

oUF:AddElement('HealthPrediction', Path, Enable, Disable)
