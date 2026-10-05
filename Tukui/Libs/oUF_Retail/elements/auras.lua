--[[
# Element: Auras

Handles creation and updating of aura buttons.

## Widget

Auras   - A Frame to hold `Button`s representing both buffs and debuffs.
Buffs   - A Frame to hold `Button`s representing buffs.
Debuffs - A Frame to hold `Button`s representing debuffs.

## Notes

At least one of the above widgets must be present for the element to work.

## Options

.disableMouse             - Disables mouse events (boolean)
.disableCooldown          - Disables the cooldown spiral (boolean)
.size                     - Aura button size. Defaults to 16 (number)
.width                    - Aura button width. Takes priority over `size` (number)
.height                   - Aura button height. Takes priority over `size` (number)
.onlyShowPlayer           - Shows only auras created by player/vehicle (boolean)
.showStealableBuffs       - Displays the stealable texture on buffs that can be stolen (boolean)
.spacing                  - Spacing between each button. Defaults to 0 (number)
.['spacing-x']            - Horizontal spacing between each button. Takes priority over `spacing` (number)
.['spacing-y']            - Vertical spacing between each button. Takes priority over `spacing` (number)
.['growth-x']             - Horizontal growth direction. Defaults to 'RIGHT' (string)
.['growth-y']             - Vertical growth direction. Defaults to 'UP' (string)
.initialAnchor            - Anchor point for the aura buttons. Defaults to 'BOTTOMLEFT' (string)
.filter                   - Custom filter list for auras to display. Defaults to 'HELPFUL' for buffs and 'HARMFUL' for
                            debuffs (string)
.tooltipAnchor            - Anchor point for the tooltip. Defaults to 'ANCHOR_BOTTOMRIGHT', however, if a frame has
                            anchoring restrictions it will be set to 'ANCHOR_CURSOR' (string)
.reanchorIfVisibleChanged - Reanchors aura buttons when the number of visible auras has changed (boolean)

## Options Auras

.numBuffs     - The maximum number of buffs to display. Defaults to 32 (number)
.numDebuffs   - The maximum number of debuffs to display. Defaults to 40 (number)
.numTotal     - The maximum number of auras to display. Prioritizes buffs over debuffs. Defaults to the sum of
                .numBuffs and .numDebuffs (number)
.gap          - Controls the creation of an invisible button between buffs and debuffs. Defaults to false (boolean)
.buffFilter   - Custom filter list for buffs to display. Takes priority over `filter` (string)
.debuffFilter - Custom filter list for debuffs to display. Takes priority over `filter` (string)

## Options Buffs

.num - Number of buffs to display. Defaults to 32 (number)

## Options Debuffs

.num - Number of debuffs to display. Defaults to 40 (number)

## Attributes

button.caster         - the unit who cast the aura (string)
button.filter         - the filter list used to determine the visibility of the aura (string)
button.isHarmful      - indicates if the button holds a debuff (boolean)
button.auraInstanceID - unique ID for the current aura being tracked by the button (number)

## Examples

    -- Position and size
    local Buffs = CreateFrame('Frame', nil, self)
    Buffs:SetPoint('RIGHT', self, 'LEFT')
    Buffs:SetSize(16 * 2, 16 * 16)

    -- Register with oUF
    self.Buffs = Buffs
--]]

local _, ns = ...
local oUF = ns.oUF

local function UpdateTooltip(self)
	if(GameTooltip:IsForbidden()) then return end

	if(self.isHarmful) then
		GameTooltip:SetUnitDebuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
	else
		GameTooltip:SetUnitBuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
	end
end

local function onEnter(self)
	if(GameTooltip:IsForbidden() or not self:IsVisible()) then return end

	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, self:GetParent().__restricted and 'ANCHOR_CURSOR' or self:GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local function onLeave()
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:Hide()
end

local function CreateButton(element, index)
	local button = CreateFrame('Button', element:GetDebugName() .. 'Button' .. index, element)

	local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
	cd:SetAllPoints()
	button.Cooldown = cd

	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()
	button.Icon = icon

	local countFrame = CreateFrame('Frame', nil, button)
	countFrame:SetAllPoints(button)
	countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

	local count = countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	count:SetPoint('BOTTOMRIGHT', countFrame, 'BOTTOMRIGHT', -1, 0)
	button.Count = count

	local overlay = button:CreateTexture(nil, 'OVERLAY')
	overlay:SetTexture([[Interface\Buttons\UI-Debuff-Overlays]])
	overlay:SetAllPoints()
	overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
	button.Overlay = overlay

	local stealable = button:CreateTexture(nil, 'OVERLAY')
	stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
	stealable:SetPoint('TOPLEFT', -3, 3)
	stealable:SetPoint('BOTTOMRIGHT', 3, -3)
	stealable:SetBlendMode('ADD')
	button.Stealable = stealable

	button.UpdateTooltip = UpdateTooltip
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnLeave', onLeave)

	--[[ Callback: Auras:PostCreateButton(button)
	Called after a new aura button has been created.

	* self   - the widget holding the aura buttons
	* button - the newly created aura button (Button)
	--]]
	if(element.PostCreateButton) then element:PostCreateButton(button) end

	return button
end

