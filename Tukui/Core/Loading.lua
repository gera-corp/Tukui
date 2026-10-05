local T, C, L = unpack((select(2, ...)))

local Loading = CreateFrame("Frame")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

function Loading:StoreDefaults()
	T.Defaults = {}

	for group, options in pairs(C) do
		if (not T.Defaults[group]) then
			T.Defaults[group] = {}
		end

		for option, value in pairs(options) do
			T.Defaults[group][option] = value

			if (type(C[group][option]) == "table") then
				if C[group][option].Options then
					T.Defaults[group][option] = value.Value
				else
					T.Defaults[group][option] = value
				end
			else
				T.Defaults[group][option] = value
			end
		end
	end
end

function Loading:LoadCustomSettings()
	local Settings = TukuiDatabase.Settings[T.MyRealm][T.MyName]

	for group, options in pairs(Settings) do
		if C[group] then
			local Count = 0

			for option, value in pairs(options) do
				if (C[group][option] ~= nil) then
					if (C[group][option] == value) then
						Settings[group][option] = nil
					else
						Count = Count + 1

						if (type(C[group][option]) == "table") then
							if C[group][option].Options then
								C[group][option].Value = value
							else
								C[group][option] = value
							end
						else
							C[group][option] = value
						end
					end
				end
			end

			-- Keeps settings clean and small
			if (Count == 0) then
				Settings[group] = nil
			end
		else
			Settings[group] = nil
		end
	end
end

function Loading:LoadProfiles()
	local Profiles = C.General.Profiles
	local Menu = Profiles.Options
	local Data = TukuiDatabase.Variables
	local GUISettings = TukuiDatabase.Settings
	local Nickname = T.MyName
	local Server = T.MyRealm

	if not GUISettings then
		return
	end

	for Index, Table in pairs(GUISettings) do
		local Server = Index

		for Nickname, Settings in pairs(Table) do
			local ProfileName = Server.."-"..Nickname
			local MyProfileName = T.MyRealm.."-"..T.MyName

			if MyProfileName ~= ProfileName then
				Menu[ProfileName] = ProfileName
			end
		end
	end
end

function Loading:Enable()
	local Toolkit = T.Toolkit

	self:StoreDefaults()
	self:LoadProfiles()
	self:LoadCustomSettings()

	Toolkit.Settings.BackdropColor = C.General.BackdropColor
	Toolkit.Settings.BorderColor = C.General.ClassColorBorder and T.Colors.class[T.MyClass] or C.General.BorderColor
	Toolkit.Settings.UIScale = C.General.UIScale

	if C.General.HideShadows then
		Toolkit.Settings.ShadowTexture = ""
	end
end

function Loading:MergeDatabase()
	if TukuiData then
		TukuiDatabase["Variables"] = TukuiData

		TukuiData = nil
	end

	if TukuiSettingsPerCharacter then
		TukuiDatabase["Settings"] = TukuiSettingsPerCharacter

		TukuiSettingsPerCharacter = nil
	end

	if TukuiGold then
		TukuiDatabase["Gold"] = TukuiGold

		TukuiGold = nil
	end

	if TukuiChatHistory then
		TukuiDatabase["ChatHistory"] = TukuiChatHistory

		TukuiChatHistory = nil
	end
end

