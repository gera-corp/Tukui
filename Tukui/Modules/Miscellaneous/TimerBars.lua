local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Movers = T["Movers"]
local TimerBars = CreateFrame("Frame")

-- Timer bars started from our own successful casts (the aura API is secret in
-- combat on this client, so casts are what we can rely on):
-- * Summon Hawk (Forever hunter talent): temporary hawks, at most 2 alive, a 3rd
--   cast replaces the oldest one. Shown in their own group at the bottom.
-- * Any other harmful spell whose tooltip has a duration ("for 15 sec", "for 2 min"):
--   stings, marks, DoTs, crowd control... Grouped by mob (up to 5 mobs, the mob
--   name on top), one bar per spell, restarted on recast. Spells that live on one
--   mob only (Hunter's Mark) move to the new mob. The current target's group is
--   opaque, the others are faded.
-- A group remembers its mob: its GUID when the client doesn't hide it, otherwise
-- a counter bumped on every target change, plus the mob's nameplate unit. It's
-- removed when that mob dies: while targeted, or through its nameplate (which
-- needs enemy nameplates on). Other early ends (hawk killed, debuff dispelled)
-- aren't detected: the combat log is closed to addons, so the bars just run out.
local HAWK = {
	SpellIDs = {
		[1293241] = true, -- Rank 1
		[1293525] = true, -- Rank 2
		[1293526] = true, -- Rank 3
		[1293527] = true, -- Rank 4
	},
	Max = 2,
	DefaultDuration = 18,
	Color = T.Colors.class["HUNTER"],
}

-- One of these on a single mob at a time (Classic ranks, matched by name so other
-- rank IDs work too)
local SINGLE_TARGET_SPELL_IDS = {
	1130, -- Hunter's Mark
}

local DEBUFF_COLOR = {0.85, 0.65, 0.20}
local MAX_GROUPS = 5
local MAX_BARS_PER_GROUP = 5
local OTHER_TARGET_ALPHA = 0.45
local BAR_SPACING = 3
local GROUP_SPACING = 8
local CLEAR_DELAY = 0.3

-- Size and font come from the Tukui settings (Misc > Timer Bars), read on Enable
local BarWidth, BarHeight, HeaderHeight, FontPath, FontSize, FontFlag

-- /run TukuiTimerBarsDebug = true  prints what the client does with the target
local function Debug(...)
	if TukuiTimerBarsDebug then
		print("|cff00ff96TimerBars|r", ("%.2f"):format(GetTime()), ...)
	end
end

local function NotSecret(value)
	return not (issecretvalue and issecretvalue(value))
end

-- nil when the unit doesn't exist or the client keeps its GUID secret
local function GetGUID(unit)
	local GUID = UnitGUID(unit)

	if GUID and NotSecret(GUID) then
		return GUID
	end
end

local function GetTargetGUID()
	return GetGUID("target")
end

local function ToNumber(text)
	return text and tonumber((text:gsub(",", ".")))
end

-- Localized "sec"/"min" words, taken from Blizzard's own duration strings
-- (SPELL_DURATION_SEC is "%.2f sec" on enUS), so other client languages work too
local function GetUnitWord(Format, Fallback)
	local Word = type(Format) == "string" and Format:match("%%[%d%.]*[fd]%s*([^%s%.%d]+)")

	return Word or Fallback
end

local SecondsWord = GetUnitWord(SPELL_DURATION_SEC, "sec")
local MinutesWord = GetUnitWord(SPELL_DURATION_MIN, "min")

-- Duration from the spell tooltip, nil if it doesn't mention one
local function GetDuration(spellID)
	local Description = C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellID)

	if not Description or (issecretvalue and issecretvalue(Description)) then
		return
	end

	local Seconds = ToNumber(Description:match("(%d+[%.,]?%d*)%s*"..SecondsWord) or Description:match("(%d+[%.,]?%d*)%s*sec"))

	if not Seconds then
		local Minutes = ToNumber(Description:match("(%d+[%.,]?%d*)%s*"..MinutesWord) or Description:match("(%d+[%.,]?%d*)%s*min"))

		Seconds = Minutes and Minutes * 60
	end

	if Seconds and Seconds > 0 then
		return Seconds
	end
end

local function FormatTime(seconds)
	if seconds >= 60 then
		return ("%d:%02d"):format(seconds / 60, seconds % 60)
	end

	return ("%.1f"):format(seconds)
end

local function SortByExpiration(a, b)
	return a.Expires < b.Expires
end

