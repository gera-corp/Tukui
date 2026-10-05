local T, C, L = unpack((select(2, ...)))
local Inventory = T["Inventory"]
local GroupLoot = CreateFrame("Frame")

-- Lib Globals
local select = select
local unpack = unpack
local pairs = pairs

-- WoW Globals
local NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES or 4

-- Locals
GroupLoot.PreviousFrame = {}

function GroupLoot:TestGroupLootFrames()
	GetLootRollItemInfo = function(RollID)
		Texture = 135226
		Name = "Atiesh, Greatstaff of the Guardian"
		Count = RollID
		Quality	= RollID + 1
		BindOnPickUp = math.random(0, 1) > 0.5
		CanNeed	= true
		CanGreed = true
		ReasonNeed = 0
		ReasonGreed = 0

		return Texture, Name, Count, Quality, BindOnPickUp, CanNeed, CanGreed, ReasonNeed, ReasonGreed
	end

	function GroupLootFrame_OnUpdate() end

	for i = 1, NUM_GROUP_LOOT_FRAMES do
		GroupLootFrame_OpenNewFrame(i, 300)
		_G["GroupLootFrame" .. i].Timer:SetValue(math.random(8, 300))
	end
end

function GroupLoot:SkinGroupLoot(Frame)
    if (Frame.IsSkinned) then
		return
	end

	Frame:StripTextures()

	if (Frame.Timer.Background) then
		Frame.Timer.Background:Kill()
	end

	if (_G[Frame:GetName().."NameFrame"] or _G[Frame:GetName().."Corner"]) then
		_G[Frame:GetName().."NameFrame"]:Kill()
		_G[Frame:GetName().."Corner"]:Kill()
	end

	Frame.OverlayContrainerFrame = CreateFrame("Frame", nil, Frame)
	Frame.OverlayContrainerFrame:SetFrameLevel(Frame:GetFrameLevel() - 1)
	Frame.OverlayContrainerFrame:SetSize(233, 32)
	Frame.OverlayContrainerFrame:SetPoint("CENTER", Frame, 0, 0)
	Frame.OverlayContrainerFrame:CreateBackdrop("Transparent")
	Frame.OverlayContrainerFrame:CreateShadow()

	Frame.Name:ClearAllPoints()
	Frame.Name:SetPoint("LEFT", Frame.OverlayContrainerFrame, 6, 0)
	Frame.Name:SetFontTemplate(C.Medias.Font, 12)

	Frame.IconFrame.Count:ClearAllPoints()
	Frame.IconFrame.Count:SetPoint("BOTTOMRIGHT", -2, 4)
	Frame.IconFrame.Count:SetFontTemplate(C.Medias.Font, 12)

	Frame.Timer:CreateBackdrop()
	Frame.Timer:CreateShadow()
	Frame.Timer:StripTextures(true)
	Frame.Timer:SetStatusBarColor(1, 0.82, 0, 0.50)
	Frame.Timer:SetStatusBarTexture(C.Medias.Blank)
	Frame.Timer:ClearAllPoints()
	Frame.Timer:SetSize(Frame.OverlayContrainerFrame:GetWidth() + 1, 8)
	Frame.Timer:SetPoint("BOTTOMLEFT", Frame.OverlayContrainerFrame, 0, -12)

	Frame.Timer.Backdrop:SetFrameStrata("BACKGROUND")
	Frame.Timer.Backdrop:SetFrameLevel(0)

	Frame.IconFrame:CreateBackdrop()
	Frame.IconFrame:CreateShadow()
	Frame.IconFrame:SetSize(44, 44)
	Frame.IconFrame:ClearAllPoints()
	Frame.IconFrame:SetPoint("LEFT", Frame.OverlayContrainerFrame, -48, -6)

	Frame.IconFrame.Icon:SetTexCoord(unpack(T.IconCoord))
	Frame.IconFrame.Icon:SetInside()
	Frame.IconFrame.Icon:SetSnapToPixelGrid(false)
	Frame.IconFrame.Icon:SetTexelSnappingBias(0)

	if Frame.PassButton then
		Frame.PassButton:SetSize(24, 24)
		Frame.PassButton:ClearAllPoints()
		Frame.PassButton:SetPoint("RIGHT", Frame.OverlayContrainerFrame, 0, 0)
		Frame.PassButton:SkinCloseButton(nil, nil, 12)
	end

	if Frame.GreedButton then
		Frame.GreedButton:SetSize(24, 24)
		Frame.GreedButton:ClearAllPoints()
		Frame.GreedButton:SetPoint("LEFT", Frame.PassButton or Frame.OverlayContrainerFrame, Frame.PassButton and -24 or 0, -2)
	end

	if Frame.NeedButton then
		Frame.NeedButton:SetSize(24, 24)
		Frame.NeedButton:ClearAllPoints()
		Frame.NeedButton:SetPoint("LEFT", Frame.GreedButton or Frame.OverlayContrainerFrame, -24, 1)
	end

	-- This client keeps the roll buttons in Frame.LootButtonContainer, laid out 2x2 (the
	-- greed coin sat on the timer bar): put them in one row at the right of the panel.
	local Container = Frame.LootButtonContainer

	if Container and not Frame.PassButton then
		local Pass, Greed, Transmog, Need = Container.PassButton, Container.GreedButton, Container.TransmogButton, Container.NeedButton
		local Previous

		for _, Button in ipairs({Pass, Greed, Need}) do
			Button:SetSize(24, 24)
			Button:ClearAllPoints()

			if Previous then
				Button:SetPoint("RIGHT", Previous, "LEFT", -2, 0)
			else
				Button:SetPoint("RIGHT", Frame.OverlayContrainerFrame, "RIGHT", -4, 0)
			end

			Previous = Button
		end

		-- transmog replaces greed for items you can collect
		if Transmog then
			Transmog:SetSize(24, 24)
			Transmog:ClearAllPoints()
			Transmog:SetPoint("CENTER", Greed, "CENTER", 0, 0)
		end

		-- keep the item name clear of the buttons
		Frame.Name:SetPoint("RIGHT", Need, "LEFT", -4, 0)
		Frame.Name:SetJustifyH("LEFT")
		Frame.Name:SetWordWrap(false)
	end

	if not T.Retail then
		hooksecurefunc(Frame, "SetBackdrop", Frame.ClearBackdrop)
	end

	Frame.IsSkinned = true
