local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Movers = T["Movers"]
local DamageMeter = CreateFrame("Frame")
local Skinned = setmetatable({}, {__mode = "k"})

-- Blizzard only lets you move the primary damage meter window through Edit Mode,
-- which Tukui replaces with its movers. Anchor the window to a Tukui holder instead.
-- Edit Mode re-anchors the window when layouts load, so a cheap watcher (polling,
-- not a hook on Blizzard methods) puts it back onto the holder.
function DamageMeter:Anchor()
	local Frame = _G.DamageMeter
	local Holder = self.Holder

	local Width, Height = Frame:GetSize()

	if not (issecretvalue and (issecretvalue(Width) or issecretvalue(Height))) and Width > 0 and Height > 0 then
		Holder:SetSize(Width, Height)
	end

	local _, RelativeTo = Frame:GetPoint()

	if RelativeTo ~= Holder or Frame:GetNumPoints() ~= 1 then
		Frame:ClearAllPoints()
		Frame:SetPoint("TOPLEFT", Holder, "TOPLEFT", 0, 0)
	end
end

-- Skinning: Blizzard keeps re-applying atlases and alpha on its background textures,
-- but never touches their vertex color, so a zero vertex alpha hides them for good.
-- Entries are pooled by the scroll boxes; the watcher skins each new frame once.
-- No ScrollBox callbacks: our code would run inside Blizzard's acquire and taint
-- the entry setup, which handles secret values.
local function HideRegion(Region)
	if Region then
		Region:SetVertexColor(1, 1, 1, 0)
	end
end

local function SetFont(Text)
	if Text then
		Text:SetFont(C.Medias.Font, 12, "")
		Text:SetShadowColor(0, 0, 0)
		Text:SetShadowOffset(1.25, -1.25)
	end
end

local function CreatePanel(Parent, Level)
	local Panel = CreateFrame("Frame", nil, Parent)

	Panel:SetFrameLevel(math.max(Level - 1, 0))
	Panel:CreateBackdrop("Transparent")
	Panel:CreateShadow()

	return Panel
end

-- Border from plain textures anchored to the edges. The meter's bars have a *secret* size,
-- and Blizzard's backdrop (CreateBackdrop) computes its texture coordinates from the frame
-- size: "attempt to perform arithmetic on local 'width' (a secret number value)".
local function CreateEdgeBorder(Frame)
	local R, G, B = unpack(C.General.BorderColor)
	local BR, BG, BB = unpack(C.General.BackdropColor)

	local Background = Frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	Background:SetAllPoints()
	Background:SetColorTexture(BR, BG, BB, 1)

	local Edges = {
		{"TOPLEFT", "TOPRIGHT", nil, 1},
		{"BOTTOMLEFT", "BOTTOMRIGHT", nil, 1},
		{"TOPLEFT", "BOTTOMLEFT", 1, nil},
		{"TOPRIGHT", "BOTTOMRIGHT", 1, nil},
	}

	for _, Edge in ipairs(Edges) do
		local Line = Frame:CreateTexture(nil, "BORDER")

		Line:SetColorTexture(R, G, B, 1)
		Line:SetPoint(Edge[1])
		Line:SetPoint(Edge[2])

		if Edge[3] then
			Line:SetWidth(Edge[3])
		else
			Line:SetHeight(Edge[4])
		end
	end
end

function DamageMeter:SkinEntry(Entry)
	if Skinned[Entry] then
		return
	end

	-- mark first: if anything below fails it must not be retried every 0.1s
	Skinned[Entry] = true

	local Bar = Entry.StatusBar

	Bar:SetStatusBarTexture(C.Medias.Normal)

	HideRegion(Bar.Background)
	HideRegion(Bar.BackgroundEdge)

	local Border = CreateFrame("Frame", nil, Bar)

	Border:SetOutside(Bar, 1, 1)
	Border:SetFrameLevel(math.max(Bar:GetFrameLevel() - 1, 0))
	CreateEdgeBorder(Border)

	SetFont(Bar.Name)
	SetFont(Bar.Value)
end

local function SkinEntryFrame(Entry)
	DamageMeter:SkinEntry(Entry)
end

function DamageMeter:SkinWindow(Window)
	local Container = Window.MinimizeContainer
	local SourceWindow = Container.SourceWindow

	if not Skinned[Window] then
		local Level = Window:GetFrameLevel()

		HideRegion(Window.Header)
		HideRegion(Container.Background)

		-- Header stays visible when the window is minimized, the body hides with the container
		local Header = CreatePanel(Window, Level)
		Header:SetAllPoints(Window.Header)

		local Body = CreatePanel(Container, Level)
		Body:SetPoint("TOPLEFT", Window.Header, "BOTTOMLEFT", 0, 1)
		Body:SetPoint("BOTTOMRIGHT", Window, "BOTTOMRIGHT", 0, 0)

		SetFont(Window.SessionTimer)
		SetFont(Window.DamageMeterTypeDropdown.TypeName)
		SetFont(Window.SessionDropdown.SessionName)
		SetFont(Container.NotActive)

		Skinned[Window] = true
	end

	if SourceWindow and not Skinned[SourceWindow] then
		HideRegion(SourceWindow.Background)

		CreatePanel(SourceWindow, SourceWindow:GetFrameLevel()):SetAllPoints(SourceWindow)

		Skinned[SourceWindow] = true
	end

	Container.ScrollBox:ForEachFrame(SkinEntryFrame)

	if Container.LocalPlayerEntry then
		self:SkinEntry(Container.LocalPlayerEntry)
	end

	if SourceWindow then
		SourceWindow.ScrollBox:ForEachFrame(SkinEntryFrame)
	end
end

function DamageMeter:Skin()
	local Frame = _G.DamageMeter

	if Frame.windowDataList then
		for _, WindowData in pairs(Frame.windowDataList) do
			if WindowData.sessionWindow then
				self:SkinWindow(WindowData.sessionWindow)
			end
		end
	end
end

function DamageMeter:OnUpdate(elapsed)
	self.Elapsed = (self.Elapsed or 0) + elapsed

	if self.Elapsed < 0.1 then
		return
	end

	self.Elapsed = 0
	self:Anchor()
	self:Skin()
end

function DamageMeter:Setup()
	if self.Holder or not _G.DamageMeter then
		return
	end

	local Holder = CreateFrame("Frame", "TukuiDamageMeter", UIParent)

	Holder:SetSize(400, 200)
	Holder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -12, 260)

	self.Holder = Holder
	self:Anchor()
	self:SetScript("OnUpdate", self.OnUpdate)

	Movers:RegisterFrame(Holder, "Damage Meter")
end

function DamageMeter:OnEvent(event, addon)
	if addon ~= "Blizzard_DamageMeter" then
		return
	end

	self:UnregisterEvent("ADDON_LOADED")
	self:Setup()
end

function DamageMeter:Enable()
	if _G.DamageMeter then
		self:Setup()
	else
		self:RegisterEvent("ADDON_LOADED")
		self:SetScript("OnEvent", self.OnEvent)
	end
end

Miscellaneous.DamageMeter = DamageMeter
