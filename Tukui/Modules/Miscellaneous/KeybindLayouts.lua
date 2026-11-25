local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Layouts = CreateFrame("Frame")

-- Key bindings that work in both the English and the Russian keyboard layout.
-- The game binds a key by the character it types, so a binding made on Q doesn't fire
-- while the Russian layout is on (the same key types Й), and the other way round.
-- Every binding on one of these keys gets a copy on the other layout's key, with the
-- same modifiers. Removing or changing a binding also removes or changes its copy.
-- Copies are remembered per binding set, so a key the player bound on their own is never
-- touched.
local Pairs = {
	{"Q", "Й"}, {"W", "Ц"}, {"E", "У"}, {"R", "К"}, {"T", "Е"}, {"Y", "Н"}, {"U", "Г"},
	{"I", "Ш"}, {"O", "Щ"}, {"P", "З"}, {"[", "Х"}, {"]", "Ъ"},
	{"A", "Ф"}, {"S", "Ы"}, {"D", "В"}, {"F", "А"}, {"G", "П"}, {"H", "Р"}, {"J", "О"},
	{"K", "Л"}, {"L", "Д"}, {";", "Ж"}, {"'", "Э"},
	{"Z", "Я"}, {"X", "Ч"}, {"C", "С"}, {"V", "М"}, {"B", "И"}, {"N", "Т"}, {"M", "Ь"},
	{",", "Б"}, {".", "Ю"}, {"`", "Ё"},
	-- Ё is outside the А-Я range: the client may name that key in lower case
	{"`", "ё"},
}

local Modifiers = {"", "SHIFT-", "CTRL-", "CTRL-SHIFT-", "ALT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-"}

local Syncing = false
local Pending = false

local Action = function(Key)
	return GetBindingAction(Key) or ""
end

-- Copies made by Tukui: key -> action Tukui put on it
local GetCopies = function()
	local Set = GetCurrentBindingSet and GetCurrentBindingSet() or 2
	local Store

	if Set == 1 then
		TukuiDatabase.KeybindCopies = TukuiDatabase.KeybindCopies or {}
		Store = TukuiDatabase.KeybindCopies
	else
		local Data = TukuiDatabase.Variables[T.MyRealm][T.MyName]

		Data.KeybindCopies = Data.KeybindCopies or {}
		Store = Data.KeybindCopies
	end

	return Store
end

-- Keys the client doesn't accept (SetBinding doesn't stick): skipped, so a failed copy
-- isn't retried (and saved) on every binding update
local Unsupported = {}

local Copy = function(Copies, Key, Command)
	SetBinding(Key, Command)

	if Action(Key) ~= Command then
		Unsupported[Key] = true

		return false
	end

	Copies[Key] = Command

	return true
end

-- Returns true when a binding was changed
local SyncPair = function(Copies, Key1, Key2)
	if Unsupported[Key1] or Unsupported[Key2] then
		return false
	end

	local Action1, Action2 = Action(Key1), Action(Key2)
	local Copy1, Copy2 = Copies[Key1], Copies[Key2]

	-- A copy the player changed or removed
	if Copy1 and Copy1 ~= Action1 then
		Copies[Key1] = nil

		if Action1 == "" and Action2 == Copy1 then
			SetBinding(Key2)

			return true
		end

		Copy1 = nil
	end

	if Copy2 and Copy2 ~= Action2 then
		Copies[Key2] = nil

		if Action2 == "" and Action1 == Copy2 then
			SetBinding(Key1)

			return true
		end

		Copy2 = nil
	end

	if Action1 == Action2 then
		return false
	end

	if Action2 == "" then
		if Copy1 then
			-- the original binding was removed: remove its copy
			SetBinding(Key1)
			Copies[Key1] = nil
		else
			return Copy(Copies, Key2, Action1)
		end

		return true
	elseif Action1 == "" then
		if Copy2 then
			SetBinding(Key2)
			Copies[Key2] = nil
		else
			return Copy(Copies, Key1, Action2)
		end

		return true
	elseif Copy2 then
		-- the original key got another action: the copy follows it
		return Copy(Copies, Key2, Action1)
	elseif Copy1 then
		return Copy(Copies, Key1, Action2)
	end

	-- both keys have their own, different bindings: leave them
	return false
end

-- Not while a key binding window is open: it may still cancel its changes
local IsBindingWindowOpen = function()
	return (QuickKeybindFrame and QuickKeybindFrame:IsShown())
		or (KeyBindingFrame and KeyBindingFrame:IsShown())
		or (SettingsPanel and SettingsPanel:IsShown())
		or (T.Miscellaneous.Keybinds and T.Miscellaneous.Keybinds.enabled)
end

function Layouts:Sync()
	Pending = false

	if Syncing or not TukuiDatabase then
		return
	end

	if InCombatLockdown() or IsBindingWindowOpen() then
		Pending = true

		return
	end

	Syncing = true

	local Copies = GetCopies()
	local Changed = false

	for _, Pair in ipairs(Pairs) do
		for _, Modifier in ipairs(Modifiers) do
			if SyncPair(Copies, Modifier .. Pair[1], Modifier .. Pair[2]) then
				Changed = true
			end
		end
	end

	if Changed then
		SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 2)
	end

	Syncing = false
end

function Layouts:OnEvent(event)
	if event == "PLAYER_REGEN_ENABLED" and not Pending then
		return
	end

	-- bindings change several times in a row (and SaveBindings fires UPDATE_BINDINGS again)
	if not self.Timer then
		self.Timer = true

		C_Timer.After(1, function()
			self.Timer = nil
			self:Sync()
		end)
	end
end

function Layouts:Enable()
	if not C.Misc.KeybindLayouts or not SetBinding or not GetBindingAction then
		return
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:SetScript("OnEvent", self.OnEvent)

	-- binding windows: sync once they are closed
	C_Timer.NewTicker(2, function()
		if Pending and not InCombatLockdown() and not IsBindingWindowOpen() then
			Layouts:Sync()
		end
	end)
end

Miscellaneous.KeybindLayouts = Layouts