end

function GroupLoot:UpdateGroupLootContainer()
	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local Frame = _G["GroupLootFrame" .. i]
		local Mover = GroupLoot.Mover

		Frame:ClearAllPoints()

		if (i == 1) then
			Frame:SetPoint("CENTER", Mover, 24, -32)
		else

			Frame:SetPoint("BOTTOM", GroupLoot.PreviousFrame, "BOTTOM", 0, -52)
		end

		GroupLoot.PreviousFrame = Frame
	end
end

function GroupLoot:SkinFrames()
	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local Frame = _G["GroupLootFrame" .. i]

		self:SkinGroupLoot(Frame)
	end
end

function GroupLoot:AddMover()
	self.Mover = CreateFrame("Frame", "TukuiGroupLoot", UIParent)
	self.Mover:SetPoint("TOP", UIParent, 0, 0)
	self.Mover:SetSize(284, 22)

	T.Movers:RegisterFrame(self.Mover, "Group Loot")
end

function GroupLoot:AddHooks()
	-- So we can move the Group Loot Container.
	if not T.Retail then
		UIPARENT_MANAGED_FRAME_POSITIONS.GroupLootContainer = nil
	end

	hooksecurefunc("GroupLootContainer_Update", self.UpdateGroupLootContainer)
end

-- Who rolled what: a counter on every roll button, names in its tooltip.
-- Source 1: the loot history (LOOT_HISTORY_UPDATE_DROP, per player roll state).
-- Source 2: the "X has selected Need for: [item]" loot messages, for rolls the history misses.
local RollTypes = {"Need", "Greed", "Transmog", "Pass"}
local Rolls = {} -- [rollID] = {Need = {[name] = class}, ...}
local RollItems = {} -- [rollID] = itemID
local Drops = {} -- ["encounterID:lootListKey"] = rollID
local RollInfos = {} -- [rollID] = {Texture, Name, Quality, EndTime}
local Winners = {} -- [rollID] = {Name, Class, Type, Roll} or {AllPassed = true}
local MessagePatterns

