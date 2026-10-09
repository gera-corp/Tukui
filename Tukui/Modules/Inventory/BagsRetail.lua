local T, C, L = unpack((select(2, ...)))

--[[ THIS BAG MODULE IS CURRENTLY WORK IN PROGRESS]]
local ContainerFrameCombinedBags = _G.ContainerFrameCombinedBags
local C_Container = _G.C_Container
local C_Item = _G.C_Item

local Bags = CreateFrame("Frame")
local Inventory = T["Inventory"]
local Movers = T["Movers"]
local Noop = function() end

function Bags:SkinButton(Button)
	if not Button or Button.IsSkinned then
		return
	end

	local Normal = Button:GetNormalTexture()

	-- Blizzard paints empty slots by putting the "bags-item-slot64" atlas on the icon
	-- itself. Without it the icon just hides and Tukui's flat backdrop shows through.
	Button.emptyBackgroundAtlas = nil
	Button.emptyBackgroundTexture = nil

	if Normal then
		Normal:SetAlpha(0)
	end

	Button.IconBorder:SetAlpha(0)
	Button.IconQuestTexture:SetAlpha(0)

	-- Hide the golden slot frame Blizzard adds to item buttons in combined-bags mode.
	if Button.ItemSlotBackground then
		Button.ItemSlotBackground:Hide()
	end

	Button.icon:SetTexCoord(unpack(T.IconCoord))
	Button.icon:SetInside(Button)

	-- An empty slot still carries the atlas applied before we skinned it, drop it
	if not C_Container.GetContainerItemInfo(Button:GetBagID(), Button:GetID()) then
		Button.icon:SetTexture(nil)
		Button.icon:Hide()
	end

	Button:CreateBackdrop()
	Button.Backdrop:SetFrameLevel(math.max(0, Button:GetFrameLevel() - 1))
	Button:StyleButton()

	Button.IsSkinned = true
end

-- Bag slot bar (backpack + bag slots), rebuilt as a Tukui-style movable bar.
-- Left to right, same order as Blizzard's BagsBar.
local BagBarSlots = {
	"KeyRingButton",
	"CharacterReagentBag0Slot",
	"CharacterBag3Slot",
	"CharacterBag2Slot",
	"CharacterBag1Slot",
	"CharacterBag0Slot",
	"MainMenuBarBackpackButton",
}

function Bags:HideBagSlotArt(Button)
	local Normal = Button:GetNormalTexture()
	local Pushed = Button:GetPushedTexture()

	-- The default bag-slot / bag-main frame is an ATLAS applied via SetAtlas in
	-- UpdateTextures. Clearing the file does not clear the atlas, so hide via alpha
	-- (alpha persists across atlas re-application).
	if Normal then
		Normal:SetAlpha(0)
	end

	-- Blizzard may re-apply its atlas onto our own hover/pushed textures, repaint them
	if Button.Highlight then
		Button.Highlight:SetColorTexture(1, 1, 1, 0.3)
	end

	if Button.Pushed then
		Button.Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
	elseif Pushed then
		Pushed:SetAlpha(0)
	end

	if Button.SlotHighlightTexture then
		Button.SlotHighlightTexture:SetAlpha(0)
	end
end

function Bags:SkinBagSlot(Button)
	local Size = C.ActionBars.NormalButtonSize
	local Icon = Button.icon or _G[Button:GetName().."IconTexture"]
	local Count = Button.Count or _G[Button:GetName().."Count"]

	Button:SetNormalTexture("")
	Button:SetPushedTexture("")
	Button:SetHighlightTexture("")
	Bags:HideBagSlotArt(Button)

	if Button.IconBorder then
		Button.IconBorder:SetAlpha(0)
	end

	if Button.IconOverlay then
		Button.IconOverlay:SetAlpha(0)
	end

	if Button.QuickKeybindHighlightTexture then
		Button.QuickKeybindHighlightTexture:SetTexture("")
	end

	if Button.AnimIcon then
		Button.AnimIcon:SetAlpha(0)
	end

	-- Square Tukui look: swap the circular alpha mask for a solid square
	if Button.CircleMask then
		Button.CircleMask:SetTexture("Interface\\Buttons\\WHITE8x8")
	end

	Button:SetSize(Size, Size)

	if Icon then
		Icon:SetTexCoord(unpack(T.IconCoord))
		Icon:SetInside(Button)
		Icon:SetDrawLayer("BACKGROUND", 7)
	end

	if Count then
		Count:ClearAllPoints()
		Count:SetPoint("BOTTOMRIGHT", 1, 1)
		Count:SetFont(C.Medias.Font, 12, "OUTLINE")
	end

	Button:CreateBackdrop()
	Button.Backdrop:SetFrameLevel(math.max(0, Button:GetFrameLevel() - 1))
	Button:StyleButton()

	-- Ensure the slot accepts drag & drop so bags can be swapped.
	Button:RegisterForDrag("LeftButton")
	Button:EnableMouse(true)

	Button.IsSkinned = true