function Loading:VerifyDatabase()
	if not TukuiDatabase then
		TukuiDatabase = {}
	end

	-- VARIABLES
	if not TukuiDatabase.Variables then
		TukuiDatabase.Variables = {}
	end

	if not TukuiDatabase.Variables[T.MyRealm] then
		TukuiDatabase.Variables[T.MyRealm] = {}
	end

	if not TukuiDatabase.Variables[T.MyRealm][T.MyName] then
		TukuiDatabase.Variables[T.MyRealm][T.MyName] = {}
	end

	if not TukuiDatabase.Variables[T.MyRealm][T.MyName].Move then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Move = {}
	end

	if not TukuiDatabase.Variables[T.MyRealm][T.MyName].ActionBars then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].ActionBars = {}
	end

	if not TukuiDatabase.Variables[T.MyRealm][T.MyName].Tracking then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Tracking = {}
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Tracking.PvP = {}
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Tracking.PvE = {}
	end

	if (not TukuiDatabase.Variables[T.MyRealm][T.MyName].DataTexts) then
		local DataTexts = T.DataTexts

		DataTexts:AddDefaults()
	end

	if not TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat = {}

		if not TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat.Positions then
			TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat.Positions = T.Chat.Positions
		end
	else
		-- We recently changed this table, make sure it work with our new layout
		if not TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat.Positions then
			-- Reset Chat Database
			TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat = {}

			-- Set frames position default
			TukuiDatabase.Variables[T.MyRealm][T.MyName].Chat.Positions = T.Chat.Positions

			-- Warn user
			T.Print("|CFFFF0000WARNING:|r Your chat position have been reset to default")
		end
	end

	if (not TukuiDatabase.Variables[T.MyRealm][T.MyName].Misc) then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Misc = {}
	end

	if (not TukuiDatabase.Variables[T.MyRealm][T.MyName].Installation) then
		TukuiDatabase.Variables[T.MyRealm][T.MyName].Installation = {}
	end

	-- SETTINGS
	if (not TukuiDatabase.Settings) then
		TukuiDatabase.Settings = {}
	end

	if not TukuiDatabase.Settings[T.MyRealm] then
		TukuiDatabase.Settings[T.MyRealm] = {}
	end

	if not TukuiDatabase.Settings[T.MyRealm][T.MyName] then
		TukuiDatabase.Settings[T.MyRealm][T.MyName] = {}
	end

	-- Chat History
	if not TukuiDatabase.ChatHistory then
		TukuiDatabase.ChatHistory = {}
	end

	-- Gold
	if not TukuiDatabase.Gold then
		TukuiDatabase.Gold = {}
	end
end

function Loading:RemoveEditFrame(frame)
	if not T.Retail then
		return
	end
	
	for i, f in pairs(EditModeManagerFrame.registeredSystemFrames) do
		local Frame = f
		local Name = Frame:GetName()
		
		if frame == Name then
			table.remove(EditModeManagerFrame.registeredSystemFrames, i)
		end
	end
end

-- The player name can still be "Unknown" when Tukui files load (Init.lua), which
-- makes the whole session read/write settings under an "Unknown" character.
local IsUnknownName = function(Name)
	return not Name or Name == "" or Name == UNKNOWNOBJECT or Name == UKNOWNBEING or Name == "Unknown" or Name == "Неизвестно"
end

function Loading:UpdatePlayerName()
	local Name = UnitName("player")
	local Realm = GetRealmName()

	if not IsUnknownName(Name) then
		T.MyName = Name
	end

	if Realm and Realm ~= "" then
		T.MyRealm = Realm
	end

	return not IsUnknownName(T.MyName)
end

-- Settings saved while the name was still unknown ended up under fake "Unknown"/"Неизвестно"
-- characters: move them to the real character (without overriding its own values), once.
function Loading:MergeUnknownCharacters()
	if IsUnknownName(T.MyName) or not TukuiDatabase or not TukuiDatabase.Settings then
		return
	end

	local Realm = TukuiDatabase.Settings[T.MyRealm]

	if not Realm then
		return
	end

	Realm[T.MyName] = Realm[T.MyName] or {}

	local Mine = Realm[T.MyName]

	for Name, Settings in pairs(Realm) do
		if Name ~= T.MyName and IsUnknownName(Name) then
			for Group, Options in pairs(Settings) do
				if type(Options) == "table" then
					Mine[Group] = Mine[Group] or {}

					for Option, Value in pairs(Options) do
						if Mine[Group][Option] == nil then
							Mine[Group][Option] = Value
						end
					end
				end
			end

			Realm[Name] = nil
		end
	end

	-- frame positions moved in such a session: keep the ones the real character doesn't have
	local Variables = TukuiDatabase.Variables and TukuiDatabase.Variables[T.MyRealm]
	local MyMove = Variables and Variables[T.MyName] and Variables[T.MyName].Move

	if Variables then
		for Name, Data in pairs(Variables) do
			if Name ~= T.MyName and IsUnknownName(Name) then
				if MyMove and type(Data.Move) == "table" then
					for Frame, Position in pairs(Data.Move) do
						if MyMove[Frame] == nil then
							MyMove[Frame] = Position
						end
					end
				end

				Variables[Name] = nil
			end
		end
	end

	-- gold of the fake characters would show up in the gold datatext
	local Gold = TukuiDatabase.Gold and TukuiDatabase.Gold[T.MyRealm]

	if Gold then
		for Name in pairs(Gold) do
			if Name ~= T.MyName and IsUnknownName(Name) then
				Gold[Name] = nil
			end
		end
	end
end