local IsSecret = function(Value)
	return issecretvalue and issecretvalue(Value)
end

local function GetItemID(Link)
	return type(Link) == "string" and not IsSecret(Link) and tonumber(Link:match("item:(%d+)"))
end

local function GetButton(Frame, Type)
	local Key = Type.."Button"

	return Frame[Key] or (Frame.LootButtonContainer and Frame.LootButtonContainer[Key])
end

local function ForEachLootFrame(Callback)
	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local Frame = _G["GroupLootFrame"..i]

		if Frame then
			Callback(Frame)
		end
	end
end

local function UpdateCounters()
	ForEachLootFrame(function(Frame)
		local Data = Frame.rollID and Rolls[Frame.rollID]

		for _, Type in ipairs(RollTypes) do
			local Button = GetButton(Frame, Type)

			if Button and Button.TukuiRollCount then
				local Count = 0

				if Data and Data[Type] then
					for _ in pairs(Data[Type]) do
						Count = Count + 1
					end
				end

				Button.TukuiRollCount:SetText(Count > 0 and Count or "")
			end
		end
	end)

	if GroupLoot.RefreshTrackers then
		GroupLoot:RefreshTrackers()
	end
end

local function SetRoll(RollID, Type, Name, Class)
	local Data = Rolls[RollID]

	if not Data then
		Data = {}
		Rolls[RollID] = Data
	end

	-- a player has one choice per roll
	for _, Other in ipairs(RollTypes) do
		if Data[Other] then
			Data[Other][Name] = nil
		end
	end

	Data[Type] = Data[Type] or {}
	Data[Type][Name] = Class or false
end

-- Active roll showing this item; with two identical drops take the one without this player yet
local function FindRoll(ItemID, Name)
	local Found

	for RollID, RollItemID in pairs(RollItems) do
		if RollItemID == ItemID then
			local Data = Rolls[RollID]
			local HasPlayer = false

			if Data and Name then
				for _, Type in ipairs(RollTypes) do
					if Data[Type] and Data[Type][Name] ~= nil then
						HasPlayer = true
					end
				end
			end

			if not HasPlayer then
				return RollID
			end

			Found = Found or RollID
		end
	end

	return Found
end

local HistoryStates = {}

if Enum and Enum.EncounterLootDropRollState then
	local State = Enum.EncounterLootDropRollState

	HistoryStates[State.NeedMainSpec] = "Need"
	HistoryStates[State.NeedOffSpec] = "Need"
	HistoryStates[State.Transmog] = "Transmog"
	HistoryStates[State.Greed] = "Greed"
	HistoryStates[State.Pass] = "Pass"
end

