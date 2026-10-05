local T, C, L = unpack((select(2, ...)))

local Auras = T["Auras"]

Auras.HeaderNames = {
	"TukuiBuffHeader",
	"TukuiDebuffHeader",
}

--[[ Container headers

On this client SecureAuraHeaderTemplate is only loaded for the Classic game type (see
Blizzard_RestrictedAddOnEnvironment.toc), so the secure headers below can't be created and
nothing was shown. Blizzard's AuraContainer does the same job (and handles secret aura
data, right-click cancel and weapon enchants itself), styled like Tukui's aura buttons.
--]]
local ContainerTimerOptions

local function GetTimerOptions()
	if ContainerTimerOptions == nil then
		local ok, options = pcall(function()
			local Up = Enum.NumericRuleFormatRounding.Up
			local Formatter = C_StringUtil.CreateNumericRuleFormatter()

			-- same output as T.FormatTime
			Formatter:SetBreakpoints({
				{threshold = 0, step = 0.1, rounding = Up, format = "%.1f"},
				{threshold = 5, step = 1, rounding = Up, format = "%.0f"},
				{threshold = 60, format = "%.0fm", components = {{div = 60, step = 1, rounding = Up}}},
				{threshold = 3600, format = "%.0fh", components = {{div = 3600, step = 1, rounding = Up}}},
				{threshold = 86400, format = "%.0fd", components = {{div = 86400, step = 1, rounding = Up}}},
			})

			-- Tukui's colors: red under 5s, orange under a minute, light grey above
			local Curve = C_CurveUtil.CreateColorCurve()
			Curve:SetType(Enum.LuaCurveType.Step)
			Curve:AddPoint(0, CreateColor(1, 20/255, 20/255))
			Curve:AddPoint(5, CreateColor(1, 165/255, 0))
			Curve:AddPoint(60.5, CreateColor(.9, .9, .9))

			return {
				textFormatter = Formatter,
				textColor = {curve = Curve, property = Enum.DurationTextBindingProperty.RemainingDuration},
			}
		end)

		ContainerTimerOptions = ok and options or false
	end

	return ContainerTimerOptions or nil
end

