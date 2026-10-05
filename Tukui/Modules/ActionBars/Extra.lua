local T, C, L = unpack((select(2, ...)))

local ActionBars = T["ActionBars"]
local Movers = T["Movers"]
local Button = ExtraActionButton1
local Icon = ExtraActionButton1Icon
local Container = ExtraAbilityContainer
local ZoneAbilities = ZoneAbilityFrame

function ActionBars:DisableExtraButtonTexture()
	local Bar = ExtraActionBarFrame

	if (HasExtraActionBar()) then
		Button.style:SetTexture("")

		Icon:SetInside()
	end
end

function ActionBars:SkinZoneAbilities()
	for SpellButton in ZoneAbilities.SpellButtonContainer:EnumerateActive() do
		if not SpellButton.IsSkinned then
			SpellButton:CreateBackdrop()
			SpellButton:StyleButton()
			SpellButton:CreateShadow()

			SpellButton.Backdrop:SetFrameLevel(SpellButton:GetFrameLevel() - 1)

			SpellButton.Icon:SetTexCoord(unpack(T.IconCoord))
			SpellButton.Icon:ClearAllPoints()
			SpellButton.Icon:SetInside(SpellButton.Backdrop)

			SpellButton.NormalTexture:SetAlpha(0)

			SpellButton.IsSkinned = true
		end
	end
end

function ActionBars:SetupExtraButton()
	local Holder = CreateFrame("Frame", "TukuiExtraActionButton", UIParent)
	local Bar = ExtraActionBarFrame
	local Icon = ExtraActionButton1Icon
	local Button = ExtraActionButton1

	Bar:EnableMouse(false)
	Bar:SetParent(UIParent)

	Holder:SetSize(160, 80)
	Holder:SetPoint("BOTTOM", 0, 250)

	Container:SetParent(Holder)
	Container:ClearAllPoints()
	Container:SetPoint("CENTER", Holder, "CENTER", 0, 0)
	Container:EnableMouse(false)
	Container.ignoreFramePositionManager = true

	Button:StripTextures()
	Button:CreateBackdrop()
	Button:StyleButton()
	Button:SetNormalTexture("")
	Button:CreateShadow()

	Button.HotKey:Kill()

	Button.QuickKeybindHighlightTexture:SetTexture("")

	Icon:SetDrawLayer("ARTWORK")
	Icon:SetTexCoord(unpack(T.IconCoord))

	ZoneAbilities.Style:SetAlpha(0)

	Movers:RegisterFrame(Holder, "Extra Buttons")

	-- No hooksecurefunc on ExtraActionBar_Update / ZoneAbilityFrame:UpdateDisplayedZoneAbilities:
	-- on this client Blizzard's secure code gets nil when calling a function an addon
	-- hooked ("attempt to call a nil value"), so the Blizzard update never runs.
	-- Re-skin from our own event frame instead, once Blizzard has updated.
	local Updater = CreateFrame("Frame")
	local Pending = false

	local function Update()
		Pending = false

		ActionBars:DisableExtraButtonTexture()
		ActionBars:SkinZoneAbilities()
	end

	Updater:RegisterEvent("PLAYER_ENTERING_WORLD")
	Updater:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
	Updater:RegisterEvent("SPELLS_CHANGED")
	Updater:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	Updater:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	Updater:RegisterUnitEvent("UNIT_AURA", "player")
	Updater:SetScript("OnEvent", function()
		-- Blizzard refreshes zone abilities a frame later (C_Timer.After(0)), wait a bit more
		if not Pending then
			Pending = true
			C_Timer.After(0.2, Update)
		end
	end)
end