function GroupLoot:OnHistoryDrop(EncounterID, LootListKey)
	local Ok, Info = pcall(C_LootHistory.GetSortedInfoForDrop, EncounterID, LootListKey)

	if not Ok or type(Info) ~= "table" or type(Info.rollInfos) ~= "table" then
		return
	end

	local Key = EncounterID..":"..LootListKey
	local RollID = Drops[Key]

	if not RollID or not RollItems[RollID] then
		RollID = FindRoll(GetItemID(Info.itemHyperlink))
		Drops[Key] = RollID
	end

	if not RollID then
		return
	end

	for _, RollInfo in ipairs(Info.rollInfos) do
		local Name, Class, State = RollInfo.playerName, RollInfo.playerClass, RollInfo.state

		if not (IsSecret(Name) or IsSecret(Class) or IsSecret(State)) and Name and HistoryStates[State] then
			SetRoll(RollID, HistoryStates[State], Ambiguate(Name, "none"), Class)
		end
	end

	-- result of the roll
	local Winner = Info.winner

	if Info.allPassed and not IsSecret(Info.allPassed) then
		Winners[RollID] = {AllPassed = true}
	elseif type(Winner) == "table" and Winner.playerName and not IsSecret(Winner.playerName) then
		local Roll = Winner.roll

		Winners[RollID] = {
			Name = Ambiguate(Winner.playerName, "none"),
			Class = not IsSecret(Winner.playerClass) and Winner.playerClass or nil,
			Type = not IsSecret(Winner.state) and HistoryStates[Winner.state] or nil,
			Roll = not IsSecret(Roll) and Roll or nil,
		}
	end

	UpdateCounters()
end

-- "%s has selected Need for: %s" -> pattern with (name) and (item) captures in the right order
local function MakePattern(Format)
	if type(Format) ~= "string" then
		return
	end

	local NameFirst = true
	local Position1, Position2 = Format:find("%%1%$s"), Format:find("%%2%$s")

	if Position1 and Position2 and Position2 < Position1 then
		NameFirst = false
	end

	local Pattern = Format:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
	-- "$" is escaped by now, so "%1$s" reads "%1%$s"
	Pattern = Pattern:gsub("%%%d%%%$s", "(.+)"):gsub("%%s", "(.+)")

	return "^"..Pattern.."$", NameFirst
end

local function GetMessagePatterns()
	if MessagePatterns then
		return MessagePatterns
	end

	MessagePatterns = {}

	for Type, Global in pairs({Need = "LOOT_ROLL_NEED", Greed = "LOOT_ROLL_GREED", Transmog = "LOOT_ROLL_TRANSMOG", Pass = "LOOT_ROLL_PASSED"}) do
		local Pattern, NameFirst = MakePattern(_G[Global])

		if Pattern then
			tinsert(MessagePatterns, {Type = Type, Pattern = Pattern, NameFirst = NameFirst})
		end

		-- "You have selected Need for: %s"
		local SelfPattern = MakePattern(_G[Global.."_SELF"])

		if SelfPattern then
			tinsert(MessagePatterns, {Type = Type, Pattern = SelfPattern, Self = true})
		end
	end

	return MessagePatterns
end

function GroupLoot:OnLootMessage(Message)
	if type(Message) ~= "string" or IsSecret(Message) then
		return
	end

	if GroupLoot:OnWinnerMessage(Message) then
		return
	end

	for _, Entry in ipairs(GetMessagePatterns()) do
		local A, B = Message:match(Entry.Pattern)

		if A then
			local Name, Link

			if Entry.Self then
				Name, Link = T.MyName, A
			elseif Entry.NameFirst then
				Name, Link = A, B
			else
				Name, Link = B, A
			end

			-- names in loot messages can be links: |Hplayer:Name|h[Name]|h
			Name = Name and (Name:match("|h%[?(.-)%]?|h") or Name)

			local RollID = Name and FindRoll(GetItemID(Link), Name)

			if RollID then
				local Class
				local Units = {"player"}
				local Prefix = IsInRaid() and "raid" or "party"

				for i = 1, GetNumGroupMembers() do
					tinsert(Units, Prefix..i)
				end

				for _, Unit in ipairs(Units) do
					-- names here are "Name Surname": compare with both parts
					local First, Second = UnitName(Unit)

					if First and not IsSecret(First) and not IsSecret(Second) then
						if First == Name or (Second and Second ~= "" and (First.." "..Second == Name or First.."-"..Second == Name)) then
							local _, UnitClassValue = UnitClass(Unit)

							if not IsSecret(UnitClassValue) then
								Class = UnitClassValue
							end
						end
					end
				end

				-- the loot history (if it knows this roll) has the class already
				local Data = Rolls[RollID]
				local Known = Data and Data[Entry.Type] and Data[Entry.Type][Name]

				SetRoll(RollID, Entry.Type, Name, Known or Class)
				UpdateCounters()
			end

			return
		end
	end
