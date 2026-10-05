local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local GUI = T["GUI"]
local GameMenu = CreateFrame("Frame")
local Menu = GameMenuFrame
local Header = Menu.Header

local function NudgePoint(frame, dx, dy)
	local point, relativeTo, relativePoint, x, y = frame:GetPoint()

	if point then
		frame:ClearAllPoints()
		frame:SetPoint(point, relativeTo, relativePoint, x + (dx or 0), y + (dy or 0))
	end
end

function GameMenu:PositionTukuiButton()
	if not GameMenu.Tukui then return end

	-- Layout runs on every menu open, after InitButtons. Skin here too: after a
	-- /reload the InitButtons hook can be installed too late to catch the first
	-- button creation, leaving half the menu on the default skin.
	-- NOTE: this hook receives GameMenuFrame as self, not GameMenu.
	GameMenu:SkinButtons()

	Menu:SetHeight(Menu:GetHeight() + 25)

	for button in Menu.buttonPool:EnumerateActive() do
		local text = button.GetText and button:GetText()

		if text and (text == _G.LOGOUT or text == _G.LOG_OUT or text == _G.EXIT_GAME or text == _G.RETURN_TO_GAME) then
			NudgePoint(button, 0, -25)
		else
			if text == _G.MACROS then
				GameMenu.Tukui:Show()
				GameMenu.Tukui:ClearAllPoints()
				GameMenu.Tukui:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -Menu.spacing)
			end
		end
	end
end

function GameMenu:CreateTukuiMenuButton()
	local Tukui = CreateFrame("Button", nil, Menu, "MainMenuFrameButtonTemplate")
	Tukui:SetSize(200, 35)
	Tukui:SetText("Tukui")

	Tukui:SetScript("OnClick", function(self)
		if InCombatLockdown() then
			T.Print(ERR_NOT_IN_COMBAT)

			return
		end

		GUI:Toggle()

		HideUIPanel(Menu)
	end)

	hooksecurefunc(Menu, "Layout", GameMenu.PositionTukuiButton)

	self.Tukui = Tukui
end

local function SetHover(self)
	local Backdrop = self.Backdrop
	if not Backdrop then return end

	local Class = select(2, UnitClass("player"))
	local Color = RAID_CLASS_COLORS[Class]
	if T.Toolkit.Settings.ClassColors then
		Color.r, Color.g, Color.b = unpack(T.Toolkit.Settings.ClassColors[Class])
	end

	Backdrop:SetBackdropColor(Color.r * .2, Color.g * .2, Color.b * .2)
	Backdrop:SetBorderColor(Color.r, Color.g, Color.b)
end

local function SetNormal(self)
	local Backdrop = self.Backdrop
	if not Backdrop then return end

	local Settings = T.Toolkit.Settings
	Backdrop:SetBackdropColor(Settings.BackdropColor[1], Settings.BackdropColor[2], Settings.BackdropColor[3], 1)
	Backdrop:SetBorderColor(Settings.BorderColor[1], Settings.BorderColor[2], Settings.BorderColor[3])
end

-- AddButton() clears OnEnter/OnLeave (SetScript nil) on every menu open, which
-- drops SkinButton's HookScript hover hooks. Re-apply hover via SetScript (not
-- HookScript, to avoid stacking) for every button on each skin pass.
local function ApplyHover(button)
	if not button then return end

	button:SetScript("OnEnter", SetHover)
	button:SetScript("OnLeave", SetNormal)
end

function GameMenu:SkinButtons()
	local menu = Menu

	if not menu.buttonPool then return end

	local function SkinOne(button)
		if not button or not button.SkinButton then return end

		button:SkinButton(nil, nil, true)

		-- MainMenuFrameButtonTemplate is a ThreeSlice button (Left/Center/Right
		-- textures). Its UpdateButton mixin re-applies the default red atlas on
		-- every OnShow/OnEnable/OnMouseUp, which undoes the skin (worst after a
		-- /reload, when buttons are reused from the pool with IsSkinned set).
		if button.UpdateButton then
			button.UpdateButton = function() end
		end

		-- SkinButton hides "Middle", but ThreeSlice buttons name the center
		-- texture "Center" — hide it explicitly.
		if button.Center then button.Center:SetAlpha(0) end
	end

	for button in menu.buttonPool:EnumerateActive() do
		if button then
			if not button.IsSkinned then
				SkinOne(button)
				button.IsSkinned = true
			end

			ApplyHover(button)
		end
	end

	if GameMenu.Tukui then
		if not GameMenu.Tukui.IsSkinned then
			SkinOne(GameMenu.Tukui)
			GameMenu.Tukui.IsSkinned = true
		end

		ApplyHover(GameMenu.Tukui)
	end
end

function GameMenu:Enable()
	self:CreateTukuiMenuButton()

	if not AddOnSkins then
		if T.Retail then
			if Header then Header:StripTextures() end

			if Header then
				Header:ClearAllPoints()
				Header:SetPoint("TOP", Menu, 0, 7)
			end

			if Menu.Border then Menu.Border:StripTextures() end

			Menu:CreateBackdrop("Transparent")
			Menu:CreateShadow()

			-- Buttons inside a section sit flush (spacing defaults to 0); give
			-- them a little breathing room so they don't look like they overlap.
			Menu.spacing = 6

			if Menu.InitButtons then
				hooksecurefunc(Menu, "InitButtons", GameMenu.SkinButtons)
			end
		else
			Menu:StripTextures()

			Menu:CreateBackdrop("Transparent")
			Menu:CreateShadow()

			for _, Button in pairs({Menu:GetChildren()}) do
				if Button.IsObjectType and Button:IsObjectType("Button") then
					Button:SkinButton(nil, nil, true)
				end
			end
		end
	end
end

Miscellaneous.GameMenu = GameMenu
