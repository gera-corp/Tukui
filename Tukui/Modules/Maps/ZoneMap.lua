local T, C, L = unpack((select(2, ...)))

local ZoneMap = CreateFrame("Frame")
local Movers = T["Movers"]

function ZoneMap:SetMapAlpha()
	local Map = BattlefieldMapFrame
	local Alpha = 1 - BattlefieldMapOptions.opacity

	Map.ScrollContainer.Backdrop:SetAlpha(Alpha)
	Map.ScrollContainer.Shadow:SetAlpha(Alpha)
end

function ZoneMap:Skin()
	local Map = BattlefieldMapFrame
	local Tab = BattlefieldMapTab

	Map.BorderFrame:Kill()
	Map.ScrollContainer:CreateBackdrop()
	Map.ScrollContainer:CreateShadow()
	Tab:StripTextures()

	Map.IsSkinned = true
end

-- Not a hook on BattlefieldMapFrame:RefreshAlpha: on this client, hooking a Blizzard
-- object's method breaks it when Blizzard calls it from secure code. The opacity only
-- changes from the map's options, so re-apply it from the map's own OnUpdate.
function ZoneMap:AddHooks()
	local LastOpacity

	BattlefieldMapFrame:HookScript("OnUpdate", function()
		local Opacity = BattlefieldMapOptions and BattlefieldMapOptions.opacity

		if Opacity ~= LastOpacity then
			LastOpacity = Opacity
			ZoneMap:SetMapAlpha()
		end
	end)
end

function ZoneMap:OnEvent(event, addon)
	if addon ~= "Blizzard_BattlefieldMap" then
		return
	end

	if not BattlefieldMapFrame.IsSkinned then
		self:Skin()
		self:AddHooks()
	end
end

function ZoneMap:Enable()
	self:RegisterEvent("ADDON_LOADED")
	self:SetScript("OnEvent", self.OnEvent)

	if BattlefieldMapFrame and not BattlefieldMapFrame.IsSkinned then
		self:Skin()
		self:AddHooks()
	end
end

T["Maps"].Zonemap = ZoneMap
