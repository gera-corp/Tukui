local T, C, L = unpack((select(2, ...)))

local AddOnCommands = {} -- Let people use /tukui for their mods
local SelectedProfile = 0
local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
local GetMouseFocus = GetMouseFocus or GetMouseFoci
local EnableAddOn = C_AddOns and C_AddOns.EnableAddOn or EnableAddOn
local DisableAddOn = C_AddOns and C_AddOns.DisableAddOn or DisableAddOn

local Split = function(cmd)
	if cmd:find("%s") then
		return strsplit(" ", cmd)
	else
		return cmd
	end
end

local SplitServerCharacter = function(profile)
	return strsplit("-", profile)
end

local EventTraceEnabled = false
local EventTrace = CreateFrame("Frame")
EventTrace:SetScript("OnEvent", function(self, event)
	if (event ~= "GET_ITEM_INFO_RECEIVED" and event ~= "COMBAT_LOG_EVENT_UNFILTERED") then
		T.Print(event)
	end
end)

-- Taint check (/tukui taint): lists values in Blizzard's action bar code that an addon wrote
-- (tainted), and which addon did it. Clients with secret values refuse to show action button
-- cooldowns once that code reads a tainted value, and taint.log doesn't record field writes.
local TaintBarNames = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button", "OverrideActionBarButton", "StanceButton", "PetActionButton"}
local TaintChildren = {"cooldown", "chargeCooldown", "lossOfControlCooldown", "bar"}
local TaintGlobalPatterns = {"^ActionButton", "^ActionBar", "^CooldownFrame", "^CooldownViewer", "^MultiActionBar", "^MultiBar", "^MainMenuBar", "^MainActionBar", "^GetAction", "^IsAction", "^HasAction", "^IsUsableAction", "^IsCurrentAction", "^IsAutoRepeatAction", "^IsAttackAction", "^IsConsumableAction", "^IsEquippedAction", "^IsStackableAction", "^IsItemAction", "^IsSpellOverlayed", "^SetCooldown"}

