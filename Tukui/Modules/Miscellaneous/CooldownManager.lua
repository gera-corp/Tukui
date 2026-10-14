local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Movers = T["Movers"]
local CooldownManager = CreateFrame("Frame")

-- Blizzard's Cooldown Manager viewers can only be moved through Edit Mode, which Tukui
-- replaces with its movers. Each viewer gets a Tukui holder with a mover instead, and a
-- cheap watcher (polling, no hooks on Blizzard methods) keeps it anchored to its holder.
-- Three viewers are "bottom managed" frames that Blizzard stacks above the action bars;
-- when that layout runs it moves them back and the watcher re-anchors them.
-- Nothing else is done to the viewers on purpose: writing fields into them, or calling
-- their SetParent / the container's RemoveManagedFrame from addon code ran Blizzard's
-- viewer scripts tainted, and their aura handling then failed in combat ("attempted to
-- index a table that cannot be accessed while tainted").
local Viewers = {
	{Name = "EssentialCooldownViewer", Holder = "TukuiEssentialCooldowns", Mover = "Cooldowns (Essential)", Y = 330, FadeOnCooldown = true, CombatOnly = true},
	{Name = "UtilityCooldownViewer", Holder = "TukuiUtilityCooldowns", Mover = "Cooldowns (Utility)", Y = 290, FadeOnCooldown = true, CombatOnly = true},
	{Name = "BuffIconCooldownViewer", Holder = "TukuiBuffIconCooldowns", Mover = "Cooldowns (Buff Icons)", Y = 380},
	{Name = "BuffBarCooldownViewer", Holder = "TukuiBuffBarCooldowns", Mover = "Cooldowns (Buff Bars)", Y = 430, Bars = true},
}

-- Alpha of a spell icon while its cooldown runs (back to 1 once it's ready)
local COOLDOWN_ALPHA = 0.35

-- CombatOnly viewers are invisible out of combat. Done with the viewer's alpha: Blizzard's
-- own "in combat only" visibility lives in Edit Mode (replaced by Tukui's movers), and
-- Hide()/Show() from addon code would run the viewer's OnHide/OnShow scripts tainted.
-- (Blizzard sets the viewer alpha too, to hide it while a vehicle bar is up: that wins
-- out of combat only for a moment, the watcher puts ours back.)
local function UpdateCombatVisibility(Viewer)
	local Alpha = (InCombatLockdown() or UnitAffectingCombat("player")) and 1 or 0

	if Viewer:GetAlpha() ~= Alpha then
		Viewer:SetAlpha(Alpha)
	end
end

local function IsSecret(Value)
	return issecretvalue and issecretvalue(Value)
end

-- Tukui look. Nothing is written into Blizzard's item frames (no fields, no Toolkit calls
-- on them, those store fields): our borders/shadows are separate child frames and textures,
-- and the skinned items are remembered in our own weak table. Items are pooled, each one
-- is skinned once when the watcher first sees it.
local Skinned = setmetatable({}, {__mode = "k"})
local ICON_OVERLAY_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"

local function PixelSize()
	return T.Toolkit and T.Toolkit.Functions.Scale(1) or 1
end

-- 1px dark edges over the icon, and Tukui's shadow outside
local function AddBorder(Parent, Region, Level)
	local Border = CreateFrame("Frame", nil, Parent)
	local Size = PixelSize()
	local R, G, B = unpack(C.General.BorderColor)

	Border:SetAllPoints(Region)
	Border:SetFrameLevel(Level)

	for _, Edge in ipairs({{"TOPLEFT", "TOPRIGHT"}, {"BOTTOMLEFT", "BOTTOMRIGHT"}, {"TOPLEFT", "BOTTOMLEFT"}, {"TOPRIGHT", "BOTTOMRIGHT"}}) do
		local Line = Border:CreateTexture(nil, "OVERLAY", nil, 7)

		Line:SetColorTexture(R, G, B, 1)
		Line:SetPoint(Edge[1])
		Line:SetPoint(Edge[2])

		if Edge[1] == "TOPLEFT" and Edge[2] == "BOTTOMLEFT" or Edge[1] == "TOPRIGHT" then
			Line:SetWidth(Size)
		else
			Line:SetHeight(Size)
		end
	end

	Border:CreateShadow()

	return Border
end

-- Square, cropped icon without Blizzard's round mask and frame
local function SkinIcon(Frame, Icon)
	for i = Icon:GetNumMaskTextures(), 1, -1 do
		Icon:RemoveMaskTexture(Icon:GetMaskTexture(i))
	end

	Icon:SetTexCoord(unpack(T.IconCoord))

	for _, Region in ipairs({Frame:GetRegions()}) do
		if Region.GetAtlas and Region:GetAtlas() == ICON_OVERLAY_ATLAS then
			Region:SetAlpha(0)
		end
	end

	AddBorder(Frame, Icon, Frame:GetFrameLevel() + 2)
end

local function SetFont(FontString, Size)
	if FontString and FontString.SetFontTemplate then
		FontString:SetFontTemplate(C.Medias.Font, Size)
	end
end

-- the cooldown's countdown text
local function SkinCountdown(Cooldown, Size)
	if Cooldown then
		for _, Region in ipairs({Cooldown:GetRegions()}) do
			if Region.GetText then
				SetFont(Region, Size)
			end
		end
	end
end

local function SkinIconItem(Item)
	local Size = Item:GetWidth()
	local FontSize = (IsSecret(Size) or Size >= 40) and 14 or 12

	if Item.Icon then
		SkinIcon(Item, Item.Icon)
	end

	SkinCountdown(Item.Cooldown, FontSize)
	SetFont(Item.ChargeCount and Item.ChargeCount.Current, FontSize)
	SetFont(Item.Applications and Item.Applications.Applications, FontSize)
end

local function SkinBarItem(Item)
	local IconFrame, Bar = Item.Icon, Item.Bar

	if IconFrame and IconFrame.Icon then
		SkinIcon(IconFrame, IconFrame.Icon)
		SetFont(IconFrame.Applications, 12)
	end

	if Bar then
		Bar:SetStatusBarTexture(C.Medias.Normal)

		if Bar.BarBG then
			Bar.BarBG:SetAlpha(0)
		end

		if Bar.Pip then
			Bar.Pip:SetAlpha(0)
		end

		-- dark background with Tukui's border behind the bar
		local Background = CreateFrame("Frame", nil, Item)

		Background:SetAllPoints(Bar)
		Background:SetFrameLevel(math.max(Bar:GetFrameLevel() - 1, 0))
		Background:CreateBackdrop()
		Background:CreateShadow()

		SetFont(Bar.Name, 12)
		SetFont(Bar.Duration, 12)
	end
end

local function SkinItems(Viewer, Bars)
	local Pool = Viewer.itemFramePool

	if not Pool then
		return
	end

	for Item in Pool:EnumerateActive() do
		if not Skinned[Item] then
			Skinned[Item] = true

			if Bars then
				SkinBarItem(Item)
			else
				SkinIconItem(Item)
			end
		end
	end
end

-- Spells on cooldown are faded, from the spell's cooldown duration object
-- (C_Spell.GetSpellCooldownDuration). Blizzard's own item flags were stale or secret.
-- The global cooldown made every icon blink after each cast, and in combat the remaining
-- time is secret, so it can't be compared with the GCD length in Lua. A curve turns the
-- remaining time into the alpha inside the client instead (secret in, secret out, and
-- SetAlpha accepts secret values): more than GCD_LENGTH left -> faded, less -> opaque.
-- Side effect: an icon lights up GCD_LENGTH before its cooldown is ready.
local GCD_LENGTH = 1.6
local AlphaCurve

local function GetAlphaCurve()
	if not AlphaCurve and C_CurveUtil and C_CurveUtil.CreateCurve then
		AlphaCurve = C_CurveUtil.CreateCurve()
		AlphaCurve:SetType(Enum.LuaCurveType.Linear)
		AlphaCurve:AddPoint(0, 1)
		AlphaCurve:AddPoint(GCD_LENGTH - 0.1, 1)
		AlphaCurve:AddPoint(GCD_LENGTH, COOLDOWN_ALPHA)
		AlphaCurve:AddPoint(86400, COOLDOWN_ALPHA)
	end

	return AlphaCurve
end

local function FadeItems(Viewer)
	local Pool = Viewer.itemFramePool
	local Curve = GetAlphaCurve()

	if not Pool or not Curve or not (C_Spell and C_Spell.GetSpellCooldownDuration) then
		return
	end

	for Item in Pool:EnumerateActive() do
		local SpellID = Item.GetSpellID and Item:GetSpellID()
		local Duration = SpellID and not IsSecret(SpellID) and C_Spell.GetSpellCooldownDuration(SpellID)
		-- (no "Alpha or 1": a secret number can't be tested)
		if Duration then
			Item:SetAlpha(Duration:EvaluateRemainingDuration(Curve))
		else
			Item:SetAlpha(1)
		end
	end
end

function CooldownManager:Anchor(Info)
	local Viewer = _G[Info.Name]
	local Holder = Info.Frame

	if not Viewer or not Holder then
		return
	end

	-- the mover is sized like the viewer (which grows with the number of tracked spells)
	local Width, Height = Viewer:GetSize()

	if not (IsSecret(Width) or IsSecret(Height)) and Width > 1 and Height > 1 then
		local HolderWidth, HolderHeight = Holder:GetSize()

		if math.abs(HolderWidth - Width) > 0.5 or math.abs(HolderHeight - Height) > 0.5 then
			Holder:SetSize(Width, Height)
		end
	end

	local Point, RelativeTo = Viewer:GetPoint(1)

	if Point ~= "CENTER" or RelativeTo ~= Holder or Viewer:GetNumPoints() ~= 1 then
		-- Base versions skip Edit Mode's snapping logic in the overrides
		local ClearAllPoints = Viewer.ClearAllPointsBase or Viewer.ClearAllPoints
		local SetPoint = Viewer.SetPointBase or Viewer.SetPoint

		ClearAllPoints(Viewer)
		SetPoint(Viewer, "CENTER", Holder, "CENTER", 0, 0)
	end
end

function CooldownManager:OnUpdate(Elapsed)
	-- Position every frame: Blizzard's bottom layout moves the viewers back often, and a
	-- slower check let a frame be drawn at the old place (the viewers blinked)
	for _, Info in ipairs(Viewers) do
		self:Anchor(Info)
	end

	self.Elapsed = (self.Elapsed or 0) + Elapsed

	if self.Elapsed < 0.1 then
		return
	end

	self.Elapsed = 0

	for _, Info in ipairs(Viewers) do
		local Viewer = _G[Info.Name]

		if Viewer and Info.CombatOnly then
			UpdateCombatVisibility(Viewer)
		end

		if Viewer then
			SkinItems(Viewer, Info.Bars)
		end

		if Info.FadeOnCooldown and Viewer and Viewer:IsVisible() then
			FadeItems(Viewer)
		end
	end
end

function CooldownManager:Enable()
	if self.Enabled or not _G.EssentialCooldownViewer then
		return
	end

	self.Enabled = true

	for _, Info in ipairs(Viewers) do
		if _G[Info.Name] then
			local Holder = CreateFrame("Frame", Info.Holder, UIParent)

			Holder:SetSize(200, 40)
			Holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, Info.Y)

			Info.Frame = Holder

			Movers:RegisterFrame(Holder, Info.Mover)
			self:Anchor(Info)
		end
	end

	self:SetScript("OnUpdate", self.OnUpdate)
end

Miscellaneous.CooldownManager = CooldownManager