end

function Bags:UpdateBagBar()
	local Bar = Bags.BagBar
	local Size = C.ActionBars.NormalButtonSize
	local Spacing = C.ActionBars.ButtonSpacing
	local Shown = 0

	if not Bar then
		return
	end

	Bar.IsUpdating = true

	for _, Name in ipairs(BagBarSlots) do
		local Button = _G[Name]

		if Button and Button.IsSkinned then
			Button:ClearAllPoints()

			-- Anchor every slot to the bar itself, never to another slot: Blizzard's
			-- BagsBar layout chains slots to each other, so slot-to-slot anchors
			-- here would create circular anchor dependencies.
			if Button:IsShown() then
				Button:SetPoint("LEFT", Bar, "LEFT", Spacing + Shown * (Size + Spacing), 0)
				Button.TukuiOffset = Spacing + Shown * (Size + Spacing)

				Shown = Shown + 1
			end
		end
	end

	Bar:SetSize(math.max(Shown, 1) * (Size + Spacing) + Spacing, Size + (Spacing * 2))

	Bar.IsUpdating = false
end

-- True when Blizzard moved, showed or hid a slot since our last layout
function Bags:BagBarNeedsUpdate()
	local Bar = Bags.BagBar
	local Shown = 0

	for _, Name in ipairs(BagBarSlots) do
		local Button = _G[Name]

		if Button and Button.IsSkinned and Button:IsShown() then
			local Point, Relative, _, X = Button:GetPoint(1)

			if Point ~= "LEFT" or Relative ~= Bar or Button:GetNumPoints() ~= 1 or X ~= Button.TukuiOffset then
				return true
			end

			Shown = Shown + 1
		end
	end

	return Shown ~= Bar.NumShown
end

-- No hooks on Blizzard's bag buttons or BagsBar: this client calls their
-- SetPoint/Layout/UpdateTextures from inside secure actions (e.g. the cursor
-- change when casting from the spellbook), and addon hooks there break the call
-- ("attempt to call a nil value") and block the action. Poll from our own frame.
function Bags:WatchBagBar(Elapsed)
	self.Elapsed = (self.Elapsed or 0) + Elapsed

	if self.Elapsed < 0.1 then
		return
	end

	self.Elapsed = 0

	for _, Name in ipairs(BagBarSlots) do
		local Button = _G[Name]

		if Button and Button.IsSkinned then
			Bags:HideBagSlotArt(Button)
		end
	end

	if Bags:BagBarNeedsUpdate() then
		Bags:UpdateBagBar()

		local Shown = 0

		for _, Name in ipairs(BagBarSlots) do
			local Button = _G[Name]

			if Button and Button.IsSkinned and Button:IsShown() then
				Shown = Shown + 1
			end
		end

		self.NumShown = Shown
	end
end

