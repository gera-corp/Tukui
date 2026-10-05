local _, ns = ...
local oUF = ns.oUF

-- Forever: Blizzard's TextStatusBar/CastingBarFrame/CompactUnitFrame mixins come
-- from LoadOnDemand addons (Blizzard_TextStatusBar, Blizzard_UIPanels_Game,
-- Blizzard_UnitFrame), which load AFTER Tukui. Their methods compare/boolean-test
-- secret values (nameplate health/power/cast bars) and taint when triggered.
--
-- Mixin-level overrides do NOT reach nameplate bars: the mixin methods are copied
-- into each frame at creation time, and nameplate frames are pooled at UI load,
-- before Tukui. So we neutralize on the frames themselves, before SetValue runs.

local function neutralizeStatusBarText(frame)
	if not frame or frame.__tukuiTextNeutralized then return end
	frame.__tukuiTextNeutralized = true
	frame.UpdateTextString = function() end
	frame.UpdateTextStringWithValues = function() end
end

local function neutralizeCompactUnitFrame()
	-- Forever: every CompactUnitFrame_Update* function compares/boolean-tests
	-- secret values (health color, in-range, status text, name, level, aggro...).
	-- Tukui replaces ALL Blizzard compact frames (party/raid/arena/boss/nameplate)
	-- with its own oUF frames, so freeze the entire Blizzard update cycle at once
	-- instead of whack-a-mole per function. The health/power wrappers keep the
	-- statusbar text path (SetValue -> UpdateTextString) neutralized too.
	local function noopFunc(name)
		if _G[name] and not _G['__tukui_' .. name] then
			_G['__tukui_' .. name] = true
			_G[name] = function() end
		end
	end

	noopFunc('CompactUnitFrame_UpdateAll')
	noopFunc('CompactUnitFrame_UpdateHealth')
	noopFunc('CompactUnitFrame_UpdatePower')
	noopFunc('CompactUnitFrame_UpdateHealthColor')
	noopFunc('CompactUnitFrame_UpdatePowerColor')
	noopFunc('CompactUnitFrame_UpdateInRange')
	noopFunc('CompactUnitFrame_UpdateStatusText')
	noopFunc('CompactUnitFrame_UpdateName')
	noopFunc('CompactUnitFrame_UpdateLevel')
	noopFunc('CompactUnitFrame_UpdateSelectionHighlight')
	noopFunc('CompactUnitFrame_UpdateAggroHighlight')
	noopFunc('CompactUnitFrame_UpdateHealthBorder')
	noopFunc('CompactUnitFrame_UpdateMaxHealth')
	noopFunc('CompactUnitFrame_UpdateMaxPower')

	-- Forever: UnitFrameHealthBar_Update/UnitFrameManaBar_Update are Blizzard's
	-- global health/power updaters for non-compact frames (player/target/party/
	-- raid). They compare secret values (UnitHealthMax == 0, currValue from
	-- UnitHealth) and taint when triggered via securecall from EditMode's
	-- UpdateSystems. Tukui hides these Blizzard frames and draws its own oUF,
	-- so freezing them is safe.
	noopFunc('UnitFrameHealthBar_Update')
	noopFunc('UnitFrameManaBar_Update')
	-- These are installed via SetScript("OnUpdate", ...) on player/target/etc.
	-- bars; a global noop alone won't stop an already-set script, but it stops
	-- any re-install (e.g. UnitFrameManaBar_OnEvent VARIABLES_LOADED re-set).
	-- The handleFrame path also clears OnUpdate on the frames directly.
	noopFunc('UnitFrameHealthBar_OnUpdate')
	noopFunc('UnitFrameManaBar_OnUpdate')

	-- Forever: UnitFrameHealPredictionBars_Update reads UnitGetIncomingHeals /
	-- UnitGetTotalAbsorbs / UnitGetTotalHealAbsorbs, which return secret numbers
	-- in combat, and compares them (health < myCurrentHealAbsorb). Called from
	-- UnitFrameHealthBar_Update (also frozen) and GROUP_ROSTER_UPDATE. Tukui
	-- draws its own oUF health-prediction, so freezing is safe.
	noopFunc('UnitFrameHealPredictionBars_Update')
	noopFunc('UnitFrameHealPredictionBars_UpdateMax')
	noopFunc('UnitFrameHealPredictionBars_UpdateSize')
end