-- Saved settings, fonts and the config GUI. Tukui used to do this on VARIABLES_LOADED only,
-- but on this client a fresh login fires VARIABLES_LOADED after PLAYER_LOGIN (and even after
-- PLAYER_ENTERING_WORLD), so every module enabled on PLAYER_LOGIN ran with default settings
-- until a /reload. Now it runs once, on whichever of the two comes first.
function Loading:LoadSettings()
	if self.SettingsLoaded then
		return
	end

	self.SettingsLoaded = true
	self.SettingsLoadedFor = T.MyRealm.."-"..T.MyName

	self:MergeUnknownCharacters()

	local Locale = GetLocale()

	T["Loading"]:Enable()

	-- ruRU used to be excluded too, but Expressway, PT Sans Narrow and Ubuntu Condensed all
	-- have Cyrillic (also fixed "Locale and" -> "Locale ~=")
	if (Locale ~= "koKR" and Locale ~= "zhTW" and Locale ~= "zhCN") then
		C.Medias.Font = C.General.GlobalFont.Value

		TukuiFont:SetFont(C.Medias.Font, 12, "")
		TukuiFontOutline:SetFont(C.Medias.Font, 12, "THINOUTLINE")
	end

	if (Locale ~= "koKR" and Locale ~= "zhTW" and Locale ~= "zhCN") then
		T["Fonts"]:Enable()
	end

	T["GUI"]:Enable()
	T["Profiles"]:Enable()
	T["Help"]:Enable()
end

function Loading:OnEvent(event)
	self:UpdatePlayerName()

	-- We verify everything is ok with our savedvariables
	self:VerifyDatabase()

	-- Patch 9.0 was using different table to save settings, when players will hit 9.1, we need to move their settings into our new table
	self:MergeDatabase()

	if (event == "PLAYER_LOGIN") then
		self:LoadSettings()

		T["Inventory"]:Enable()
		T["Auras"]:Enable()
		T["Maps"]["Minimap"]:Enable()
		T["Maps"]["Zonemap"]:Enable()
		T["Maps"]["Worldmap"]:Enable()
		T["DataTexts"]:Enable()
		T["Chat"]:Enable()
		
		if not T.Retail then
			T["ActionBars"]:Enable()
		end
		
		T["Cooldowns"]:Enable()
		T["Miscellaneous"]:Enable()
		T["UnitFrames"]:Enable()
		T["Tooltips"]:Enable()

		if T.Retail then
			T["PetBattles"]:Enable()
		end

		-- restore original stopwatch commands
		SlashCmdList["STOPWATCH"] = Stopwatch_Toggle
	elseif (event == "PLAYER_ENTERING_WORLD") then
		-- WIP
		if not T.MoP then
			T["Miscellaneous"]["ObjectiveTracker"]:Enable()
		end
	elseif (event == "VARIABLES_LOADED") then
		self:LoadSettings()
	end

	-- On a fresh game start the character name may not be known yet at PLAYER_LOGIN, so
	-- the settings were read from the wrong character bucket (defaults): read them again
	-- once the real name shows up and re-apply what can be changed live.
	-- The name can stay unknown through all load events: keep asking until the game knows it
	if not self:UpdatePlayerName() and not self.NameTicker then
		self.NameTicker = C_Timer.NewTicker(1, function(Ticker)
			if Loading:UpdatePlayerName() then
				Ticker:Cancel()
				Loading.NameTicker = nil
				Loading:OnEvent("TUKUI_PLAYER_NAME_KNOWN")
			end
		end, 120)
	end

	if self.SettingsLoaded and self.SettingsLoadedFor ~= T.MyRealm.."-"..T.MyName and TukuiDatabase.Settings[T.MyRealm] then
		self.SettingsLoadedFor = T.MyRealm.."-"..T.MyName
		self:MergeUnknownCharacters()
		TukuiDatabase.Settings[T.MyRealm][T.MyName] = TukuiDatabase.Settings[T.MyRealm][T.MyName] or {}
		self:LoadCustomSettings()

		if T["Auras"].ApplyLayout then
			T["Auras"]:ApplyLayout()
		end
	end

	if (event == "SETTINGS_LOADED") then
		T["ActionBars"]:Enable()
	end
	
	if T.Retail and EditModeManagerFrame then
		EditModeManagerFrame:UnregisterAllEvents()
		EditModeManagerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED");
	end
end

Loading:RegisterEvent("PLAYER_LOGIN")
Loading:RegisterEvent("VARIABLES_LOADED")
Loading:RegisterEvent("PLAYER_ENTERING_WORLD")

if T.Retail then
	Loading:RegisterEvent("SETTINGS_LOADED")
end

Loading:SetScript("OnEvent", Loading.OnEvent)

T["Loading"] = Loading