function Bags:SkinBagBar()
	if not T.Retail then
		return
	end

	local Bar = CreateFrame("Frame", "TukuiBagBar", T.PetHider)

	Bar:SetFrameStrata("LOW")
	Bar:SetFrameLevel(10)

	-- Default spot: just above the right chat panel
	Bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -28, 20 - 6 + C.Chat.RightHeight + 6)

	if C.ActionBars.ShowBackdrop then
		Bar:CreateBackdrop()
		Bar:CreateShadow()
	end

	Bags.BagBar = Bar

	-- Always keep every bag slot visible (Blizzard collapses them otherwise)
	SetCVar("expandBagBar", 1)

	for _, Name in ipairs(BagBarSlots) do
		local Button = _G[Name]

		if Button and not Button.IsSkinned then
			Button:SetParent(Bar)
			Bags:SkinBagSlot(Button)
		end
	end

	-- Blizzard's own bag bar is now empty, hide it (and its expand arrow)
	if BagsBar then
		BagsBar:SetParent(T.Hider)
	end

	Bags:UpdateBagBar()

	-- Blizzard's BagsBar layout re-anchors the slots now and then, put them back
	Bar:SetScript("OnUpdate", Bags.WatchBagBar)

	Movers:RegisterFrame(Bar, "Bag Bar")
end

function Bags:SkinButtons()
	local Bag = ContainerFrameCombinedBags
	local Reagent = ContainerFrame6

	for i, Button in Bag:EnumerateValidItems() do
		Bags:SkinButton(Button)
	end

	for i, Button in Reagent:EnumerateValidItems() do
		Bags:SkinButton(Button)
	end
end

function Bags.QuestItem(Button)
	local BagID = Button:GetBagID()
	local QuestInfo = C_Container.GetContainerItemQuestInfo(BagID, Button:GetID())
	local IsQuestItem = QuestInfo.isQuestItem
	local QuestID = QuestInfo.questID
	local IsActive = QuestInfo.isActive

	-- items starting quests are not considered quest items by Blizzard, mark them anyway
	if IsQuestItem or QuestID then
		if not Button.Quest then
			Button.Quest = CreateFrame("Frame", nil, Button)
			Button.Quest:SetFrameLevel(Button:GetFrameLevel())
			Button.Quest:SetSize(8, Button:GetHeight() - 2)
			Button.Quest:SetPoint("TOPLEFT", 1, -1)

			Button.Quest.Backdrop = Button.Quest:CreateTexture(nil, "ARTWORK")
			Button.Quest.Backdrop:SetAllPoints()
			Button.Quest.Backdrop:SetColorTexture(unpack(C.General.BackdropColor))

			Button.Quest.BorderRight = Button.Quest:CreateTexture(nil, "ARTWORK")
			Button.Quest.BorderRight:SetSize(1, 1)
			Button.Quest.BorderRight:SetPoint("TOPRIGHT", Button.Quest, "TOPRIGHT", 1, 0)
			Button.Quest.BorderRight:SetPoint("BOTTOMRIGHT", Button.Quest, "BOTTOMRIGHT", 1, 0)
			Button.Quest.BorderRight:SetColorTexture(1, 1, 0)

			Button.Quest.Texture = Button.Quest:CreateTexture(nil, "OVERLAY")
			Button.Quest.Texture:SetTexture("Interface\\QuestFrame\\AutoQuest-Parts")
			Button.Quest.Texture:SetTexCoord(0.13476563, 0.17187500, 0.01562500, 0.53125000)
			Button.Quest.Texture:SetSize(8, 16)
			Button.Quest.Texture:SetPoint("CENTER")
		end

		Button.Quest:Show()
		if Button.Backdrop then
			Button.Backdrop:SetBorderColor(1, 1, 0)
		end
	else
		if Button.Quest and Button.Quest:IsShown() then
			Button.Quest:Hide()
		end
	end
end

local WEAPON = 2
local ARMOR = 4
local PROFESSION = 19
function Bags.ItemLevel(Button)
	local ID = Button:GetBagID()
	local Info = C_Container.GetContainerItemInfo(ID, Button:GetID())
	local ItemLink = Info and Info.hyperlink

	if ItemLink then
		local Level = C_Item.GetDetailedItemLevelInfo(ItemLink)
		local _, _, Rarity, _, _, _, _, _, _, _, _, ClassID = C_Item.GetItemInfo(ItemLink)

		-- Only weapons and armors have item levels (and profession tools but here the quality gems are shown instead)
		if ClassID and (ClassID == WEAPON or ClassID == ARMOR --[[or ClassID == PROFESSION]]) and Level and Level > 1 then
			if not Button.ItemLevel then
				Button.ItemLevel = Button:CreateFontString(nil, "ARTWORK")
				Button.ItemLevel:SetPoint("TOPRIGHT", 1, -1)
				Button.ItemLevel:SetFont(C.Medias.Font, 12, "OUTLINE")
				Button.ItemLevel:SetJustifyH("RIGHT")
			end

			Button.ItemLevel:SetText(Level)

			if Rarity then
				R, G, B = C_Item.GetItemQualityColor(Rarity)

				Button.ItemLevel:SetTextColor(R, G, B)
			else
				Button.ItemLevel:SetTextColor(1, 1, 1)
			end
		else
			if Button.ItemLevel then
				Button.ItemLevel:SetText("")
			end
		end
	else
		if Button.ItemLevel then
			Button.ItemLevel:SetText("")
		end
	end