local function CreateText(parent, size)
	local Text = parent:CreateFontString(nil, "OVERLAY")

	Text:SetFont(FontPath, size, FontFlag)
	Text:SetShadowColor(0, 0, 0)
	Text:SetShadowOffset(1.25, -1.25)

	return Text
end

local function CreateBar(parent)
	local Bar = CreateFrame("StatusBar", nil, parent)

	Bar:SetSize(BarWidth - BarHeight - BAR_SPACING, BarHeight)
	Bar:SetStatusBarTexture(C.Medias.Normal)
	Bar:CreateBackdrop()
	Bar:CreateShadow()
	Bar:Hide()

	Bar.Icon = CreateFrame("Frame", nil, Bar)
	Bar.Icon:SetSize(BarHeight, BarHeight)
	Bar.Icon:SetPoint("RIGHT", Bar, "LEFT", -BAR_SPACING, 0)
	Bar.Icon:CreateBackdrop()
	Bar.Icon:CreateShadow()

	Bar.Icon.Texture = Bar.Icon:CreateTexture(nil, "ARTWORK")
	Bar.Icon.Texture:SetInside()
	Bar.Icon.Texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	Bar.Name = CreateText(Bar, FontSize)
	Bar.Name:SetPoint("LEFT", Bar, "LEFT", 4, 0)

	Bar.Time = CreateText(Bar, FontSize)
	Bar.Time:SetPoint("RIGHT", Bar, "RIGHT", -4, 0)

	return Bar
end

-- A group: optional header with the mob name, then its bars from the top down
local function CreateGroupFrame(parent, numBars, withHeader)
	local Frame = CreateFrame("Frame", nil, parent)
	local Top = 0

	Frame:SetWidth(BarWidth)
	Frame:Hide()

	if withHeader then
		Frame.Header = CreateText(Frame, FontSize - 1)
		Frame.Header:SetTextColor(0.75, 0.75, 0.75)
		Frame.Header:SetJustifyH("CENTER")
		Frame.Header:SetWordWrap(false)
		Frame.Header:SetPoint("TOPLEFT", Frame, "TOPLEFT", 0, 0)
		Frame.Header:SetPoint("TOPRIGHT", Frame, "TOPRIGHT", 0, 0)

		Top = HeaderHeight
	end

	Frame.Top = Top
	Frame.Bars = {}

	for i = 1, numBars do
		local Bar = CreateBar(Frame)

		Bar:SetPoint("TOPRIGHT", Frame, "TOPRIGHT", 0, -(Top + (i - 1) * (BarHeight + BAR_SPACING)))
		Frame.Bars[i] = Bar
	end

	return Frame
end

local function RemoveExpired(timers, now)
	for i = #timers, 1, -1 do
		if timers[i].Expires <= now then
			table.remove(timers, i)
		end
	end
end

local function RemoveByName(timers, name)
	for i = #timers, 1, -1 do
		if timers[i].Name == name then
			table.remove(timers, i)
		end
	end
end