local function SkinContainerButton(Button, IsDebuff)
	local API = T.Toolkit.API
	local Font = T.GetFont(C["Auras"].Font)

	Button:SetSize(30, 30)
	Button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", -5, -5)

	API.CreateBackdrop(Button)
	API.CreateShadow(Button)
	Button.Backdrop:SetFrameLevel(math.max(0, Button:GetFrameLevel() - 1))

	local Icon = Button:CreateTexture(nil, "BORDER")
	Icon:SetTexCoord(unpack(T.IconCoord))
	API.SetInside(Icon, Button)
	Button:SetIcon(Icon)

	local Overlay = CreateFrame("Frame", nil, Button)
	Overlay:SetAllPoints()
	Overlay:SetFrameLevel(Button:GetFrameLevel() + 2)

	local Count = Overlay:CreateFontString(nil, "OVERLAY")
	Count:SetFontObject(Font)
	Count:SetPoint("TOP", Button, 1, -4)
	Button:SetApplicationCount(Count)

	if C.Auras.ClassicTimer then
		local Duration = Overlay:CreateFontString(nil, "OVERLAY")
		Duration:SetFontObject(Font)
		Duration:SetPoint("BOTTOM", Button, 0, -17)

		if not pcall(Button.SetDurationText, Button, Duration, GetTimerOptions()) then
			Button:SetDurationText(Duration)
		end
	else
		local Holder = CreateFrame("Frame", nil, Button)
		Holder:SetSize(30, 4)
		Holder:SetPoint("TOP", Button, "BOTTOM", 0, -1)
		API.CreateBackdrop(Holder, "Transparent")
		API.CreateShadow(Holder)

		local Bar = CreateFrame("StatusBar", nil, Holder)
		API.SetInside(Bar, Holder)
		Bar:SetStatusBarTexture(C.Medias.Blank)
		Bar:SetStatusBarColor(0, 0.8, 0)
		Button:SetDurationBar(Bar, {
			-- shrink with the remaining time (Blizzard's default fills up with the elapsed time)
			direction = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime,
		})
	end

	-- debuff border colored by type, over Tukui's 1px border
	if IsDebuff and Button.Backdrop then
		local Options = {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			showWhenHarmful = true,
			showWhenHelpful = false,
			showWithoutDispelType = true,
		}

		for _, Edge in ipairs({"BorderTop", "BorderBottom", "BorderLeft", "BorderRight"}) do
			local Border = Button.Backdrop[Edge]

			if Border then
				local Texture = Overlay:CreateTexture(nil, "OVERLAY", nil, 7)
				Texture:SetTexture("Interface\\Buttons\\WHITE8x8")
				Texture:SetAllPoints(Border)
				Button:AddDispelTypeTexture(Texture, Options)
			end
		end
	else
		Button:SetCancelAuraButtons("RightButtonUp")
	end
end

-- Built on the first PLAYER_ENTERING_WORLD, not at PLAYER_LOGIN: on a fresh login Tukui's
-- saved settings (VARIABLES_LOADED) arrive after PLAYER_LOGIN, so "Grow left to right",
-- buffs per row and classic timer only applied after a /reload.
function Auras:BuildContainer(Header)
	local IsDebuff = Header.IsDebuff
	local PerRow = C["Auras"].BuffsPerRow

	if (IsDebuff and C.Auras.HideDebuffs) or (not IsDebuff and C.Auras.HideBuffs) then
		Header:Hide()

		return
	end

	Header:SetSize(PerRow * 35, 30)

	local ok, Container = pcall(CreateFrame, "AuraContainer", nil, Header, "CustomAuraContainerTemplate")

	if ok and Container then
		Header.Container = Container

		Container:SetSize(1, 1)
		Auras:ApplyLayout()
		Container:SetFlowLayoutMaximumLineSize(PerRow * 35)
		Container:SetFlowLayoutPadding(0, 0, 0, 0)

		local Initialize = function(Button)
			SkinContainerButton(Button, IsDebuff)
		end

		Container:AddAuraGroup("Tukui", IsDebuff and "HARMFUL" or "HELPFUL", {
			maxFrameCount = IsDebuff and 16 or 40,
			layout = {
				elementSpacing = 5,
				lineSpacing = C.Auras.ClassicTimer and 21 or 10,
			},
			initializeFrame = Initialize,
		})

		-- temporary weapon enchants next to the buffs, like the old weapon template
		if not IsDebuff then
			local Slots = AuraContainerItemEnchantmentSlot or {MainHand = 0, OffHand = 1, Ranged = 2}

			for _, Slot in ipairs({Slots.MainHand, Slots.OffHand}) do
				pcall(Container.AddItemEnchantment, Container, Slot, {initializeFrame = Initialize, hidePermanent = true})
			end
		end

		Container:SetUnit("player")
		Container:SetEnabled(true)

		-- settings can still change right after login (see Loading.lua): check again later
		C_Timer.After(3, function()
			Container.TukuiAnchor = nil
			Auras:ApplyLayout()
		end)
	end
end

-- Growth direction of the container headers from the current settings. Default: from the
-- right edge leftwards; the "Grow left to right" option flips it.
function Auras:ApplyLayout()
	for _, Header in pairs(Auras.Headers) do
		local Container = Header.Container

		if Container then
			local Anchor = C.Auras.GrowRight and "TOPLEFT" or "TOPRIGHT"

			if Container.TukuiAnchor ~= Anchor then
				Container.TukuiAnchor = Anchor
				Container:ClearAllPoints()
				Container:SetPoint(Anchor, Header, Anchor, 0, 0)
				Container:SetFlowLayoutAnchorPoint(Anchor)
				Container:SetFlowLayoutGrowthDirection(C.Auras.GrowRight and 1 or -1, -1) -- down
			end
		end
	end
end

function Auras:CreateContainerHeaders()
	local Movers = T["Movers"]
	local Headers = Auras.Headers
	local PerRow = C["Auras"].BuffsPerRow

	for i = 1, 2 do
		local IsDebuff = (i == 2)
		local Header = CreateFrame("Frame", Auras.HeaderNames[i], T.PetHider)

		Header:SetSize(PerRow * 35, 30)
		Header:SetFrameStrata("BACKGROUND")
		Header:SetClampedToScreen(true)

		Header.IsDebuff = IsDebuff

		table.insert(Headers, Header)
	end

	local Buffs = Headers[1]
	local Debuffs = Headers[2]

	if (not C.Auras.HideBuffs) then
		Buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -27)
		Buffs:Show()

		Movers:RegisterFrame(Buffs, "Buffs")
	else
		Buffs:Hide()
	end

	if (not C.Auras.HideDebuffs) then
		if (C.Auras.HideBuffs) then
			Debuffs:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -30, 2)
		else
			Debuffs:SetPoint("TOP", Buffs, "BOTTOM", 0, -95)
		end

		Debuffs:Show()

		Movers:RegisterFrame(Debuffs, "Debuffs")
	else
		Debuffs:Hide()
	end

	local Builder = CreateFrame("Frame")
	Builder:RegisterEvent("PLAYER_ENTERING_WORLD")
	Builder:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()

		for _, Header in pairs(Headers) do
			Auras:BuildContainer(Header)
		end
	end)

	-- the secure headers followed the vehicle; do the same
	local VehicleWatcher = CreateFrame("Frame")
	VehicleWatcher:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
	VehicleWatcher:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
	VehicleWatcher:SetScript("OnEvent", function(_, Event)
		local Unit = (Event == "UNIT_ENTERED_VEHICLE" and UnitHasVehicleUI("player")) and "vehicle" or "player"

		for _, Header in pairs(Headers) do
			if Header.Container then
				Header.Container:SetUnit(Unit)
			end
		end
	end)