end

-- Blizzard bug (WoW Forever 1.60.1.70170): the gamepad bag bar parented to the combined bag is
-- meant to be hidden without the gamepad UI, but GamepadBagBar:GetBagButton() returns nil then,
-- so nothing hides it and its backpack button covers the sort button.
local function HideGamepadBagBar()
	local Bar = _G.GamepadBagBar

	if Bar and Bar:IsShown() and not (InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()) then
		Bar:Hide()
	end
end

function Bags:UpdateItems()
	-- (see HideGamepadBagBar)
	HideGamepadBagBar()

	for i, Button in self:EnumerateValidItems() do
		-- Buttons for newly equipped bags are created after login, skin them here
		Bags:SkinButton(Button)

		-- Hide the golden slot frame Blizzard may have (re)created on Initialize
		if Button.ItemSlotBackground and Button.ItemSlotBackground:IsShown() then
			Button.ItemSlotBackground:Hide()
		end

		local ID = Button:GetBagID()
		local Info = C_Container.GetContainerItemInfo(ID, Button:GetID())
		local ItemLink = Info and Info.hyperlink
		local Texture = Info and Info.iconFileID

		local Count = Info and Info.stackCount
		local Lock = Info and Info.isLocked
		local Quality = Info and Info.quality
		local Readable = Info and Info.IsReadable
		local ItemLink = Info and Info.hyperlink
		local IsFiltered = Info and Info.isFiltered
		local NoValue = Info and Info.hasNoValue
		local ItemID = Info and Info.itemID
		local IsBound = Info and Info.isBound
		local R, G, B

		if Button.Backdrop then
			if Quality then
				R, G, B = C_Item.GetItemQualityColor(Quality)

				Button.Backdrop:SetBorderColor(R, G, B)
			else
				Button.Backdrop:SetBorderColor(unpack(C.General.BorderColor))
			end
		end

		-- Quest Items
		if C.Bags.IdentifyQuestItems then
			Bags.QuestItem(Button)
		end

		-- Items Level
		if C.Bags.ItemLevel then
			Bags.ItemLevel(Button)
		end
	end
end