-- Fill a group frame and stack it at height y; returns the next free height
function TimerBars:ShowGroup(frame, timers, now, y, alpha)
	if #timers == 0 then
		frame:Hide()

		return y
	end

	table.sort(timers, SortByExpiration)

	local Count = math.min(#timers, #frame.Bars)

	for i, Bar in ipairs(frame.Bars) do
		local Timer = timers[i]

		if Timer then
			local Left = Timer.Expires - now

			Bar:SetStatusBarColor(unpack(Timer.Color))
			Bar:SetMinMaxValues(0, Timer.Duration)
			Bar:SetValue(Left)
			Bar.Time:SetText(FormatTime(Left))
			Bar.Name:SetText(Timer.Name)
			Bar.Icon.Texture:SetTexture(Timer.Icon)
			Bar:Show()
		else
			Bar:Hide()
		end
	end

	local Height = frame.Top + Count * BarHeight + (Count - 1) * BAR_SPACING

	frame:SetHeight(Height)
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", self.Holder, "BOTTOMLEFT", 0, y)
	frame:SetAlpha(alpha)
	frame:Show()

	return y + Height + GROUP_SPACING
end

function TimerBars:Refresh()
	local Now = GetTime()
	local HasTarget = UnitExists("target")
	local ClearTarget

	-- Dead target: still targeted as a corpse, or gone for good (see OnTargetChanged)
	if HasTarget and UnitIsDead("target") then
		ClearTarget = self.TargetID
	elseif self.PendingClear and Now >= self.PendingClearAt then
		ClearTarget = not HasTarget and self.PendingClear or nil
		Debug("pending check: target", HasTarget, "-> clear", ClearTarget)
		self.PendingClear = nil
	end

	RemoveExpired(self.Hawks, Now)

	for i = #self.Groups, 1, -1 do
		local Group = self.Groups[i]

		RemoveExpired(Group.Timers, Now)

		local Dead = Group.Dead or (Group.Plate and UnitIsDead(Group.Plate))

		if #Group.Timers == 0 or Dead or (ClearTarget and Group.TargetID == ClearTarget) then
			table.remove(self.Groups, i)
		end
	end

	-- Hawks at the bottom, then the mobs in the order they were first debuffed
	local Y = self:ShowGroup(self.HawkFrame, self.Hawks, Now, 0, 1)

	for i, Frame in ipairs(self.GroupFrames) do
		local Group = self.Groups[i]

		if Group then
			-- The name can be secret: the font string takes it, string code can't
			if not pcall(Frame.Header.SetText, Frame.Header, Group.Unit) then
				Frame.Header:SetText("")
			end

			local Current = HasTarget and Group.TargetID == self.TargetID

			Y = self:ShowGroup(Frame, Group.Timers, Now, Y, Current and 1 or OTHER_TARGET_ALPHA)
		else
			Frame:Hide()
		end
	end

	if #self.Hawks == 0 and #self.Groups == 0 then
		self:SetScript("OnUpdate", nil)
	end
end

-- The nameplate unit of the current target, if the client lets us compare units
function TimerBars:FindTargetPlate()
	for Plate in pairs(self.Plates) do
		local Same = UnitIsUnit(Plate, "target")

		if NotSecret(Same) and Same then
			return Plate
		end
	end
end

-- The group of the current target, created if needed (dropping the group we
-- haven't touched for the longest time when all of them are taken)
function TimerBars:GetTargetGroup()
	local GUID = GetTargetGUID()
	local Plate = self:FindTargetPlate()

	for _, Group in ipairs(self.Groups) do
		if Group.TargetID == self.TargetID or (GUID and Group.GUID == GUID) then
			Group.TargetID = self.TargetID
			Group.Plate = Plate or Group.Plate

			return Group
		end
	end

	if #self.Groups >= MAX_GROUPS then
		local Oldest = 1

		for i, Group in ipairs(self.Groups) do
			if Group.LastUsed < self.Groups[Oldest].LastUsed then
				Oldest = i
			end
		end

		table.remove(self.Groups, Oldest)
	end

	local Group = {
		GUID = GUID,
		TargetID = self.TargetID,
		Unit = UnitName("target"),
		Plate = Plate,
		Timers = {},
		LastUsed = GetTime(),
	}

	table.insert(self.Groups, Group)

	return Group
end

function TimerBars:OnTargetChanged()
	local Exists = UnitExists("target")

	Debug("target changed: exists", Exists, "dead", UnitIsDead("target"), "id", self.TargetID, "->", self.TargetID + 1)

	-- This client clears the target when it dies (the corpse is never seen as dead
	-- in time), and reports the clearing twice. Switching targets can briefly go
	-- through "no target" too, so the old target's group goes only if no new
	-- target shows up in time. Only a target that was there and is gone counts, so
	-- the second "no target" doesn't replace the pending one.
	-- Side effect: clearing the target by hand (Esc) also removes the group.
	if self.HadTarget and not Exists then
		self.PendingClear = self.TargetID
		self.PendingClearAt = GetTime() + CLEAR_DELAY
	end

	self.HadTarget = Exists
	self.TargetID = self.TargetID + 1

	-- Back on a mob we already debuffed: its group follows the new target id. Found
	-- by GUID, or, when the client keeps GUIDs secret, by the nameplate we saw it on
	local GUID = Exists and GetTargetGUID()
	local Plate = Exists and self:FindTargetPlate()
	local Found

	if Exists then
		for _, Group in ipairs(self.Groups) do
			if (GUID and Group.GUID == GUID) or (Plate and Group.Plate == Plate) then
				Group.TargetID = self.TargetID
				Group.Plate = Plate or Group.Plate
				Found = true
			end
		end
	end

	Debug("target guid", GUID and "known" or "secret or none", "plate", Plate or "not found", "group", Found and "found" or "none")

	-- Update the fading right away
	if #self.Groups > 0 then
		self:Refresh()
	end
end

function TimerBars:OnCast(spellID)
	if issecretvalue and issecretvalue(spellID) then
		return
	end

	local Now = GetTime()
	local Name = C_Spell.GetSpellName(spellID)
	local Icon = C_Spell.GetSpellTexture(spellID)

	if HAWK.SpellIDs[spellID] then
		if #self.Hawks >= HAWK.Max then
			table.sort(self.Hawks, SortByExpiration)
			table.remove(self.Hawks, 1)
		end

		local Duration = GetDuration(spellID) or HAWK.DefaultDuration

		table.insert(self.Hawks, {Name = Name, Icon = Icon, Color = HAWK.Color, Duration = Duration, Expires = Now + Duration})
	elseif Name and UnitExists("target") and C_Spell.IsSpellHarmful(spellID) then
		local Duration = GetDuration(spellID)

		if not Duration then
			return
		end

		local Group = self:GetTargetGroup()

		-- Same spell again: restart its bar; single-target spells leave other mobs
		if self.SingleTargetNames[Name] then
			for _, Other in ipairs(self.Groups) do
				RemoveByName(Other.Timers, Name)
			end
		else
			RemoveByName(Group.Timers, Name)
		end

		-- Group full: the bar closest to running out makes room
		if #Group.Timers >= MAX_BARS_PER_GROUP then
			table.sort(Group.Timers, SortByExpiration)
			table.remove(Group.Timers, 1)
		end

		table.insert(Group.Timers, {Name = Name, Icon = Icon, Color = DEBUFF_COLOR, Duration = Duration, Expires = Now + Duration})
		Group.LastUsed = Now

		Debug("cast", Name, "on target id", Group.TargetID, "guid", Group.GUID and "known" or "secret or none", "plate", Group.Plate or "not found")
	else
		return
	end

	self:SetScript("OnUpdate", self.Refresh)
	self:Refresh()
end

-- A mob's nameplate came into range: hook it back to its group
function TimerBars:OnPlateAdded(unit)
	self.Plates[unit] = true

	local GUID = GetGUID(unit)

	if GUID then
		for _, Group in ipairs(self.Groups) do
			if Group.GUID == GUID then
				Group.Plate = unit
			end
		end
	end
end

-- Nameplates go away when the mob dies, or just goes out of range
function TimerBars:OnPlateRemoved(unit)
	local Dead = UnitIsDead(unit)

	self.Plates[unit] = nil

	for _, Group in ipairs(self.Groups) do
		if Group.Plate == unit then
			Group.Plate = nil
			Group.Dead = Group.Dead or Dead
		end
	end

	if #self.Groups > 0 then
		Debug("plate removed", unit, "dead", Dead)

		self:Refresh()
	end
end

function TimerBars:OnEvent(event, unit, castGUID, spellID)
	if event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged()
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		self:OnPlateAdded(unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		self:OnPlateRemoved(unit)
	else
		self:OnCast(spellID)
	end
end

function TimerBars:Enable()
	if self.Holder then
		return
	end

	-- The frame used to be "TukuiHawkTimers": keep a position saved under that name
	local Realm = TukuiDatabase.Variables and TukuiDatabase.Variables[T.MyRealm]
	local Move = Realm and Realm[T.MyName] and Realm[T.MyName].Move

	if Move and Move.TukuiHawkTimers and not Move.TukuiTimerBars then
		Move.TukuiTimerBars = Move.TukuiHawkTimers
		Move.TukuiHawkTimers = nil
	end

	local Path, _, Flag = _G[T.GetFont(C.Misc.TimerBarsFont)]:GetFont()

	BarWidth = C.Misc.TimerBarsWidth or 290
	BarHeight = C.Misc.TimerBarsHeight or 17
	FontSize = C.Misc.TimerBarsFontSize or 13
	FontPath, FontFlag = Path, Flag
	HeaderHeight = FontSize + 3

	-- The groups grow upwards from the holder's bottom edge
	local Holder = CreateFrame("Frame", "TukuiTimerBars", UIParent)

	Holder:SetSize(BarWidth, 2 * BarHeight + BAR_SPACING)
	Holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 260)

	self.Holder = Holder
	self.Hawks = {}
	self.Groups = {}
	self.TargetID = 0
	self.HadTarget = UnitExists("target")
	self.SingleTargetNames = {}
	self.Plates = {}

	for _, SpellID in ipairs(SINGLE_TARGET_SPELL_IDS) do
		local Name = C_Spell.GetSpellName(SpellID)

		if Name then
			self.SingleTargetNames[Name] = true
		end
	end

	self.HawkFrame = CreateGroupFrame(Holder, HAWK.Max, false)
	self.GroupFrames = {}

	for i = 1, MAX_GROUPS do
		self.GroupFrames[i] = CreateGroupFrame(Holder, MAX_BARS_PER_GROUP, true)
	end

	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	self:SetScript("OnEvent", self.OnEvent)

	Movers:RegisterFrame(Holder, "Timers")
end

Miscellaneous.TimerBars = TimerBars