local TaintCheck = function(Quick)
	local Found, Count, Seen = {}, 0, {}

	local Add = function(Where, Addon)
		Count = Count + 1
		Found[Addon] = Found[Addon] or {}
		tinsert(Found[Addon], Where)
	end

	local CheckTable = function(Table, Name, Depth)
		if type(Table) ~= "table" or Seen[Table] then
			return
		end

		Seen[Table] = true

		for Key, Value in pairs(Table) do
			-- tables keyed by frames (like the event frames' button lists) show the frame name
			local KeyName = type(Key) == "table" and Key.GetName and (Key:GetName() or "<frame>") or tostring(Key)
			local Ok, Secure, Addon = pcall(issecurevariable, Table, Key)

			if Ok and not Secure then
				Add(Name .. "[" .. KeyName .. "]", Addon or "?")
			end

			if Depth > 0 and type(Value) == "table" and not Value.GetObjectType then
				pcall(CheckTable, Value, Name .. "." .. KeyName, Depth - 1)
			end
		end
	end

	for _, Prefix in ipairs(TaintBarNames) do
		for i = 1, 12 do
			local Name = Prefix .. i
			local Button = _G[Name]

			if Button then
				pcall(CheckTable, Button, Name, 0)

				for _, Child in ipairs(TaintChildren) do
					if type(Button[Child]) == "table" then
						pcall(CheckTable, Button[Child], Name .. "." .. Child, 0)
					end
				end
			end
		end
	end

	for _, Name in ipairs({"ActionBarButtonEventsFrame", "ActionBarActionEventsFrame", "MainMenuBar", "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar"}) do
		if _G[Name] then
			pcall(CheckTable, _G[Name], Name, 1)
		end
	end

	if Quick then
		return Found, Count
	end

	-- Blizzard's action bar settings (an addon writing them taints the bar updates)
	if Settings and Settings.GetSetting then
		for i = 2, 8 do
			local Ok, Setting = pcall(Settings.GetSetting, "PROXY_SHOW_ACTIONBAR_" .. i)

			if Ok and type(Setting) == "table" then
				pcall(CheckTable, Setting, "Setting[PROXY_SHOW_ACTIONBAR_" .. i .. "]", 1)
			end
		end
	end

	for Name, Value in pairs(_G) do
		if type(Name) == "string" and type(Value) == "table" and Name:find("ActionButton%d+$") and not Name:find("^Tukui") then
			-- other action buttons, such as Blizzard's gamepad bars
			pcall(CheckTable, Value, Name, 0)

			for _, Child in ipairs(TaintChildren) do
				if type(Value[Child]) == "table" then
					pcall(CheckTable, Value[Child], Name .. "." .. Child, 0)
				end
			end
		end

		if type(Name) == "string" then
			local Match = false

			for _, Pattern in ipairs(TaintGlobalPatterns) do
				if Name:find(Pattern) then
					Match = true
					break
				end
			end

			-- Blizzard-style constants (STANDARD_TEXT_FONT) and functions (Foo_Bar): an addon
			-- that overwrites one taints every Blizzard function reading it
			if not Match and (Name:find("^[A-Z][A-Z0-9_]+$") or (type(Value) == "function" and Name:find("^%u%a+_%u"))) then
				Match = true
			end

			if Match and not Name:find("^Tukui") then
				local Secure, Addon = issecurevariable(Name)

				if not Secure then
					Add(Name, Addon or "?")
				end

				if type(Value) == "table" and (Name:find("Mixin$") or Name:find("Util$")) then
					pcall(CheckTable, Value, Name, 0)
				end
			elseif Name:find("^C_") and type(Value) == "table" then
				pcall(CheckTable, Value, Name, 0)
			end
		end
	end

	return Found, Count
end

local TaintPrint = function()
	local Found, Count = TaintCheck()

	if Count == 0 then
		T.Print("Taint check: nothing in the action bar code is tainted right now.")

		return
	end

	T.Print("Taint check: " .. Count .. " tainted value(s) in the action bar code:")

	for Addon, List in pairs(Found) do
		local Shown = {}

		for i = 1, min(#List, 8) do
			Shown[i] = List[i]
		end

		T.Print("|cffff8000" .. Addon .. "|r (" .. #List .. "): " .. table.concat(Shown, ", ") .. (#List > 8 and ", ..." or ""))
	end
end

-- On clients with secret values the check also runs by itself (after loading screens, every
-- 30 seconds for the buttons and every 2 minutes in full, out of combat) and keeps the first finding of each kind in
-- TukuiDatabase.TaintReport, so a report survives the /reload that fixes the bars.
if issecretvalue then
	local Reported = {}
	local Recorder = CreateFrame("Frame")

	-- Tukui's own skin fields on Blizzard buttons: Blizzard's code never reads them
	local Ignored = {Backdrop = true, Shadow = true, isSkinned = true, IsSkinned = true, Pushed = true, Highlight = true, Checked = true, IsCooldownTextEdited = true}

	local Record = function(Quick)
		if not TukuiDatabase then
			return
		end

		local Found = TaintCheck(Quick)

		for Addon, List in pairs(Found) do
			for _, Where in ipairs(List) do
				local Key = Addon .. " " .. Where
				local Field = Where:match("%[([^%]]+)%]$")

				if Addon == "Tukui" and Field and Ignored[Field] then
					Reported[Key] = true
				end

				if not Reported[Key] then
					Reported[Key] = true

					TukuiDatabase.TaintReport = TukuiDatabase.TaintReport or {}

					local Report = TukuiDatabase.TaintReport

					tinsert(Report, date("%m/%d %H:%M:%S") .. " " .. (GetZoneText() or "") .. ": " .. Addon .. " -> " .. Where)

					while #Report > 500 do
						tremove(Report, 1)
					end
				end
			end
		end
	end

	-- Watch for the moment the buttons' action fields go tainted: check them on every event
	-- and every frame, for the whole session, and record the events that came just before.
	-- Re-armed once the fields are clean again (Blizzard rewrote them), up to 20 records.
	local Watcher = CreateFrame("Frame")
	local WatchButtons = {"ActionButton1", "ActionButton2", "MultiBarBottomLeftButton1", "MultiBarBottomRightButton1", "MultiBarRightButton1", "MultiBarLeftButton1", "ExtraActionButton1"}
	local WatchFields = {"action", "feedback_action"}
	local RecentEvents, Caught, Records = {}, false, 0
	-- call stack of the last clean action change: these events fire from inside Blizzard's
	-- button updates, so the stack shows what started the update
	local LastStack, Stack = "", ""
	local Noisy = {COMBAT_LOG_EVENT_UNFILTERED = true, UNIT_POWER_FREQUENT = true, UNIT_AURA = true, UNIT_HEALTH = true}

	local CheckWatch = function(Where)
		for _, Name in ipairs(WatchButtons) do
			local Button = _G[Name]

			if Button then
				for _, Field in ipairs(WatchFields) do
					local Ok, Secure, Addon = pcall(issecurevariable, Button, Field)

					if Ok and Secure == false then
						if not Caught and Records < 20 then
							Caught = true
							Records = Records + 1

							-- kept apart from the report, so later reports can't push it out
							TukuiDatabase.TaintFirst = TukuiDatabase.TaintFirst or {}
							tinsert(TukuiDatabase.TaintFirst, date("%m/%d %H:%M:%S") .. " " .. (GetZoneText() or "") .. " FIRST " .. Name .. "[" .. Field .. "] by " .. (Addon or "?") .. " at " .. Where .. (InCombatLockdown() and " (combat)" or "") .. "; events before: " .. table.concat(RecentEvents, ", ") .. " || STACK NOW: " .. Stack .. " || STACK BEFORE (clean): " .. LastStack)
						end

						return
					end
				end
			end
		end

		-- all clean again: catch the next time
		Caught = false
	end

	Watcher:RegisterAllEvents()
	Watcher:SetScript("OnEvent", function(_, Event)
		if not TukuiDatabase then
			return
		end

		if Event == "ACTION_RANGE_CHECK_UPDATE" or Event == "ACTIONBAR_SLOT_CHANGED" then
			Stack = debugstack(2, 25, 0) or ""
		else
			Stack = ""
		end

		CheckWatch("event " .. Event)

		if Stack ~= "" and not Caught then
			LastStack = Stack
		end

		if not Noisy[Event] then
			tinsert(RecentEvents, Event)

			if #RecentEvents > 30 then
				tremove(RecentEvents, 1)
			end
		end
	end)
	Watcher:SetScript("OnUpdate", function()
		if TukuiDatabase then
			CheckWatch("frame update")
		end
	end)

	local Elapsed, Full = 0, 0

	Recorder:RegisterEvent("PLAYER_ENTERING_WORLD")
	Recorder:SetScript("OnEvent", function()
		C_Timer.After(5, function()
			Record(false)
		end)
	end)
	Recorder:SetScript("OnUpdate", function(_, Delta)
		Elapsed = Elapsed + Delta

		if Elapsed >= 30 and not InCombatLockdown() then
			Elapsed = 0
			Full = Full + 1

			-- the whole check (globals too) every 2 minutes, the buttons every 30 seconds
			Record(Full % 4 ~= 0)
		end
	end)
end

T.SlashHandler = function(cmd)
	local arg1, arg2, arg3, arg4 = Split(cmd)

	if (arg1 == "" or arg1 == "help") then
		T.Help:Show()
	else
		T.Help:Hide()
	end

	if (arg1 == "t") or (arg1 == "tracking") then
		if (C.UnitFrames.Enable) and (C.Raid.Enable) then
			T.UnitFrames.Tracking:Toggle()
		else
			T.Print("Sorry, our raid module is currently disabled")
		end
	elseif (arg1 == "p") or (arg1 == "profile") then
		local Profiles = T.Profiles

		Profiles:Toggle()
	elseif (arg1 == "mm") or (arg1 == "micromenu") then
		local MicroMenu = T.Miscellaneous.MicroMenu

		MicroMenu:Toggle()
	elseif (arg1 == "ot") or (arg1 == "quests") then
		if T.Retail then
			if (ObjectiveTrackerFrame:IsVisible()) then
				ObjectiveTrackerFrame:Hide()
			else
				ObjectiveTrackerFrame:Show()
			end
		else
			if (QuestWatchFrame:IsVisible()) then
				QuestWatchFrame:Hide()
			else
				QuestWatchFrame:Show()
			end
		end
	elseif (arg1 == "ru") or (arg1 == "markers") then
		local Utilities = T.Miscellaneous.RaidUtilities

		Utilities:Toggle()
	elseif (arg1 == "fn") then
		local Name = GetMouseFocus():GetName()

		if Name then
			T.Print("Global name for this frame is: |CFF00FF00"..GetMouseFocus():GetName().."|r")
		else
			T.Print("Global name not found for this frame")
		end
	elseif (arg1 == "kb" or arg1 == "keybinds") then
		if InCombatLockdown() then
			return
		end

		if T.Retail then
			if QuickKeybindFrame and QuickKeybindFrame:IsShown() then
				return
			end

			QuickKeybindFrame:Show()
		else
			T.Miscellaneous.Keybinds:Toggle()
		end
	elseif (arg1 == "chat") then
		if (arg2 == "reset") then
			local Chat = T.Chat
			local Panels = T.DataTexts.Panels
			local DataLeft = Panels.Left
			local DataRight = Panels.Right

			if Chat then
				-- Reset chat windows
				Chat:Reset()

				-- Move back to default position
				DataLeft:ClearAllPoints()
				DataLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 34, 20)

				DataRight:ClearAllPoints()
				DataRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -34, 20)

				if DataLeft.DragInfo then
					DataLeft.DragInfo:ClearAllPoints()
					DataLeft.DragInfo:SetAllPoints(DataLeft)
				end

				if DataRight.DragInfo then
					DataRight.DragInfo:ClearAllPoints()
					DataRight.DragInfo:SetAllPoints(DataRight)
				end

				-- Remove saved position settings
				TukuiDatabase.Variables[T.MyRealm][T.MyName].Move.TukuiLeftDataTextBox = nil
				TukuiDatabase.Variables[T.MyRealm][T.MyName].Move.TukuiRightDataTextBox = nil
			end
		end
	elseif (arg1 == "dt" or arg1 == "datatext") then
		local DataText = T["DataTexts"]

		if arg2 then
			if (arg2 == "reset") then
				DataText:Reset()
			elseif (arg2 == "resetgold") then
				DataText:ResetGold()
			end
		else
			DataText:ToggleDataPositions()
		end
	elseif (arg1 == "install" or arg1 == "reset") then
		if arg2 == "blizzard" then
			if T.Retail then
				C_EditMode.SetActiveLayout(1)
			end
			
			ReloadUI()
		else
			T.Popups.ShowPopup("RESETUI")
		end
	elseif (arg1 == "load" or arg1 == "unload") then
		local Loaded, Reason = ((C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn)(arg2)

		if (Reason == "MISSING") then
			T.Print("["..arg2.."] is not installed")

			return
		end

		if arg1 == "load" then
			if (IsAddOnLoaded(arg2)) then
				T.Print("["..arg2.."] is already loaded")

				return
			end

			EnableAddOn(arg2)
		else
			DisableAddOn(arg2)
		end

		ReloadUI()
	elseif (arg1 == "br" or arg1 == "report") then
		if arg2 == "enable" then
			EnableAddOn("Blizzard_PTRFeedback")
		else
			DisableAddOn("Blizzard_PTRFeedback")
		end

		ReloadUI()
	elseif (arg1 == "status" or arg1 == "debug") then
		local Status = TukuiStatus

		Status:ShowWindow()
	elseif (arg1 == "events" or arg1 == "trace") then
		if EventTraceEnabled then
			EventTrace:UnregisterAllEvents()

			EventTraceEnabled = false
		else
			EventTrace:RegisterAllEvents()

			EventTraceEnabled = true
		end
	elseif (arg1 == "taint") then
		TaintPrint()
	elseif (arg1 == "move" or arg1 == "moveui") then
		local Movers = T["Movers"]

		if not Movers.IsEnabled then
			Movers:OpenEditMode()
		else
			Movers:CloseEditMode()
		end
	elseif (arg1 == "c" or arg1 == "config" or arg1 == "gui") then
		T.GUI:Toggle()
	elseif (arg1 == "gold") and (arg2 == "reset") then
		local DataText = T["DataTexts"]
		local MyRealm = GetRealmName()
		local MyName = UnitName("player")

		DataText:ResetGold()
	elseif (arg1 == "test" or arg1 == "testui") then
		local Test = T["TestUI"]

		Test:EnableOrDisable()
	elseif (arg1 == "grid") then
		local Grid = T.Miscellaneous.Grid

		if Grid.Enable then
			Grid:Hide()
			Grid.Enable = false
		else
			if arg2 then
				local Number = tonumber(arg2)

				if Number then
					Grid.BoxSize = Number
				end
			end
			if Grid.BoxSize > 256 then
				Grid.BoxSize = 256
			end

			Grid:Show()
			Grid.Enable = true
			Grid.BoxSize = (math.ceil((tonumber(arg) or Grid.BoxSize) / 32) * 32)
		end
	elseif AddOnCommands[arg1] then
		AddOnCommands[arg1](arg2)
	end
end

T.Popups.Popup["RESETUI"] = {
	Question = "Are you sure you want to reset Tukui to default?",
	Answer1 = ACCEPT,
	Answer2 = CANCEL,
	Function1 = function(self)
		local Install = T["Install"]
		
		if T.Retail then
			C_EditMode.SetActiveLayout(1)
		end

		Install:ResetSettings()
		Install:ResetData()
	end,
}

SLASH_TUKUISLASHHANDLER1 = "/tukui"
SlashCmdList["TUKUISLASHHANDLER"] = T.SlashHandler

T.AddOnCommands = AddOnCommands