local function neutralizeCastingBarMixin()
	local mixin = _G.CastingBarFrameMixin
	if mixin then
		mixin.ShouldIconBeShown = function() return false end
		mixin.UpdateIconShown = function() end
		mixin.SetIconShown = function() end
	end

	-- Forever: the nameplate castbar (NamePlateCastingBarMixin) is built via
	-- CreateFromMixins(CastingBarMixin, ...), which COPIES methods (pairs) into
	-- a fresh table rather than using a metatable. So overriding CastingBarMixin
	-- does NOT reach it (and the copy may happen before our noop if
	-- Blizzard_NamePlates loads first). Override NamePlateCastingBarMixin
	-- directly too. HandleCastStart/GetEffectiveType do boolean-tests and
	-- arithmetic on secret values (notInterruptible, startTime/endTime from
	-- UnitCastingInfo on a secret enemy) and taint.
	-- Tukui draws its own oUF castbars and hides all Blizzard castbars, so
	-- freezing the cast cycle is safe.
	local baseMixin = _G.CastingBarMixin
	if baseMixin then
		baseMixin.HandleCastStart = function() end
		baseMixin.HandleCastStop = function() end
		baseMixin.HandleCastDelayed = function() end
		baseMixin.HandleChannelUpdateDelayed = function() end
		baseMixin.HandleInterruptOrSpellFailed = function() end
		baseMixin.GetEffectiveType = function() end
	end

	local namePlateMixin = _G.NamePlateCastingBarMixin
	if namePlateMixin then
		namePlateMixin.HandleCastStart = function() end
		namePlateMixin.HandleCastStop = function() end
		namePlateMixin.HandleCastDelayed = function() end
		namePlateMixin.HandleChannelUpdateDelayed = function() end
		namePlateMixin.HandleInterruptOrSpellFailed = function() end
		namePlateMixin.GetEffectiveType = function() end
	end
end

local function neutralizeTextStatusBarMixin()
	local mixin = _G.TextStatusBarMixin
	if not mixin then return end
	mixin.OnValueChanged = function() end
	mixin.UpdateTextString = function() end
	mixin.UpdateTextStringWithValues = function() end
end

local function neutralizeNamePlateUnitFrameMixin()
	local mixin = _G.NamePlateUnitFrameMixin
	if not mixin then return end
	if mixin.UpdateCastBarDisplay then
		mixin.UpdateCastBarDisplay = function() end
	end
	-- Forever: UpdateAnchors calls GetPoint() (frame measurement) on restricted
	-- regions, which taints when triggered from OnUnitSet before our hooks run.
	if mixin.UpdateAnchors then
		mixin.UpdateAnchors = function() end
	end
	if mixin.UpdateShowOnlyName then
		mixin.UpdateShowOnlyName = function() end
	end
	if mixin.UpdateIsPlayer then
		mixin.UpdateIsPlayer = function() end
	end
end

-- Forever: Blizzard's nameplate aura container (NamePlateAurasMixin) runs its
-- own aura cycle on OnNamePlateAdded -> SetUnit -> RefreshAuras -> ParseAllAuras
-- -> C_UnitAuras.GetUnitAuras, which throws "Auras cannot be accessed when
-- secret" on enemy nameplates. Tukui hides the Blizzard nameplate entirely via
-- DisableNamePlate and draws its own oUF auras, so freeze the aura cycle.
local function neutralizeNamePlateAurasMixin()
	local mixin = _G.NamePlateAurasMixin
	if not mixin then return end
	if mixin.ParseAllAuras then
		mixin.ParseAllAuras = function() end
	end
	if mixin.RefreshAuras then
		mixin.RefreshAuras = function() end
	end
	if mixin.AddAura then
		mixin.AddAura = function() end
	end
	if mixin.UpdateAura then
		mixin.UpdateAura = function() end
	end
	if mixin.GetLossOfControlAura then
		mixin.GetLossOfControlAura = function() end
	end
	if mixin.RefreshLossOfControl then
		mixin.RefreshLossOfControl = function() end
	end
	if mixin.RefreshExplicitAuras then
		mixin.RefreshExplicitAuras = function() end
	end
end

local function neutralizePartyRaidAuras()
	-- Forever: GROUP_ROSTER_UPDATE routes through Blizzard_Game's
	-- HandleGroupRosterUpdate -> UpdateRaidAndPartyFrames (Blizzard_RaidFrame)
	-- -> PartyFrame:UpdatePartyFrames() -> UpdateMember() -> UpdateAuras()
	-- -> PartyMemberAuraMixin:ParseAllAuras() -> ForEachAura -> GetAuraSlots,
	-- which throws "Auras cannot be accessed when secret" on party/raid members
	-- in combat. Tukui hides the Blizzard party/raid frames and draws its own
	-- oUF frames, but UpdateRaidAndPartyFrames is a global called directly, so
	-- hiding the frame does not stop it. Freeze the whole update cycle.
	local function noopFunc(name)
		if _G[name] and not _G['__tukui_' .. name] then
			_G['__tukui_' .. name] = true
			_G[name] = function() end
		end
	end

	noopFunc('UpdateRaidAndPartyFrames')