end

function GroupLoot:OnRollEvent(event, ...)
	if event == "START_LOOT_ROLL" then
		local RollID = ...

		local RollTime = select(2, ...)
		local Texture, Name, _, Quality = GetLootRollItemInfo(RollID)

		RollItems[RollID] = GetItemID(GetLootRollItemLink(RollID))
		Rolls[RollID] = Rolls[RollID] or {}
		RollInfos[RollID] = {
			Texture = Texture,
			Name = Name,
			Quality = Quality,
			EndTime = GetTime() + (tonumber(RollTime) or 60000) / 1000,
		}

		C_Timer.After(0, UpdateCounters)
	elseif event == "LOOT_HISTORY_UPDATE_DROP" then
		GroupLoot:OnHistoryDrop(...)
	elseif event == "CHAT_MSG_LOOT" then
		GroupLoot:OnLootMessage(...)
	elseif event == "CANCEL_LOOT_ROLL" then
		local RollID = ...

		-- Blizzard's frame closes as soon as we chose (or the roll ended): keep showing the
		-- roll on a Tukui bar until it's over and the winner is known
		GroupLoot:ShowTracker(RollID)

		UpdateCounters()
	end
end

local function AddRollTooltip(Button)
	local Frame = Button:GetParent()

	while Frame and not Frame.rollID do
		Frame = Frame:GetParent()
	end

	local Data = Frame and Rolls[Frame.rollID]
	local Names = Data and Data[Button.TukuiRollType]

	if not Names or not next(Names) then
		return
	end

	GameTooltip:AddLine(" ")

	for Name, Class in pairs(Names) do
		local Color = Class and T.Colors.class[Class]

		if Color then
			GameTooltip:AddLine(Name, Color[1], Color[2], Color[3])
		else
			GameTooltip:AddLine(Name, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

function GroupLoot:AddRollTracking()
	ForEachLootFrame(function(Frame)
		for _, Type in ipairs(RollTypes) do
			local Button = GetButton(Frame, Type)

			if Button and not Button.TukuiRollCount then
				Button.TukuiRollType = Type
				Button.TukuiRollCount = Button:CreateFontString(nil, "OVERLAY")
				Button.TukuiRollCount:SetFontTemplate(C.Medias.Font, 13)
				-- top right corner: the bottom one runs into the timer bar below the buttons
				Button.TukuiRollCount:SetPoint("TOPRIGHT", Button, "TOPRIGHT", 1, 4)
				Button.TukuiRollCount:SetDrawLayer("OVERLAY", 7)
				Button.TukuiRollCount:SetTextColor(1, 0.82, 0)

				Button:HookScript("OnEnter", AddRollTooltip)
			end
		end

		Frame:HookScript("OnShow", function() C_Timer.After(0, UpdateCounters) end)
	end)

	local Tracker = CreateFrame("Frame")

	for _, Event in ipairs({"START_LOOT_ROLL", "CANCEL_LOOT_ROLL", "LOOT_HISTORY_UPDATE_DROP", "CHAT_MSG_LOOT"}) do
		pcall(Tracker.RegisterEvent, Tracker, Event)
	end

	Tracker:SetScript("OnEvent", GroupLoot.OnRollEvent)
end

-- Roll tracker bars: the roll stays visible after our choice, with the counts, the timer
-- and finally the winner.
local Ru = GetLocale() == "ruRU"
local TextWinner = Ru and "Досталось:" or "Won by:"
local TextAllPassed = Ru and "Все отказались" or "Everyone passed"
local TextEnded = Ru and "Розыгрыш окончен" or "Roll ended"
local TypeIcons = {
	Need = "lootroll-toast-icon-need-up",
	Greed = "lootroll-toast-icon-greed-up",
	Transmog = "lootroll-toast-icon-transmog-up",
	Pass = "lootroll-toast-icon-pass-up",
}
local ShowWinnerFor = 8
local Trackers = {} -- shown bars, in order
local TrackerPool = {}

local function TypeMarkup(Type, Size)
	return TypeIcons[Type] and CreateAtlasMarkup(TypeIcons[Type], Size or 14, Size or 14) or ""
end

local function ColoredName(Name, Class)
	local Color = Class and T.Colors.class[Class]

	if Color then
		return format("|cff%02x%02x%02x%s|r", Color[1] * 255, Color[2] * 255, Color[3] * 255, Name)
	end

	return Name
end

-- "%1$s won: %3$s (Need - %2$d)" -> pattern + which argument each capture is
local function MakeArgPattern(Format)
	if type(Format) ~= "string" then
		return
	end

	local Order, Next = {}, 1
	local Pattern = Format:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")

	Pattern = Pattern:gsub("%%(%d?)%%?%$?([sd])", function(Index, Kind)
		Index = tonumber(Index)

		if not Index then
			Index = Next
			Next = Next + 1
		end

		tinsert(Order, Index)

		return Kind == "d" and "(%d+)" or "(.+)"
	end)

	return "^"..Pattern.."$", Order
end

local WinnerPatterns

local function GetWinnerPatterns()
	if WinnerPatterns then
		return WinnerPatterns
	end

	WinnerPatterns = {}

	-- {global string, who (arg index or "self"), item arg, roll arg, type}
	local List = {
		{"LOOT_ROLL_WON_NO_SPAM_NEED", 1, 3, 2, "Need"},
		{"LOOT_ROLL_WON_NO_SPAM_GREED", 1, 3, 2, "Greed"},
		{"LOOT_ROLL_WON_NO_SPAM_TRANSMOG", 1, 3, 2, "Transmog"},
		{"LOOT_ROLL_YOU_WON_NO_SPAM_NEED", "self", 2, 1, "Need"},
		{"LOOT_ROLL_YOU_WON_NO_SPAM_GREED", "self", 2, 1, "Greed"},
		{"LOOT_ROLL_YOU_WON_NO_SPAM_TRANSMOG", "self", 2, 1, "Transmog"},
		{"LOOT_ROLL_WON", 1, 2},
		{"LOOT_ROLL_YOU_WON", "self", 1},
		{"LOOT_ROLL_ALL_PASSED", nil, 1},
	}

	for _, Entry in ipairs(List) do
		local Pattern, Order = MakeArgPattern(_G[Entry[1]])

		if Pattern then
			tinsert(WinnerPatterns, {Pattern = Pattern, Order = Order, Who = Entry[2], Item = Entry[3], Roll = Entry[4], Type = Entry[5], AllPassed = Entry[1] == "LOOT_ROLL_ALL_PASSED"})
		end
	end

	return WinnerPatterns
end

function GroupLoot:OnWinnerMessage(Message)
	for _, Entry in ipairs(GetWinnerPatterns()) do
		local Captures = {Message:match(Entry.Pattern)}

		if #Captures > 0 then
			local Args = {}

			for i, Index in ipairs(Entry.Order) do
				Args[Index] = Captures[i]
			end

			local ItemID = GetItemID(Args[Entry.Item])
			local RollID

			-- the roll with this item that has no result yet
			for ID, RollItemID in pairs(RollItems) do
				if RollItemID == ItemID and not Winners[ID] then
					RollID = ID
				end
			end

			if not RollID then
				return true
			end

			if Entry.AllPassed then
				Winners[RollID] = {AllPassed = true}
			else
				local Name = Entry.Who == "self" and T.MyName or Args[Entry.Who]

				Name = Name and (Name:match("|h%[?(.-)%]?|h") or Name)

				-- class from the rolls we saw
				local Class

				for _, Names in pairs(Rolls[RollID] or {}) do
					if Names[Name] then
						Class = Names[Name]
					end
				end

				if Entry.Who == "self" then
					Class = T.MyClass
				end

				Winners[RollID] = {Name = Name, Class = Class, Type = Entry.Type, Roll = tonumber(Entry.Roll and Args[Entry.Roll])}
			end

			UpdateCounters()

			return true
		end
	end
end

local function ReleaseTracker(Bar)
	local RollID = Bar.RollID

	Bar:Hide()
	Bar.RollID = nil

	for i, Other in ipairs(Trackers) do
		if Other == Bar then
			tremove(Trackers, i)
			break
		end
	end

	tinsert(TrackerPool, Bar)

	if RollID then
		Rolls[RollID] = nil
		RollItems[RollID] = nil
		RollInfos[RollID] = nil
		Winners[RollID] = nil
	end

	GroupLoot:LayoutTrackers()
end

local function Tracker_OnUpdate(self)
	local Info = RollInfos[self.RollID]

	if not Info then
		ReleaseTracker(self)

		return
	end

	local Now = GetTime()
	local Left = max(0, Info.EndTime - Now)

	self.Timer:SetValue(Left)

	if Winners[self.RollID] then
		self.WinnerTime = self.WinnerTime or Now

		if Now - self.WinnerTime > ShowWinnerFor then
			ReleaseTracker(self)
		end
	elseif Left <= 0 then
		-- no result reported: give the history/chat a moment, then give up
		self.EndedTime = self.EndedTime or Now

		if Now - self.EndedTime > 5 then
			self.Status:SetText("|cff999999"..TextEnded.."|r")

			if Now - self.EndedTime > 8 then
				ReleaseTracker(self)
			end
		end
	end
end

local function Tracker_OnEnter(self)
	local Data = Rolls[self.RollID]

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	local Info = RollInfos[self.RollID]

	if Info and Info.Name then
		local Color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[Info.Quality]

		GameTooltip:AddLine(Info.Name, Color and Color.r or 1, Color and Color.g or 1, Color and Color.b or 1)
	end

	for _, Type in ipairs(RollTypes) do
		local Names = Data and Data[Type]

		if Names and next(Names) then
			local List = {}

			for Name, Class in pairs(Names) do
				tinsert(List, ColoredName(Name, Class))
			end

			GameTooltip:AddLine(TypeMarkup(Type, 16).." "..table.concat(List, ", "), 1, 1, 1, true)
		end
	end

	GameTooltip:Show()
end

local function CreateTracker()
	local Bar = CreateFrame("Frame", nil, UIParent)

	Bar:SetSize(233, 32)
	Bar:SetFrameStrata("DIALOG")
	Bar:CreateBackdrop("Transparent")
	Bar:CreateShadow()
	Bar:EnableMouse(true)
	Bar:SetScript("OnEnter", Tracker_OnEnter)
	Bar:SetScript("OnLeave", GameTooltip_Hide)
	Bar:SetScript("OnUpdate", Tracker_OnUpdate)

	Bar.Icon = CreateFrame("Frame", nil, Bar)
	Bar.Icon:SetSize(32, 32)
	Bar.Icon:SetPoint("RIGHT", Bar, "LEFT", -4, 0)
	Bar.Icon:CreateBackdrop()
	Bar.Icon:CreateShadow()
	Bar.Icon.Texture = Bar.Icon:CreateTexture(nil, "ARTWORK")
	Bar.Icon.Texture:SetInside(Bar.Icon.Backdrop)
	Bar.Icon.Texture:SetTexCoord(unpack(T.IconCoord))

	Bar.Name = Bar:CreateFontString(nil, "OVERLAY")
	Bar.Name:SetFontTemplate(C.Medias.Font, 12)
	Bar.Name:SetPoint("TOPLEFT", Bar, "TOPLEFT", 6, -3)
	Bar.Name:SetPoint("RIGHT", Bar, "RIGHT", -6, 0)
	Bar.Name:SetJustifyH("LEFT")
	Bar.Name:SetWordWrap(false)

	Bar.Status = Bar:CreateFontString(nil, "OVERLAY")
	Bar.Status:SetFontTemplate(C.Medias.Font, 12)
	Bar.Status:SetPoint("BOTTOMLEFT", Bar, "BOTTOMLEFT", 6, 3)
	Bar.Status:SetPoint("RIGHT", Bar, "RIGHT", -6, 0)
	Bar.Status:SetJustifyH("LEFT")
	Bar.Status:SetWordWrap(false)

	Bar.Timer = CreateFrame("StatusBar", nil, Bar)
	Bar.Timer:SetSize(233, 6)
	Bar.Timer:SetPoint("TOPLEFT", Bar, "BOTTOMLEFT", 0, -4)
	Bar.Timer:SetStatusBarTexture(C.Medias.Blank)
	Bar.Timer:SetStatusBarColor(1, 0.82, 0, 0.5)
	Bar.Timer:CreateBackdrop()
	Bar.Timer:CreateShadow()

	return Bar
end

function GroupLoot:LayoutTrackers()
	-- below the lowest Blizzard roll frame that is still shown
	local Lowest = 0

	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local Frame = _G["GroupLootFrame"..i]

		if Frame and Frame:IsShown() then
			Lowest = i
		end
	end

	for i, Bar in ipairs(Trackers) do
		local Slot = Lowest + i - 1

		Bar:ClearAllPoints()
		Bar:SetPoint("CENTER", GroupLoot.Mover, "CENTER", 24, -32 - Slot * 52)
	end
end

function GroupLoot:RefreshTrackers()
	GroupLoot:LayoutTrackers()

	for _, Bar in ipairs(Trackers) do
		local RollID = Bar.RollID
		local Info = RollInfos[RollID]
		local Winner = Winners[RollID]
		local Data = Rolls[RollID]

		if Info then
			local Color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[Info.Quality]

			Bar.Icon.Texture:SetTexture(Info.Texture)
			Bar.Name:SetText(Info.Name or "")
			Bar.Name:SetTextColor(Color and Color.r or 1, Color and Color.g or 1, Color and Color.b or 1)
		end

		if Winner and Winner.AllPassed then
			Bar.Status:SetText(TypeMarkup("Pass").." "..TextAllPassed)
		elseif Winner then
			local Roll = Winner.Roll and (" |cff999999("..Winner.Roll..")|r") or ""

			Bar.Status:SetText(TextWinner.." "..TypeMarkup(Winner.Type).." "..ColoredName(Winner.Name or "?", Winner.Class)..Roll)
		else
			-- counts per choice, ours first
			local Parts = {}

			for _, Type in ipairs(RollTypes) do
				local Count = 0

				for _ in pairs(Data and Data[Type] or {}) do
					Count = Count + 1
				end

				if Count > 0 then
					tinsert(Parts, TypeMarkup(Type).." "..Count)
				end
			end

			Bar.Status:SetText(table.concat(Parts, "   "))
		end
	end
end

function GroupLoot:ShowTracker(RollID)
	local Info = RollInfos[RollID]

	-- (also for rolls that ended on the timer: the winner is reported right after)
	if not Info then
		return
	end

	for _, Bar in ipairs(Trackers) do
		if Bar.RollID == RollID then
			return
		end
	end

	local Bar = tremove(TrackerPool) or CreateTracker()

	Bar.RollID = RollID
	Bar.WinnerTime = nil
	Bar.EndedTime = nil
	Bar.Timer:SetMinMaxValues(0, max(1, Info.EndTime - GetTime()))
	Bar:Show()

	tinsert(Trackers, Bar)

	-- Blizzard hides its frame right after this event
	C_Timer.After(0, function()
		GroupLoot:LayoutTrackers()
		GroupLoot:RefreshTrackers()
	end)
end

function GroupLoot:Enable()
	self:AddMover()
	self:SkinFrames()
	self:AddHooks()
	self:AddRollTracking()
	--self:TestGroupLootFrames()
end

Inventory.GroupLoot = GroupLoot