function Bags:SkinContainer()
	local Container = ContainerFrameCombinedBags
	local NineSlice = Container.NineSlice
	local CloseButton = Container.CloseButton
	local Portrait = ContainerFrameCombinedBagsPortrait
	local TokensBorder = BackpackTokenFrame.Border
	local MoneyBorder = ContainerFrameCombinedBags.MoneyFrame.Border
	local SearchBox = BagItemSearchBox
	local SortButton = BagItemAutoSortButton

	-- Hide Blizzard's marble/rock background so Tukui's backdrop shows through.
	Container:StripTextures(true)
	if Container.Bg then
		Container.Bg:Hide()
	end

	NineSlice:StripTextures()
	NineSlice:SetTemplate()
	NineSlice:SetFrameLevel(0)
	NineSlice:CreateShadow()

	CloseButton:SkinCloseButton()

	Portrait:Kill()

	TokensBorder:Kill()

	MoneyBorder:Kill()

	SearchBox:StripTextures()
	SearchBox:SkinEditBox()

	-- Title in Tukui font instead of Blizzard's gold one
	local Title = Container.TitleContainer and Container.TitleContainer.TitleText

	if Title then
		Title:SetFontTemplate(C.Medias.Font, 12)
		Title:SetTextColor(1, 1, 1)
	end

	-- Sort button: flat Tukui button with a square broom icon
	if SortButton then
		SortButton:SetNormalTexture("")
		SortButton:SetPushedTexture("")
		SortButton:SetHighlightTexture("")
		SortButton:StripTextures()

		-- The broom is an atlas set in XML; clearing the file does not remove it
		if SortButton:GetNormalTexture() then
			SortButton:GetNormalTexture():SetAlpha(0)
		end

		SortButton:SetSize(SearchBox:GetHeight(), SearchBox:GetHeight())
		SortButton:CreateBackdrop()
		SortButton:StyleButton()

		SortButton.Icon = SortButton:CreateTexture(nil, "OVERLAY")
		SortButton.Icon:SetInside(SortButton)
		SortButton.Icon:SetTexture("Interface\\Icons\\INV_Pet_Broom")
		SortButton.Icon:SetTexCoord(unpack(T.IconCoord))

		-- Blizzard's C_Container.SortBags() does nothing on Classic realms, use the Tukui sort lib
		if SortBags then
			SortButton:SetScript("OnClick", function()
				if InCombatLockdown() then
					T.Print("You cannot sort your bag in combat")

					return
				end

				PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
				SortBags()
			end)
		end
	end

	-- Reagent Bag
	if ContainerFrame6 then
		local ReagentContainer = ContainerFrame6
		local ReagentNineSlice = ReagentContainer.NineSlice
		local ReagentCloseButton = ReagentContainer.CloseButton
		local ReagentPortrait = ContainerFrame6Portrait

		ReagentContainer:StripTextures(true)
		if ReagentContainer.Bg then
			ReagentContainer.Bg:Hide()
		end

		ReagentNineSlice:StripTextures()
		ReagentNineSlice:SetTemplate()
		ReagentNineSlice:SetFrameLevel(0)
		ReagentNineSlice:CreateShadow()

		ReagentCloseButton:SkinCloseButton()

		ReagentPortrait:Kill()
	end
end

function Bags:UpdatePosition()
	local Container = ContainerFrameCombinedBags
	local Position = TukuiDatabase.Variables[T.MyRealm][T.MyName].Move.ContainerFrameCombinedBags

	if Position then
		Container:ClearAllPoints()
		Container:SetPoint(unpack(Position))
	end
end

function Bags:AddHooks()
	hooksecurefunc("UpdateContainerFrameAnchors", Bags.UpdatePosition)
	hooksecurefunc(ContainerFrameCombinedBags, "UpdateItems", Bags.UpdateItems)
	hooksecurefunc(ContainerFrame6, "UpdateItems", Bags.UpdateItems)
end

function Bags:Enable()
	if (not C.Bags.Enable) then
		return
	end

	SetCVar("combinedBags", 1)
	C_Container.SetInsertItemsLeftToRight(false)

	if C.Bags.SortToBottom then
		C_Container.SetSortBagsRightToLeft(false)
	else
		C_Container.SetSortBagsRightToLeft(true)
	end

	-- Same direction for the Tukui sort lib (SortBags_Vanilla)
	if SetSortBagsRightToLeft then
		SetSortBagsRightToLeft(not C.Bags.SortToBottom)
	end

	-- (Tukui used to call ToggleAllBags() twice here to create the combined bag early.
	-- Opening bags from addon code tainted Blizzard's bag state; the bank opens the bags
	-- in its OnShow, so the bank frame got tainted and buying a bank tab was blocked.
	-- Item buttons are skinned in UpdateItems when the bag is first opened instead.)

	-- Skin the bottom bag bar first: it is independent of the combined-bags
	-- container and must still run if the combined-bags skin below errors out.
	self:SkinBagBar()

	-- Start doing shit
	self:AddHooks()
	self:SkinContainer()
	HideGamepadBagBar()

	Movers:RegisterFrame(ContainerFrameCombinedBags, "Bags")
	
	if T.Retail then
		T.Print("NEWS: Tukui 22 will be back in full health for midnight with a total rewrite from scratch, meanwhile, here a patched version of Tukui 21 until Midnight release. If you see some errors, don't hesitate to ping me on Discord - Tukz")
	end
end

Inventory.Bags = Bags