end

local function neutralizeUnitFrameBars()
	-- Forever: UnitFrameHealthBar_OnUpdate / UnitFrameManaBar_OnUpdate are set
	-- via statusbar:SetScript("OnUpdate", ...) inside UnitFrame*_Initialize,
	-- which runs when Blizzard_UnitFrame (LoadOnDemand) loads at
	-- PLAYER_ENTERING_WORLD -- AFTER our ADDON_LOADED hook and after
	-- VARIABLES_LOADED. So a global noop (set on ADDON_LOADED) does not stop
	-- the already-installed OnUpdate reference, and VARIABLES_LOADED won't
	-- re-fire to reset it. Remove the OnUpdate script directly from each bar.
	local frames = { 'PlayerFrame', 'PetFrame', 'TargetFrame', 'FocusFrame' }
	for i = 1, 5 do
		table.insert(frames, 'Boss' .. i .. 'TargetFrame')
		table.insert(frames, 'CompactPartyFrameMember' .. i)
	end

	for _, name in ipairs(frames) do
		local frame = _G[name]
		if frame then
			local health = frame.healthBar or frame.healthbar or frame.HealthBar
			local power = frame.manabar or frame.ManaBar or frame.PowerBar
			if health then
				health:SetScript('OnUpdate', nil)
			end
			if power then
				power:SetScript('OnUpdate', nil)
			end
		end
	end
end

local function neutralizeAll()
	-- Tukui: the global/mixin no-op overrides below are disabled. Replacing Blizzard globals
	-- and mixin methods with addon functions taints every Blizzard caller: Blizzard's code
	-- then fails on secret values (the very errors these overrides were meant to hide) and,
	-- worse, forbidden nameplates are built from the same mixins and error out with
	-- "Attempt to access forbidden object from code tainted by an AddOn". Blizzard's own,
	-- untainted code handles secret values fine. Only the script removal is kept (it doesn't
	-- put addon code anywhere Blizzard reads).
	--neutralizeCompactUnitFrame()
	--neutralizeCastingBarMixin()
	--neutralizeTextStatusBarMixin()
	--neutralizeNamePlateUnitFrameMixin()
	--neutralizeNamePlateAurasMixin()
	neutralizeUnitFrameBars()
	--neutralizePartyRaidAuras()
end

local mixinHook = CreateFrame('Frame')
mixinHook:RegisterEvent('ADDON_LOADED')
mixinHook:SetScript('OnEvent', function(_, _, addon)
	if addon == 'Blizzard_UIPanels_Game' or addon == 'Blizzard_TextStatusBar' or addon == 'Blizzard_NamePlates' or addon == 'Blizzard_UnitFrame' or addon == 'Blizzard_RaidFrame' then
		neutralizeAll()
	end
end)

-- Try immediately in case they are already loaded.
neutralizeAll()

-- sourced from Blizzard_UnitFrame/TargetFrame.lua
local MAX_BOSS_FRAMES = _G.MAX_BOSS_FRAMES or 5

-- sourced from Blizzard_FrameXMLBase/Shared/Constants.lua
local MEMBERS_PER_RAID_GROUP = _G.MEMBERS_PER_RAID_GROUP or 5

local hookedFrames = {}
local hookedNameplates = {}
local isArenaHooked = false
local isBossHooked = false
local isPartyHooked = false

local hiddenParent = CreateFrame('Frame', nil, UIParent)
hiddenParent:SetAllPoints()
hiddenParent:Hide()

local function insecureHide(self)
	self:Hide()
end

local function resetParent(self, parent)
	if(parent ~= hiddenParent) then
		self:SetParent(hiddenParent)
	end
end

