local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local StaticPopups = CreateFrame("Frame")

StaticPopups.Popups = {
	StaticPopup1,
	StaticPopup2,
	StaticPopup3,
	StaticPopup4,
}

function StaticPopups:Skin()
	local Name = self:GetName()

	_G[Name]:StripTextures()
	_G[Name]:CreateBackdrop("Transparent")
	_G[Name]:CreateShadow()
	_G[Name.."Button1"]:StripTextures()
	_G[Name.."Button2"]:StripTextures()
	_G[Name.."Button3"]:StripTextures()
	_G[Name.."Button4"]:StripTextures()
	_G[Name.."Button1"]:SkinButton()
	_G[Name.."Button2"]:SkinButton()
	_G[Name.."Button3"]:SkinButton()
	_G[Name.."Button4"]:SkinButton()
	_G[Name.."EditBox"]:SkinEditBox()
	_G[Name.."EditBox"].Backdrop:ClearAllPoints()
	_G[Name.."EditBox"].Backdrop:SetPoint("TOPLEFT", _G[Name.."EditBox"], -4, -5)
	_G[Name.."EditBox"].Backdrop:SetPoint("BOTTOMRIGHT", _G[Name.."EditBox"], 4, 6)
	_G[Name.."MoneyInputFrameGold"]:SkinEditBox()
	_G[Name.."MoneyInputFrameSilver"]:SkinEditBox()
	_G[Name.."MoneyInputFrameCopper"]:SkinEditBox()
	_G[Name.."MoneyInputFrameGold"].Backdrop:SetBackdropBorderColor(0, 0, 0, 0)
	_G[Name.."MoneyInputFrameSilver"].Backdrop:SetBackdropBorderColor(0, 0, 0, 0)
	_G[Name.."MoneyInputFrameCopper"].Backdrop:SetBackdropBorderColor(0, 0, 0, 0)
	_G[Name.."EditBox"].Backdrop:SetPoint("TOPLEFT", -2, -4)
	_G[Name.."EditBox"].Backdrop:SetPoint("BOTTOMRIGHT", 2, 4)
	_G[Name.."CloseButton"]:SkinCloseButton()

	-- Keep Blizzard's close/minimize art hidden with alpha. Replacing SetNormalTexture /
	-- SetPushedTexture with addon functions (as before) tainted StaticPopup_Show, and then
	-- the protected action behind the popup (buying a bank slot, etc.) got blocked.
	local CloseButton = _G[Name.."CloseButton"]

	for _, Texture in pairs({CloseButton:GetNormalTexture(), CloseButton:GetPushedTexture(), CloseButton:GetHighlightTexture(), CloseButton:GetDisabledTexture()}) do
		if Texture then
			Texture:SetAlpha(0)
		end
	end
end

--[[ Overlay skin (this client)

The popups are LayoutFrames here (Blizzard_StaticPopup_Game): their layout reads what's inside
them, so Tukui must not add frames into them or rewrite their buttons, and must not hook them -
the protected action behind "Accept" (buy a bank tab, delete an item...) would get blocked.
So Blizzard's art is only hidden with alpha (display state, nothing written into the popup's
tables), Tukui's backdrop/shadow are separate frames parented to UIParent and anchored to the
popup and its buttons, and one Tukui frame keeps them in sync by polling - no hooks at all.
--]]
local Overlays = {}

local function CreateOverlay(Target)
	local Overlay = CreateFrame("Frame", nil, UIParent)

	Overlay:SetAllPoints(Target)
	Overlay:EnableMouse(false)
	Overlay:CreateBackdrop("Transparent")
	Overlay:CreateShadow()
	Overlay:Hide()
	Overlay.Target = Target

	return Overlay
end

local function HideArt(Popup)
	for _, Key in pairs({"BG", "Border", "NineSlice"}) do
		if Popup[Key] and Popup[Key].SetAlpha then
			Popup[Key]:SetAlpha(0)
		end
	end

	for i = 1, 4 do
		local Button = _G[Popup:GetName().."Button"..i]

		if Button then
			for _, Texture in pairs({Button:GetNormalTexture(), Button:GetPushedTexture(), Button:GetDisabledTexture(), Button:GetHighlightTexture()}) do
				if Texture then
					Texture:SetAlpha(0)
				end
			end
		end
	end
end

local function SyncOverlay(Overlay, Level)
	local Target = Overlay.Target

	if Target:IsVisible() then
		if not Overlay:IsShown() then
			Overlay:Show()
		end

		Overlay:SetFrameStrata(Target:GetFrameStrata())
		Overlay:SetFrameLevel(math.max(0, (Level or Target:GetFrameLevel()) - 1))

		return true
	elseif Overlay:IsShown() then
		Overlay:Hide()
	end
end

function StaticPopups:EnableOverlaySkin()
	local R, G, B = unpack(T.Colors.class[T.MyClass])
	local BorderR, BorderG, BorderB = unpack(C.General.BorderColor)

	for _, Popup in pairs(StaticPopups.Popups) do
		HideArt(Popup)

		local Entry = {Popup = Popup, Frame = CreateOverlay(Popup), Buttons = {}}

		for i = 1, 4 do
			local Button = _G[Popup:GetName().."Button"..i]

			if Button then
				local ButtonOverlay = CreateOverlay(Button)
				ButtonOverlay.Backdrop:SetBackdropColor(unpack(C.General.BackdropColor))

				table.insert(Entry.Buttons, ButtonOverlay)
			end
		end

		table.insert(Overlays, Entry)
	end

	self:SetScript("OnUpdate", function()
		for _, Entry in pairs(Overlays) do
			if SyncOverlay(Entry.Frame) then
				for _, ButtonOverlay in pairs(Entry.Buttons) do
					if SyncOverlay(ButtonOverlay) then
						-- class colored border on hover, like Tukui's own buttons
						local Hovered = ButtonOverlay.Target:IsMouseOver()

						if Hovered ~= ButtonOverlay.Hovered then
							ButtonOverlay.Hovered = Hovered

							if Hovered then
								ButtonOverlay.Backdrop:SetBorderColor(R, G, B)
							else
								ButtonOverlay.Backdrop:SetBorderColor(BorderR, BorderG, BorderB)
							end
						end
					end
				end
			else
				for _, ButtonOverlay in pairs(Entry.Buttons) do
					if ButtonOverlay:IsShown() then
						ButtonOverlay:Hide()
					end
				end
			end
		end
	end)
end

function StaticPopups:Enable()
	-- LayoutFrame popups on this client: overlay skin only, see above
	if GameDialogMixin or C_AddOns.IsAddOnLoaded("Blizzard_StaticPopup_Game") then
		if not AddOnSkins then
			self:EnableOverlaySkin()
		end

		return
	end

	if not AddOnSkins then
		for _, Frame in pairs(StaticPopups.Popups) do
			self.Skin(Frame)
		end
	end
end

Miscellaneous.StaticPopups = StaticPopups