end

function Auras:CreateHeaders()
	if (not C.Auras.Enable) then
		return
	end

	-- secure aura headers are Classic-only on this client, see above (their Lua defines
	-- SecureAuraHeader_OnLoad; creating a frame from a missing template may not even error)
	if not SecureAuraHeader_OnLoad then
		return self:CreateContainerHeaders()
	end

	local Movers = T["Movers"]
	local Headers = Auras.Headers

	for i = 1, 2 do
		local Header

		local ok, H = pcall(CreateFrame, "Frame", Auras.HeaderNames[i], T.PetHider, "SecureAuraHeaderTemplate")
		if ok and H then
			Header = H
		else
			Header = CreateFrame("Frame", Auras.HeaderNames[i], T.PetHider)
		end
		Header:SetClampedToScreen(true)
		Header:SetMovable(true)
		Header:SetAttribute("minHeight", 30)
		Header:SetAttribute("wrapAfter", C["Auras"].BuffsPerRow)
		Header:SetAttribute("wrapYOffset", C.Auras.ClassicTimer and -51 or -40)
		Header:SetAttribute("xOffset", C.Auras.GrowRight and 35 or -35)

		if C.Auras.GrowRight then
			Header:SetAttribute("point", "TOPLEFT")
		end
		Header:CreateBackdrop()
		Header.Backdrop:SetBorderColor(1, 0, 0)
		Header.Backdrop:Hide()
		Header.Backdrop.Text = Header.Backdrop:CreateFontString(nil, "OVERLAY")
		Header.Backdrop.Text:SetFontTemplate(C.Medias.Font, 12)
		Header.Backdrop.Text:SetPoint("CENTER")

		if (i == 1) then
			Header.Backdrop.Text:SetText(L.Auras.MoveBuffs)
		else
			Header.Backdrop.Text:SetText(L.Auras.MoveDebuffs)
		end


		Header:SetAttribute("minWidth", C["Auras"].BuffsPerRow * 35)
		Header:SetAttribute("template", "AurasTemplate")
		Header:SetAttribute("weaponTemplate", "AurasTemplate")
		Header:SetSize(30, 30)
		Header:SetFrameStrata("BACKGROUND")

		RegisterAttributeDriver(Header, "unit", "[vehicleui] vehicle; player")

		table.insert(Headers, Header)
	end

	local Buffs = Headers[1]
	local Debuffs = Headers[2]

	if (not C.Auras.HideBuffs) then
		Buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -27)
		Buffs:SetAttribute("filter", "HELPFUL")
		Buffs:SetAttribute("includeWeapons", 1)
		Buffs:Show()

		Movers:RegisterFrame(Buffs, "Buffs")
	end

	if (not C.Auras.HideDebuffs) then
		if (C.Auras.HideBuffs) then
			Debuffs:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -30, 2)
		else
			Debuffs:SetPoint("TOP", Buffs, "BOTTOM", 0, -95)
		end

		Debuffs:SetAttribute("filter", "HARMFUL")
		Debuffs:Show()

		Movers:RegisterFrame(Debuffs, "Debuffs")
	end
end