local function handleFrame(baseName, doNotReparent)
	local frame
	if(type(baseName) == 'string') then
		frame = _G[baseName]
	else
		frame = baseName
	end

	if(frame) then
		frame:UnregisterAllEvents()
		frame:Hide()

		if(not doNotReparent) then
			frame:SetParent(hiddenParent)

			if(not hookedFrames[frame]) then
				hooksecurefunc(frame, 'SetParent', resetParent)

				hookedFrames[frame] = true
			end
		end

		local health = frame.healthBar or frame.healthbar or frame.HealthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
		if(health) then
			health:UnregisterAllEvents()
			-- (Tukui: no health.forceHideText = true - Blizzard reads it when the character frame
			-- opens, which taints the bar and closing the frame then fails on secret health.)

			-- Forever: UnitFrameHealthBar_OnUpdate reads UnitHealth (secret) and
			-- compares it; it's installed via SetScript("OnUpdate", ...), so a
			-- global noop doesn't stop it. Remove the OnUpdate script itself.
			health:SetScript("OnUpdate", nil)

			-- (Tukui: no method overrides on Blizzard's bars anymore - addon functions there
			-- taint Blizzard's own code paths. Events and OnUpdate are removed above.)
		end

		local power = frame.manabar or frame.ManaBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.powerBar)
		if(power) then
			power:UnregisterAllEvents()
			-- (Tukui: no power.forceHideText = true - Blizzard reads it when the character frame
			-- opens, which taints the bar and closing the frame then fails on secret health.)

			-- Forever: UnitFrameManaBar_OnUpdate reads UnitPower (secret) and
			-- compares it; remove the OnUpdate script itself.
			power:SetScript("OnUpdate", nil)
		end

		local spell = frame.castBar or frame.spellbar or frame.CastingBarFrame or frame.CastBar or (frame.CastBarsContainer and frame.CastBarsContainer.castBar)
		if(spell) then
			spell:UnregisterAllEvents()

			-- (Tukui: the castbar method overrides that used to be here are gone: addon
			-- functions on Blizzard frames taint Blizzard's code. Its events are removed above.)
		end

		local altpowerbar = frame.powerBarAlt or frame.PowerBarAlt
		if(altpowerbar) then
			altpowerbar:UnregisterAllEvents()
		end

		local buffFrame = frame.BuffFrame
		if(buffFrame) then
			buffFrame:UnregisterAllEvents()
		end

		local petFrame = frame.petFrame or frame.PetFrame
		if(petFrame) then
			petFrame:UnregisterAllEvents()
		end

		local totFrame = frame.totFrame
		if(totFrame) then
			totFrame:UnregisterAllEvents()
		end

		local classPowerBar = frame.classPowerBar
		if(classPowerBar) then
			classPowerBar:UnregisterAllEvents()
		end

		local ccRemoverFrame = frame.CcRemoverFrame
		if(ccRemoverFrame) then
			ccRemoverFrame:UnregisterAllEvents()
		end

		local debuffFrame = frame.DebuffFrame
		if(debuffFrame) then
			debuffFrame:UnregisterAllEvents()
		end
	end
end

function oUF:DisableBlizzard(unit)
	if(not unit) then return end

	if(unit == 'player') then
		handleFrame(PlayerFrame)
	elseif(unit == 'pet') then
		handleFrame(PetFrame)
	elseif(unit == 'target') then
		handleFrame(TargetFrame)
	elseif(unit == 'focus') then
		handleFrame(FocusFrame)
	elseif(unit:match('boss%d?$')) then
		if(not isBossHooked) then
			isBossHooked = true

			-- it's needed because the layout manager can bring frames that are
			-- controlled by containers back from the dead when a user chooses
			-- to revert all changes
			-- for now I'll just reparent it, but more might be needed in the
			-- future, watch it
			handleFrame(BossTargetFrameContainer)

			-- do not reparent frames controlled by containers, the vert/horiz
			-- layout code will go insane because it won't be able to calculate
			-- the size properly, 0 or negative sizes in turn will break the
			-- layout manager, fun...
			for i = 1, MAX_BOSS_FRAMES do
				handleFrame('Boss' .. i .. 'TargetFrame', true)
			end
		end
	elseif(unit:match('party%d?$')) then
		if(not isPartyHooked) then
			isPartyHooked = true

			handleFrame(PartyFrame)

			for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
				handleFrame(frame, true)
			end

			for i = 1, MEMBERS_PER_RAID_GROUP do
				handleFrame('CompactPartyFrameMember' .. i)
			end
		end
	elseif(unit:match('arena%d?$')) then
		if(not isArenaHooked) then
			isArenaHooked = true

			if CompactArenaFrame then
				handleFrame(CompactArenaFrame)

				for _, frame in next, CompactArenaFrame.memberUnitFrames do
					handleFrame(frame, true)
				end
			end
		end
	end
end

function oUF:DisableNamePlate(frame)
	if(not(frame and frame.UnitFrame)) then return end
	if(frame.UnitFrame:IsForbidden()) then return end

	-- Keyed by the unit frame, not the nameplate: on this client Blizzard hands each
	-- nameplate a unit frame from a pool on every NAME_PLATE_UNIT_ADDED, so hooking only the
	-- first one per nameplate left later ones visible (e.g. their soft-target icon).
	if(not hookedNameplates[frame.UnitFrame]) then
		frame.UnitFrame:HookScript('OnShow', insecureHide)

		hookedNameplates[frame.UnitFrame] = true
	end

	handleFrame(frame.UnitFrame, true)
end
