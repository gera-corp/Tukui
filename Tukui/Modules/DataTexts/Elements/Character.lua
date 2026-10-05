local T, C, L = unpack((select(2, ...)))

local DataText = T["DataTexts"]
local ClassColor = T.RGBToHex(unpack(T.Colors.class[T.MyClass]))

-- 1000 = "no durability" placeholder (empty slot, or not known yet right after login)
local NoDurability = 1000

-- Tukui has no Russian locale: use Blizzard's localized slot names
local SlotNames = {
	[1] = HEADSLOT, [3] = SHOULDERSLOT, [5] = CHESTSLOT, [6] = WAISTSLOT, [7] = LEGSSLOT, [8] = FEETSLOT,
	[9] = WRISTSLOT, [10] = HANDSSLOT, [16] = MAINHANDSLOT, [17] = SECONDARYHANDSLOT, [18] = RANGEDSLOT,
}

for _, Slot in ipairs(L.DataText.Slots) do
	Slot[2] = SlotNames[Slot[1]] or Slot[2]
end

local function GetLowestDurability()
	local Lowest = L.DataText.Slots[1][3]

	return Lowest < NoDurability and floor(Lowest * 100) or 100
end

local Update = function(self)
	for i = 1, 11 do
		local Slot = L.DataText.Slots[i]
		local Current, Max = GetInventoryItemDurability(Slot[1])

		-- reset every time: unequipped items used to keep their old value
		if Current and Max and Max > 0 then
			Slot[3] = Current / Max
		else
			Slot[3] = NoDurability
		end
	end

	table.sort(L.DataText.Slots, function(a, b) return a[3] < b[3] end)
	local durability = GetLowestDurability()
	local r, g, b = T.ColorGradient(durability, 100, 0.8, 0, 0, 0.8, 0.8, 0, 0, 0.8, 0)

	self.Text:SetFormattedText("%s |cff%02x%02x%02x%s%%|r", DURABILITY or "Durability", r * 255, g * 255, b * 255, durability)
end

local OnEnter = function(self)
	-- (Retail tooltip reads the stats itself; calling Blizzard's PaperDollFrame_UpdateStats
	-- from addon code would taint the character frame)
	if not T.Retail and PaperDollFrame_UpdateStats then
		PaperDollFrame_UpdateStats()
	end

	GameTooltip:SetOwner(self:GetTooltipAnchor())
	GameTooltip:ClearLines()

	if T.Retail then
		-- Set attributes (WIP)
		GameTooltip:AddDoubleLine(ClassColor..T.MyName.."|r", T.MyRealm)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("|CFFFFFFFF"..PET_BATTLE_STATS_LABEL.."|r")
		GameTooltip:AddDoubleLine("|CF00FFF00"..LEVEL.."|r", UnitLevel("player"))
		GameTooltip:AddDoubleLine("|CF00FFF00"..ITEM_UPGRADE_STAT_AVERAGE_ITEM_LEVEL.."|r", GetAverageItemLevel())
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("|CF00FFF00"..SPELL_STAT1_NAME.."|r", UnitStat("player", LE_UNIT_STAT_STRENGTH))
		GameTooltip:AddDoubleLine("|CF00FFF00"..SPELL_STAT2_NAME.."|r", UnitStat("player", LE_UNIT_STAT_AGILITY))
		GameTooltip:AddDoubleLine("|CF00FFF00"..SPELL_STAT3_NAME.."|r", UnitStat("player", LE_UNIT_STAT_INTELLECT))
		GameTooltip:AddDoubleLine("|CF00FFF00"..SPELL_STAT4_NAME.."|r", UnitStat("player", LE_UNIT_STAT_STAMINA))
		GameTooltip:AddLine(" ")
	end

	if T.Classic then
		GameTooltip:AddDoubleLine(ClassColor..T.MyName.."|r "..UnitLevel("player"), T.MyRealm)
		GameTooltip:AddLine(" ")

		if CharacterStatFrame then
			for _, Frame in pairs(CharacterStatFrame) do
				local Name = _G[Frame.."Label"]
				local Value = _G[Frame.."StatText"]
				local Tooltip = _G[Frame].tooltip2
				local StatName, StatValue

				if Name:GetText() then
					StatName = "|cffff8000"..Name:GetText().."|r"
				end

				if Value:GetText() then
					StatValue = "|cffffffff"..Value:GetText().."|r"
				end

				if StatName and StatValue then
					if IsAlternativeTooltip then
						GameTooltip:AddLine("|CF00FFF00"..StatName.."|r |CFFFFFFFF"..StatValue.."|r")
					else
						GameTooltip:AddDoubleLine("|CF00FFF00"..StatName.."|r", "|CFFFFFFFF"..StatValue.."|r")
					end

					if Tooltip and IsAlternativeTooltip then
						-- Remove double enter, for gaining tooltip space
						Tooltip = string.gsub(Tooltip, "\n\n", " ")

						GameTooltip:AddLine(Tooltip, .75, .75, .75)
						GameTooltip:AddLine(" ")
					end
				end
			end
		end

		if not IsShiftKeyDown() then
			GameTooltip:AddLine(" ")
		end
	end

	-- Display durability
	GameTooltip:AddDoubleLine("|CFFFF8000"..DURABILITY..":|r", GetLowestDurability().."%")

	for i = 1, 11 do
		if (L.DataText.Slots[i][3] ~= NoDurability) then
			local Green, Red

			Green = L.DataText.Slots[i][3] * 2
			Red = 1 - Green

			GameTooltip:AddDoubleLine(L.DataText.Slots[i][2]..":", floor(L.DataText.Slots[i][3] * 100).."%", .75, .75, .75, Red + 1, Green, 0)
		end
	end

	GameTooltip:Show()
end

local ToggleCharacter = function(self)
	if InCombatLockdown() then
		T.Print(ERR_NOT_IN_COMBAT)

		return
	end

	ToggleCharacter("PaperDollFrame")
end

local Enable = function(self)
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", GameTooltip_Hide)
	self:SetScript("OnMouseDown", ToggleCharacter)
	self:Update()
	self.Text:SetText(ClassColor..T.MyName.."|r")
end

local Disable = function(self)
	self.Text:SetText("")
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
end

DataText:Register("Character", Enable, Disable, Update)