local function SetPosition(element, from, to)
	local width = element.width or element.size or 16
	local height = element.height or element.size or 16
	local sizex = width + (element['spacing-x'] or element.spacing or 0)
	local sizey = height + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = (element['growth-x'] == 'LEFT' and -1) or 1
	local growthy = (element['growth-y'] == 'DOWN' and -1) or 1
	local cols = math.floor(element:GetWidth() / sizex + 0.5)

	for i = from, to do
		local button = element[i]
		if(not button) then break end

		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

local function updateAura(element, unit, data, position)
	if(not data.name) then return end

	local button = element[position]
	if(not button) then
		--[[ Override: Auras:CreateButton(position)
		Used to create an aura button at a given position.

		* self     - the widget holding the aura buttons
		* position - the position at which the aura button is to be created (number)

		## Returns

		* button - the button used to represent the aura (Button)
		--]]
		button = (element.CreateButton or CreateButton) (element, position)

		table.insert(element, button)
		element.createdButtons = element.createdButtons + 1
	end

	-- for tooltips
	button.auraInstanceID = data.auraInstanceID
	button.isHarmful = data.isHarmful

	if(button.Cooldown and not element.disableCooldown) then
		if(data.duration > 0) then
			button.Cooldown:SetCooldown(data.expirationTime - data.duration, data.duration, data.timeMod)
			button.Cooldown:Show()
		else
			button.Cooldown:Hide()
		end
	end

	if(button.Overlay) then
		if((data.isHarmful and element.showDebuffType) or (not data.isHarmful and element.showBuffType) or element.showType) then
			local color = element.__owner.colors.debuff[data.dispelName] or element.__owner.colors.debuff.none

			button.Overlay:SetVertexColor(color[1], color[2], color[3])
			button.Overlay:Show()
		else
			button.Overlay:Hide()
		end
	end

	if(button.Stealable) then
		if(not data.isHarmful and data.isStealable and element.showStealableBuffs and not UnitIsUnit('player', unit)) then
			button.Stealable:Show()
		else
			button.Stealable:Hide()
		end
	end

	if(button.Icon) then button.Icon:SetTexture(data.icon) end
	if(button.Count) then button.Count:SetText(data.applications > 1 and data.applications or '') end

	local width = element.width or element.size or 16
	local height = element.height or element.size or 16
	button:SetSize(width, height)
	button:EnableMouse(not element.disableMouse)
	button:Show()

	--[[ Callback: Auras:PostUpdateButton(unit, button, data, position)
	Called after the aura button has been updated.

	* self     - the widget holding the aura buttons
	* button   - the updated aura button (Button)
	* unit     - the unit for which the update has been triggered (string)
	* data     - the [AuraData](https://warcraft.wiki.gg/wiki/Struct_AuraData) object (table)
	* position - the actual position of the aura button (number)
	--]]
	if(element.PostUpdateButton) then
		element:PostUpdateButton(button, unit, data, position)
	end
end

local function FilterAura(element, unit, data)
	if((element.onlyShowPlayer and data.isPlayerAura) or (not element.onlyShowPlayer and data.name)) then
		return true
	end
end

-- see AuraUtil.DefaultAuraCompare
local function SortAuras(a, b)
	if(a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	if(a.canApplyAura ~= b.canApplyAura) then
		return a.canApplyAura
	end

	return a.auraInstanceID < b.auraInstanceID
end

local function processData(element, unit, data)
	if(not data) then return end

	data.isPlayerAura = data.sourceUnit and (UnitIsUnit('player', data.sourceUnit) or UnitIsOwnerOrControllerOfUnit('player', data.sourceUnit))

	--[[ Callback: Auras:PostProcessAuraData(unit, data)
	Called after the aura data has been processed.

	* self - the widget holding the aura buttons
	* unit - the unit for which the update has been triggered (string)
	* data - [AuraData](https://warcraft.wiki.gg/wiki/Struct_AuraData) object (table)

	## Returns

	* data - the processed aura data (table)
	--]]
	if(element.PostProcessAuraData) then
		data = element:PostProcessAuraData(unit, data)
	end

	return data
end

local function UpdateAuras(self, event, unit, updateInfo)
	if(self.unit ~= unit) then return end

	-- Forever (build 70009) marks some units as "secret". Reading their auras
	-- while tainted throws "Auras cannot be accessed when secret". Skip them.
	if(ShouldUnitIdentityBeSecret and ShouldUnitIdentityBeSecret(unit)) then return end

	-- Forever: for secret units UNIT_AURA's updateInfo carries secret values
	-- (isFullUpdate, addedAuras, updatedAuraInstanceIDs). Any boolean-test or
	-- iteration over them throws a taint error and their auras are unreadable,
	-- so skip the whole update rather than touching the secret fields below.
	if(updateInfo and (
		(issecretvalue and issecretvalue(updateInfo.isFullUpdate))
		or (issecrettable and (issecrettable(updateInfo.addedAuras) or issecrettable(updateInfo.updatedAuraInstanceIDs)))
	)) then return end

	local isFullUpdate = not updateInfo or updateInfo.isFullUpdate

	local auras = self.Auras
	if(auras) then
		--[[ Callback: Auras:PreUpdate(unit, isFullUpdate)
		Called before the element has been updated.

		* self         - the widget holding the aura buttons
		* unit         - the unit for which the update has been triggered (string)
		* isFullUpdate - indicates whether the element is performing a full update (boolean)
		--]]
		if(auras.PreUpdate) then auras:PreUpdate(unit, isFullUpdate) end

		local buffsChanged = false
		local numBuffs = auras.numBuffs or 32
		local buffFilter = auras.buffFilter or auras.filter or 'HELPFUL'
		if(type(buffFilter) == 'function') then
			buffFilter = buffFilter(auras, unit)
		end

		local debuffsChanged = false
		local numDebuffs = auras.numDebuffs or 40
		local debuffFilter = auras.debuffFilter or auras.filter or 'HARMFUL'
		if(type(debuffFilter) == 'function') then
			debuffFilter = debuffFilter(auras, unit)
		end

		local numTotal = auras.numTotal or numBuffs + numDebuffs

		if(isFullUpdate) then
			auras.allBuffs = table.wipe(auras.allBuffs or {})
			auras.activeBuffs = table.wipe(auras.activeBuffs or {})
			buffsChanged = true

				local slots = {}
				local ok = pcall(function()
					slots = {C_UnitAuras.GetAuraSlots(unit, buffFilter)}
				end)
				if(not ok) then return end

				for i = 2, #slots do -- #1 return is continuationToken, we don't care about it
					local data = processData(auras, unit, C_UnitAuras.GetAuraDataBySlot(unit, slots[i]))
				auras.allBuffs[data.auraInstanceID] = data

				--[[ Override: Auras:FilterAura(unit, data)
				Defines a custom filter that controls if the aura button should be shown.

				* self - the widget holding the aura buttons
				* unit - the unit for which the update has been triggered (string)
				* data - [AuraData](https://warcraft.wiki.gg/wiki/Struct_AuraData) object (table)

				## Returns

				* show - indicates whether the aura button should be shown (boolean)
				--]]
				if((auras.FilterAura or FilterAura) (auras, unit, data)) then
					auras.activeBuffs[data.auraInstanceID] = true
				end
			end

			auras.allDebuffs = table.wipe(auras.allDebuffs or {})
			auras.activeDebuffs = table.wipe(auras.activeDebuffs or {})
			debuffsChanged = true

				local ok = pcall(function()
					slots = {C_UnitAuras.GetAuraSlots(unit, debuffFilter)}
				end)
				if(not ok) then return end

				for i = 2, #slots do
					local data = processData(auras, unit, C_UnitAuras.GetAuraDataBySlot(unit, slots[i]))
					auras.allDebuffs[data.auraInstanceID] = data

				if((auras.FilterAura or FilterAura) (auras, unit, data)) then
					auras.activeDebuffs[data.auraInstanceID] = true
				end
			end
		else
			if(updateInfo.addedAuras) then
				for _, data in next, updateInfo.addedAuras do
					if(data.isHelpful and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, buffFilter)) then
						data = processData(auras, unit, data)
						auras.allBuffs[data.auraInstanceID] = data

						if((auras.FilterAura or FilterAura) (auras, unit, data)) then
							auras.activeBuffs[data.auraInstanceID] = true
							buffsChanged = true
						end
					elseif(data.isHarmful and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, debuffFilter)) then
						data = processData(auras, unit, data)
						auras.allDebuffs[data.auraInstanceID] = data

						if((auras.FilterAura or FilterAura) (auras, unit, data)) then
							auras.activeDebuffs[data.auraInstanceID] = true
							debuffsChanged = true
						end
					end
				end
			end

			if(updateInfo.updatedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs do
					if(auras.allBuffs[auraInstanceID]) then
						auras.allBuffs[auraInstanceID] = processData(auras, unit, C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID))

						-- only update if it's actually active
						if(auras.activeBuffs[auraInstanceID]) then
							auras.activeBuffs[auraInstanceID] = true
							buffsChanged = true
						end
					elseif(auras.allDebuffs[auraInstanceID]) then
						auras.allDebuffs[auraInstanceID] = processData(auras, unit, C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID))

						if(auras.activeDebuffs[auraInstanceID]) then
							auras.activeDebuffs[auraInstanceID] = true
							debuffsChanged = true
						end
					end
				end
			end

			if(updateInfo.removedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs do
					if(auras.allBuffs[auraInstanceID]) then
						auras.allBuffs[auraInstanceID] = nil

						if(auras.activeBuffs[auraInstanceID]) then
							auras.activeBuffs[auraInstanceID] = nil
							buffsChanged = true
						end
					elseif(auras.allDebuffs[auraInstanceID]) then
						auras.allDebuffs[auraInstanceID] = nil

						if(auras.activeDebuffs[auraInstanceID]) then
							auras.activeDebuffs[auraInstanceID] = nil
							debuffsChanged = true
						end
					end
				end
			end
		end

		--[[ Callback: Auras:PostUpdateInfo(unit, buffsChanged, debuffsChanged)
		Called after the aura update info has been updated and filtered, but before sorting.

		* self           - the widget holding the aura buttons
		* unit           - the unit for which the update has been triggered (string)
		* buffsChanged   - indicates whether the buff info has changed (boolean)
		* debuffsChanged - indicates whether the debuff info has changed (boolean)
		--]]
		if(auras.PostUpdateInfo) then
			auras:PostUpdateInfo(unit, buffsChanged, debuffsChanged)
		end

		if(buffsChanged or debuffsChanged) then
			local numVisible

			if(buffsChanged) then
				-- instead of removing auras one by one, just wipe the tables entirely
				-- and repopulate them, multiple table.remove calls are insanely slow
				auras.sortedBuffs = table.wipe(auras.sortedBuffs or {})

				for auraInstanceID in next, auras.activeBuffs do
					table.insert(auras.sortedBuffs, auras.allBuffs[auraInstanceID])
				end

				--[[ Override: Auras:SortBuffs(a, b)
				Defines a custom sorting algorithm for ordering the auras.

				Defaults to [AuraUtil.DefaultAuraCompare](https://github.com/Gethe/wow-ui-source/search?q=symbol:DefaultAuraCompare).
				--]]
				--[[ Override: Auras:SortAuras(a, b)
				Defines a custom sorting algorithm for ordering the auras.

				Defaults to [AuraUtil.DefaultAuraCompare](https://github.com/Gethe/wow-ui-source/search?q=symbol:DefaultAuraCompare).

				Overridden by the more specific SortBuffs and/or SortDebuffs overrides if they are defined.
				--]]
				table.sort(auras.sortedBuffs, auras.SortBuffs or auras.SortAuras or SortAuras)

				numVisible = math.min(numBuffs, numTotal, #auras.sortedBuffs)

				for i = 1, numVisible do
					updateAura(auras, unit, auras.sortedBuffs[i], i)
				end
			else
				numVisible = math.min(numBuffs, numTotal, #auras.sortedBuffs)
			end

			-- do it before adding the gap because numDebuffs could end up being 0
			if(debuffsChanged) then
				auras.sortedDebuffs = table.wipe(auras.sortedDebuffs or {})

				for auraInstanceID in next, auras.activeDebuffs do
					table.insert(auras.sortedDebuffs, auras.allDebuffs[auraInstanceID])
				end

				--[[ Override: Auras:SortDebuffs(a, b)
				Defines a custom sorting algorithm for ordering the auras.

				Defaults to [AuraUtil.DefaultAuraCompare](https://github.com/Gethe/wow-ui-source/search?q=symbol:DefaultAuraCompare).
				--]]
				table.sort(auras.sortedDebuffs, auras.SortDebuffs or auras.SortAuras or SortAuras)
			end

			numDebuffs = math.min(numDebuffs, numTotal - numVisible, #auras.sortedDebuffs)

			if(auras.gap and numVisible > 0 and numDebuffs > 0) then
				-- adjust the number of visible debuffs if there's an overflow
				if(numVisible + numDebuffs == numTotal) then
					numDebuffs = numDebuffs - 1
				end

				-- double check and skip it if we end up with 0 after the adjustment
				if(numDebuffs > 0) then
					numVisible = numVisible + 1

					local button = auras[numVisible]
					if(not button) then
						button = (auras.CreateButton or CreateButton) (auras, numVisible)
						table.insert(auras, button)
						auras.createdButtons = auras.createdButtons + 1
					end

					-- prevent the button from displaying anything
					if(button.Cooldown) then button.Cooldown:Hide() end
					if(button.Icon) then button.Icon:SetTexture() end
					if(button.Overlay) then button.Overlay:Hide() end
					if(button.Stealable) then button.Stealable:Hide() end
					if(button.Count) then button.Count:SetText() end

					button:EnableMouse(false)
					button:Show()

					--[[ Callback: Auras:PostUpdateGapButton(unit, gapButton, position)
					Called after an invisible aura button has been created. Only used by Auras when the `gap` option is enabled.

					* self      - the widget holding the aura buttons
					* unit      - the unit that has the invisible aura button (string)
					* gapButton - the invisible aura button (Button)
					* position  - the position of the invisible aura button (number)
					--]]
					if(auras.PostUpdateGapButton) then
						auras:PostUpdateGapButton(unit, button, numVisible)
					end
				end
			end

			-- any changes to buffs will affect debuffs, so just redraw them even if nothing changed
			for i = 1, numDebuffs do
				updateAura(auras, unit, auras.sortedDebuffs[i], numVisible + i)
			end

			numVisible = numVisible + numDebuffs
			local visibleChanged = false

			if(numVisible ~= auras.visibleButtons) then
				auras.visibleButtons = numVisible
				visibleChanged = auras.reanchorIfVisibleChanged -- more convenient than auras.reanchorIfVisibleChanged and visibleChanged
			end

			for i = numVisible + 1, #auras do
				auras[i]:Hide()
			end

			if(visibleChanged or auras.createdButtons > auras.anchoredButtons) then
				--[[ Override: Auras:SetPosition(from, to)
				Used to (re-)anchor the aura buttons.
				Called when new aura buttons have been created or the number of visible buttons has changed if the
				`.reanchorIfVisibleChanged` option is enabled.

				* self - the widget that holds the aura buttons
				* from - the offset of the first aura button to be (re-)anchored (number)
				* to   - the offset of the last aura button to be (re-)anchored (number)
				--]]
				if(visibleChanged) then
					-- this is useful for when people might want centred auras, like nameplates
					(auras.SetPosition or SetPosition) (auras, 1, numVisible)
				else
					(auras.SetPosition or SetPosition) (auras, auras.anchoredButtons + 1, auras.createdButtons)
					auras.anchoredButtons = auras.createdButtons
				end
			end

			--[[ Callback: Auras:PostUpdate(unit)
			Called after the element has been updated.

			* self - the widget holding the aura buttons
			* unit - the unit for which the update has been triggered (string)
			--]]
			if(auras.PostUpdate) then auras:PostUpdate(unit) end
		end
	end

	local buffs = self.Buffs
	if(buffs and not buffs.Container) then
		if(buffs.PreUpdate) then buffs:PreUpdate(unit, isFullUpdate) end

		local buffsChanged = false
		local numBuffs = buffs.num or 32
		local buffFilter = buffs.filter or 'HELPFUL'
		if(type(buffFilter) == 'function') then
			buffFilter = buffFilter(buffs, unit)
		end

		if(isFullUpdate) then
			buffs.all = table.wipe(buffs.all or {})
			buffs.active = table.wipe(buffs.active or {})
			buffsChanged = true

				local slots = {}
				local ok = pcall(function()
					slots = {C_UnitAuras.GetAuraSlots(unit, buffFilter)}
				end)
				if(not ok) then return end

				for i = 2, #slots do
					local data = processData(buffs, unit, C_UnitAuras.GetAuraDataBySlot(unit, slots[i]))
				buffs.all[data.auraInstanceID] = data

				if((buffs.FilterAura or FilterAura) (buffs, unit, data)) then
					buffs.active[data.auraInstanceID] = true
				end
			end
		else
			if(updateInfo.addedAuras) then
				for _, data in next, updateInfo.addedAuras do
					if(data.isHelpful and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, buffFilter)) then
						buffs.all[data.auraInstanceID] = processData(buffs, unit, data)

						if((buffs.FilterAura or FilterAura) (buffs, unit, data)) then
							buffs.active[data.auraInstanceID] = true
							buffsChanged = true
						end
					end
				end
			end

			if(updateInfo.updatedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs do
					if(buffs.all[auraInstanceID]) then
						buffs.all[auraInstanceID] = processData(buffs, unit, C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID))

						if(buffs.active[auraInstanceID]) then
							buffs.active[auraInstanceID] = true
							buffsChanged = true
						end
					end
				end
			end

			if(updateInfo.removedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs do
					if(buffs.all[auraInstanceID]) then
						buffs.all[auraInstanceID] = nil

						if(buffs.active[auraInstanceID]) then
							buffs.active[auraInstanceID] = nil
							buffsChanged = true
						end
					end
				end
			end
		end

		if(buffs.PostUpdateInfo) then
			buffs:PostUpdateInfo(unit, buffsChanged)
		end

		if(buffsChanged) then
			buffs.sorted = table.wipe(buffs.sorted or {})

			for auraInstanceID in next, buffs.active do
				table.insert(buffs.sorted, buffs.all[auraInstanceID])
			end

			table.sort(buffs.sorted, buffs.SortBuffs or buffs.SortAuras or SortAuras)

			local numVisible = math.min(numBuffs, #buffs.sorted)

			for i = 1, numVisible do
				updateAura(buffs, unit, buffs.sorted[i], i)
			end

			local visibleChanged = false

			if(numVisible ~= buffs.visibleButtons) then
				buffs.visibleButtons = numVisible
				visibleChanged = buffs.reanchorIfVisibleChanged
			end

			for i = numVisible + 1, #buffs do
				buffs[i]:Hide()
			end

			if(visibleChanged or buffs.createdButtons > buffs.anchoredButtons) then
				if(visibleChanged) then
					(buffs.SetPosition or SetPosition) (buffs, 1, numVisible)
				else
					(buffs.SetPosition or SetPosition) (buffs, buffs.anchoredButtons + 1, buffs.createdButtons)
					buffs.anchoredButtons = buffs.createdButtons
				end
			end

			if(buffs.PostUpdate) then buffs:PostUpdate(unit) end
		end
	end

	local debuffs = self.Debuffs
	if(debuffs and not debuffs.Container) then
		if(debuffs.PreUpdate) then debuffs:PreUpdate(unit, isFullUpdate) end

		local debuffsChanged = false
		local numDebuffs = debuffs.num or 40
		local debuffFilter = debuffs.filter or 'HARMFUL'
		if(type(debuffFilter) == 'function') then
			debuffFilter = debuffFilter(debuffs, unit)
		end

		if(isFullUpdate) then
			debuffs.all = table.wipe(debuffs.all or {})
			debuffs.active = table.wipe(debuffs.active or {})
			debuffsChanged = true

				local slots = {}
				local ok = pcall(function()
					slots = {C_UnitAuras.GetAuraSlots(unit, debuffFilter)}
				end)
				if(not ok) then return end

				for i = 2, #slots do
					local data = processData(debuffs, unit, C_UnitAuras.GetAuraDataBySlot(unit, slots[i]))
					debuffs.all[data.auraInstanceID] = data

				if((debuffs.FilterAura or FilterAura) (debuffs, unit, data)) then
					debuffs.active[data.auraInstanceID] = true
				end
			end
		else
			if(updateInfo.addedAuras) then
				for _, data in next, updateInfo.addedAuras do
					if(data.isHarmful and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, debuffFilter)) then
						debuffs.all[data.auraInstanceID] = processData(debuffs, unit, data)

						if((debuffs.FilterAura or FilterAura) (debuffs, unit, data)) then
							debuffs.active[data.auraInstanceID] = true
							debuffsChanged = true
						end
					end
				end
			end

			if(updateInfo.updatedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs do
					if(debuffs.all[auraInstanceID]) then
						debuffs.all[auraInstanceID] = processData(debuffs, unit, C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID))

						if(debuffs.active[auraInstanceID]) then
							debuffs.active[auraInstanceID] = true
							debuffsChanged = true
						end
					end
				end
			end

			if(updateInfo.removedAuraInstanceIDs) then
				for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs do
					if(debuffs.all[auraInstanceID]) then
						debuffs.all[auraInstanceID] = nil

						if(debuffs.active[auraInstanceID]) then
							debuffs.active[auraInstanceID] = nil
							debuffsChanged = true
						end
					end
				end
			end
		end

		if(debuffs.PostUpdateInfo) then
			debuffs:PostUpdateInfo(unit, debuffsChanged)
		end

		if(debuffsChanged) then
			debuffs.sorted = table.wipe(debuffs.sorted or {})

			for auraInstanceID in next, debuffs.active do
				table.insert(debuffs.sorted, debuffs.all[auraInstanceID])
			end

			table.sort(debuffs.sorted, debuffs.SortDebuffs or debuffs.SortAuras or SortAuras)

			local numVisible = math.min(numDebuffs, #debuffs.sorted)

			for i = 1, numVisible do
				updateAura(debuffs, unit, debuffs.sorted[i], i)
			end

			local visibleChanged = false

			if(numVisible ~= debuffs.visibleButtons) then
				debuffs.visibleButtons = numVisible
				visibleChanged = debuffs.reanchorIfVisibleChanged
			end

			for i = numVisible + 1, #debuffs do
				debuffs[i]:Hide()
			end

			if(visibleChanged or debuffs.createdButtons > debuffs.anchoredButtons) then
				if(visibleChanged) then
					(debuffs.SetPosition or SetPosition) (debuffs, 1, numVisible)
				else
					(debuffs.SetPosition or SetPosition) (debuffs, debuffs.anchoredButtons + 1, debuffs.createdButtons)
					debuffs.anchoredButtons = debuffs.createdButtons
				end
			end

			if(debuffs.PostUpdate) then debuffs:PostUpdate(unit) end
		end
	end
end

--[[ Aura containers (Forever / Midnight-era clients)

On this client the aura data of many units is "secret" for addons: it can be displayed but
not compared or computed with, so the classic code path below can't handle those units.
Blizzard's AuraContainer widget reads and displays auras itself (icon, cooldown, timer
text, stacks, dispel type color), so Buffs and Debuffs use it whenever it's available and
keep the Tukui layout options (size, num, spacing, growth-x/y, onlyShowPlayer).
--]]
local T, C = ns[1], ns[2]
local DispelStyle = Enum.CustomAuraButtonDispelTypeTextureStyle
local StealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter
local BorderEdges = {'BorderTop', 'BorderBottom', 'BorderLeft', 'BorderRight'}

-- The corner the auras grow away from
local function GetContainerOrigin(element)
	local growthX = (element['growth-x'] == 'LEFT' and -1) or 1
	local growthY = (element['growth-y'] == 'DOWN' and -1) or 1
	local origin = ((growthY == 1) and 'BOTTOM' or 'TOP') .. ((growthX == 1) and 'LEFT' or 'RIGHT')

	return origin, growthX, growthY
end

-- Tukui's timer text (T.FormatTime: 2d, 3h, 5m, 42, 3.4 - red under 5 seconds), built with
-- Blizzard's formatter objects since the remaining time itself may be secret.
local DurationTextOptions
local function GetDurationTextOptions()
	if DurationTextOptions == nil then
		local ok, options = pcall(function()
			local Up = Enum.NumericRuleFormatRounding.Up
			local formatter = C_StringUtil.CreateNumericRuleFormatter()

			formatter:SetBreakpoints({
				{threshold = 0, step = 0.1, rounding = Up, format = '%.1f'},
				{threshold = 5, step = 1, rounding = Up, format = '%.0f'},
				{threshold = 60, format = '%.0fm', components = {{div = 60, step = 1, rounding = Up}}},
				{threshold = 3600, format = '%.0fh', components = {{div = 3600, step = 1, rounding = Up}}},
				{threshold = 86400, format = '%.0fd', components = {{div = 86400, step = 1, rounding = Up}}},
			})

			local curve = C_CurveUtil.CreateColorCurve()
			curve:SetType(Enum.LuaCurveType.Step)
			curve:AddPoint(0, CreateColor(0.99, 0.31, 0.31))
			curve:AddPoint(5, CreateColor(1, 1, 1))

			return {
				textFormatter = formatter,
				textColor = {curve = curve, property = Enum.DurationTextBindingProperty.RemainingDuration},
			}
		end)

		DurationTextOptions = ok and options or false
	end

	return DurationTextOptions or nil
end

-- Tukui look for a container aura button. Buttons are not plain Buttons (AuraButton
-- widget), so Tukui's toolkit methods are called directly instead of button:Method().
local function StyleContainerButton(element, button)
	local API = T.Toolkit.API
	local size = element.size or 16

	button:SetSize(element.width or size, element.height or size)
	button:EnableMouse(not element.disableMouse)
	button:SetTooltipAnchorPoint(element.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT', 0, 0)

	API.CreateBackdrop(button)

	if not element.IsRaid then
		API.CreateShadow(button)
	end

	local icon = button:CreateTexture(nil, 'ARTWORK')
	API.SetInside(icon, button)
	icon:SetTexCoord(unpack(T.IconCoord))
	button.Icon = icon
	button:SetIcon(icon)

	local cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	API.SetInside(cooldown, button)
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(true)
	cooldown.noOCC = true
	cooldown.noCooldownCount = true
	button.Cooldown = cooldown
	button:SetDurationCooldown(cooldown)

	-- texts and the dispel border above the cooldown swipe
	local overlay = CreateFrame('Frame', nil, button)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)

	local count = overlay:CreateFontString(nil, 'OVERLAY')
	count:SetFont(C.Medias.Font, 9, 'THICKOUTLINE')
	count:SetPoint('BOTTOMRIGHT', 3, -3)
	count:SetJustifyH('RIGHT')
	count:SetTextColor(0.84, 0.75, 0.65)
	button.Count = count
	button:SetApplicationCount(count)

	-- small icons (nameplates) have no room for a timer, like before
	if size > 20 then
		local time = overlay:CreateFontString(nil, 'OVERLAY')
		time:SetFont(C.Medias.Font, 12, 'THINOUTLINE')
		time:SetPoint('CENTER', 1, 0)
		button.Time = time

		-- fall back to Blizzard's default format if the client refuses ours
		if not pcall(button.SetDurationText, button, time, GetDurationTextOptions()) then
			button:SetDurationText(time)
		end
	end

	-- Border colored by dispel type, drawn over Tukui's own 1px border: debuffs always
	-- (physical ones in red, like Tukui did), stealable buffs on "animated" elements
	local options
	if element.isDebuffElement then
		options = {style = DispelStyle.PreserveAsset, showWhenHarmful = true, showWhenHelpful = false, showWithoutDispelType = true}
	elseif element.isAnimated or element.CustomFilter then
		options = {style = DispelStyle.PreserveAsset, showWhenHarmful = false, showWhenHelpful = true, stealableFilter = StealableFilter.Stealable}
	end

	if options and button.Backdrop then
		for _, edge in ipairs(BorderEdges) do
			local border = button.Backdrop[edge]

			if border then
				local texture = overlay:CreateTexture(nil, 'OVERLAY', nil, 7)
				texture:SetTexture([[Interface\Buttons\WHITE8x8]])
				texture:SetAllPoints(border)
				button:AddDispelTypeTexture(texture, options)
			end
		end
	end

	if element.isCancellable then
		button:SetCancelAuraButtons('RightButtonUp')
	end
end

-- One group of auras in a container, with the Tukui options of `element`
local function AddContainerGroup(container, key, element, filter, newLine)
	filter = element.filter or filter

	if element.onlyShowPlayer then
		filter = filter .. '|PLAYER'
	end

	-- Tukui's nameplate buff filter (BuffIsStealable) only shows magic buffs
	local candidateFilters = element.candidateFilters
	if not candidateFilters and element.CustomFilter then
		candidateFilters = {includeDispelTypes = {Magic = true}}
	end

	local spacing = element['spacing-y'] or element.spacing or 0

	-- optional Blizzard sort (AuraContainerSortMethod), e.g. RaidDebuffs
	local sortMethod = element.sortMethod
	local sortDirection = sortMethod and AuraContainerSortDirection and AuraContainerSortDirection.Normal

	container:AddAuraGroup(key, filter, {
		maxFrameCount = element.num or 32,
		candidateFilters = candidateFilters,
		sortMethod = sortDirection and sortMethod or nil,
		sortDirection = sortDirection and sortMethod and sortDirection or nil,
		layout = {
			elementSpacing = element['spacing-x'] or element.spacing or 0,
			lineSpacing = spacing,
			groupLineSpacing = spacing,
			forceNewLine = newLine or nil,
		},
		initializeFrame = function(button)
			-- plugins (aura bars, aura track bars) can style buttons their own way
			local initialize = element.InitContainerButton or StyleContainerButton
			initialize(element, button)
		end,
	})
end

local function SetupContainer(element, filter)
	local ok, container = pcall(CreateFrame, 'AuraContainer', nil, element, 'CustomAuraContainerTemplate')
	if not ok or not container then
		return
	end

	local origin, growthX, growthY = GetContainerOrigin(element)
	-- nameplates are restricted regions, measuring them may be refused
	local measured, width = pcall(element.GetWidth, element)
	if not measured then
		width = nil
	end

	-- The container's size is set by Blizzard as a *secret* value: never anchor other
	-- frames to it, their position would be garbage (e.g. off screen).
	container:SetPoint(origin, element, origin, element.containerOffsetX or 0, element.containerOffsetY or 0)
	container:SetSize(1, 1)
	container:SetFlowLayoutAnchorPoint(origin)
	container:SetFlowLayoutGrowthDirection(growthX, growthY)
	container:SetFlowLayoutMaximumLineSize((width and width > 0) and width or (element.size or 16) * 8)
	container:SetFlowLayoutPadding(0, 0, 0, 0)

	AddContainerGroup(container, 'Tukui', element, filter)

	element.Container = container

	return container
end

-- Shared with Tukui's oUF plugins (AuraTrack, RaidDebuffs, AuraBars)
oUF.TukuiAuraContainer = {
	Setup = SetupContainer,
	StyleButton = StyleContainerButton,
	GetDurationTextOptions = GetDurationTextOptions,
}

-- Set the unit on / refresh a plugin's container
function oUF.TukuiAuraContainer.Update(container, unit)
	if container:GetUnit() ~= unit then
		container:SetUnit(unit)
	else
		container:UpdateAllAuras()
	end
end

local function UpdateContainers(self, unit)
	local buffsContainer = self.Buffs and self.Buffs.Container

	for _, element in next, {self.Buffs, self.Debuffs} do
		local container = element.Container

		-- debuffs sharing the buffs' container (target) are updated with it
		if container and not (element == self.Debuffs and container == buffsContainer) then
			if container:GetUnit() ~= unit then
				container:SetUnit(unit) -- triggers a full update
			else
				container:UpdateAllAuras()
			end
		end
	end
end

local function Update(self, event, unit, updateInfo)
	if(self.unit ~= unit) then return end

	UpdateContainers(self, unit)

	UpdateAuras(self, event, unit, updateInfo)

	-- Assume no event means someone wants to re-anchor things. This is usually
	-- done by UpdateAllElements and :ForceUpdate.
	if(event == 'ForceUpdate' or not event) then
		local auras = self.Auras
		if(auras) then
			(auras.SetPosition or SetPosition) (auras, 1, auras.createdButtons)
		end

		local buffs = self.Buffs
		if(buffs and not buffs.Container) then
			(buffs.SetPosition or SetPosition) (buffs, 1, buffs.createdButtons)
		end

		local debuffs = self.Debuffs
		if(debuffs and not debuffs.Container) then
			(debuffs.SetPosition or SetPosition) (debuffs, 1, debuffs.createdButtons)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	if(self.Auras or self.Buffs or self.Debuffs) then
		self:RegisterEvent('UNIT_AURA', UpdateAuras)

		local auras = self.Auras
		if(auras) then
			auras.__owner = self
			-- check if there's any anchoring restrictions
			auras.__restricted = not pcall(self.GetCenter, self)
			auras.ForceUpdate = ForceUpdate

			auras.createdButtons = auras.createdButtons or 0
			auras.anchoredButtons = 0
			auras.visibleButtons = 0
			auras.tooltipAnchor = auras.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'

			auras:Show()
		end

		local buffs = self.Buffs
		if(buffs) then
			buffs.__owner = self
			-- check if there's any anchoring restrictions
			buffs.__restricted = not pcall(self.GetCenter, self)
			buffs.ForceUpdate = ForceUpdate

			buffs.createdButtons = buffs.createdButtons or 0
			buffs.anchoredButtons = 0
			buffs.visibleButtons = 0
			buffs.tooltipAnchor = buffs.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'

			if not buffs.Container then
				SetupContainer(buffs, 'HELPFUL')
			end

			if buffs.Container then
				buffs.Container:SetEnabled(true)
			end

			buffs:Show()
		end

		local debuffs = self.Debuffs
		if(debuffs) then
			debuffs.__owner = self
			-- check if there's any anchoring restrictions
			debuffs.__restricted = not pcall(self.GetCenter, self)
			debuffs.ForceUpdate = ForceUpdate

			debuffs.createdButtons = debuffs.createdButtons or 0
			debuffs.anchoredButtons = 0
			debuffs.visibleButtons = 0
			debuffs.tooltipAnchor = debuffs.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			debuffs.isDebuffElement = true

			-- Debuffs stacked above the buffs (target): same container, second group on a new
			-- line, so Blizzard stacks them. Anchoring to the buff container can't work, its
			-- size is secret.
			if not debuffs.Container and buffs and buffs.Container and not debuffs.__restricted then
				local _, relativeTo = debuffs:GetPoint(1)

				if relativeTo == buffs then
					AddContainerGroup(buffs.Container, 'TukuiDebuffs', debuffs, 'HARMFUL', true)
					debuffs.Container = buffs.Container
					buffs.PostUpdate = nil
				end
			end

			if not debuffs.Container then
				SetupContainer(debuffs, 'HARMFUL')
			end

			if debuffs.Container then
				debuffs.Container:SetEnabled(true)
			end

			debuffs:Show()
		end

		return true
	end
end

local function Disable(self)
	if(self.Auras or self.Buffs or self.Debuffs) then
		self:UnregisterEvent('UNIT_AURA', UpdateAuras)

		if(self.Auras) then self.Auras:Hide() end
		if(self.Buffs) then
			if self.Buffs.Container then self.Buffs.Container:SetEnabled(false) end
			self.Buffs:Hide()
		end
		if(self.Debuffs) then
			if self.Debuffs.Container then self.Debuffs.Container:SetEnabled(false) end
			self.Debuffs:Hide()
		end
	end
end

oUF:AddElement('Auras', Update, Enable, Disable)
