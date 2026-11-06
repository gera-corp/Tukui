local T, C, L = unpack((select(2, ...)))

local Chat = T["Chat"]
local Copy = CreateFrame("Frame")

-- Forever: SetTextCopyable/SetOnTextCopiedCallback exist as C++ stubs but the
-- native chat drag-select does not work. Copy chat text into an EditBox window
-- instead (ElvUI approach), using GetNumMessages/GetMessageInfo.

local copyLines = {}

-- Chat line for the copy window. An edit box doesn't render every chat escape sequence
-- (Battle.net name tokens |K..|k, atlas and texture icons, named colors |cn..:): one such
-- line left the whole copy window empty. Links keep their visible text, colors are kept as
-- plain |cAARRGGBB codes, and the line gets the chat type color it has in the chat frame.
local function NamedColor(name)
	local Color = _G[name]

	return Color and Color.GenerateHexColor and "|c" .. Color:GenerateHexColor() or ""
end

local function IsNumber(value)
	return type(value) == "number" and not (issecretvalue and issecretvalue(value))
end

local function CopyText(msg, r, g, b)
	msg = gsub(msg, "|H.-|h(.-)|h", "%1")
	msg = gsub(msg, "|T.-|t", "")
	msg = gsub(msg, "|A.-|a", "")
	msg = gsub(msg, "|K.-|k", "?")
	msg = gsub(msg, "|n", " ")
	msg = gsub(msg, "|cn([^:]*):", NamedColor)

	-- protect the color codes, show any other "|" literally (it would start an escape
	-- sequence in the edit box), then put the color codes back
	msg = gsub(msg, "|c(%x%x%x%x%x%x%x%x)", "\001%1")
	msg = gsub(msg, "|r", "\002")
	msg = gsub(msg, "|", "||")
	msg = gsub(msg, "\001", "|c")
	msg = gsub(msg, "\002", "|r")

	if IsNumber(r) and IsNumber(g) and IsNumber(b) then
		msg = format("|cff%02x%02x%02x%s|r", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5), msg)
	end

	return msg
end

-- Keeps the edit box as wide as the visible area and the scroll bar in sync with it.
local function UpdateScrollBar(frame)
	local scroll, bar = frame.Scroll, frame.ScrollBar
	local range = scroll:GetVerticalScrollRange()

	bar:SetMinMaxValues(0, range)
	bar:SetValue(scroll:GetVerticalScroll())
	bar:SetShown(range > 0)
end

local function BuildCopyFrame()
	local frame = CreateFrame("Frame", "TukuiCopyChatFrame", UIParent)
	tinsert(UISpecialFrames, "TukuiCopyChatFrame")
	frame:SetSize(700, 300)
	frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 3)
	frame:SetFrameStrata("DIALOG")
	frame:CreateBackdrop("Transparent")
	frame:CreateShadow()
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(300, 120)
	frame:SetClampedToScreen(true)
	frame:Hide()
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
		end
	end)

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFontTemplate(C.Medias.Font, 12)
	title:SetPoint("TOPLEFT", 8, -8)
	title:SetText(CHAT or "Chat")

	-- Text lives in a scroll frame, so long logs no longer spill out of the window
	local scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 8)
	scroll:EnableMouseWheel(true)
	frame.Scroll = scroll

	local editBox = CreateFrame("EditBox", "TukuiCopyChatFrameEditBox", scroll)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(0)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontTemplate(C.Medias.Font, 12)
	editBox:SetWidth(scroll:GetWidth())
	editBox:SetScript("OnEscapePressed", function()
		frame:Hide()
	end)
	editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
		-- keep the cursor visible while selecting with the keyboard
		local top = scroll:GetVerticalScroll()
		local height = scroll:GetHeight()
		y = -y

		if y < top then
			scroll:SetVerticalScroll(y)
		elseif y + h > top + height then
			scroll:SetVerticalScroll(min(y + h - height, scroll:GetVerticalScrollRange()))
		end
	end)
	editBox:SetScript("OnTextChanged", function()
		UpdateScrollBar(frame)
	end)
	scroll:SetScrollChild(editBox)

	local bar = CreateFrame("Slider", nil, frame)
	bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -28)
	bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 22)
	bar:SetWidth(8)
	bar:SetOrientation("VERTICAL")
	bar:SetValueStep(1)
	bar:SetObeyStepOnDrag(false)
	bar:CreateBackdrop()
	bar:SetThumbTexture(C.Medias.Blank)
	bar:GetThumbTexture():SetSize(8, 30)
	bar:GetThumbTexture():SetVertexColor(unpack(C.General.BorderColor))
	bar:SetScript("OnValueChanged", function(_, value)
		scroll:SetVerticalScroll(value)
	end)
	frame.ScrollBar = bar

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local value = self:GetVerticalScroll() - delta * 40

		self:SetVerticalScroll(max(0, min(value, self:GetVerticalScrollRange())))
		bar:SetValue(self:GetVerticalScroll())
	end)
	scroll:SetScript("OnScrollRangeChanged", function()
		UpdateScrollBar(frame)
	end)
	scroll:SetScript("OnSizeChanged", function(self, width)
		editBox:SetWidth(width)
		UpdateScrollBar(frame)
	end)

	-- Resize grip in the bottom right corner
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(14, 14)
	grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	grip:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
	grip:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
	grip:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
	grip:SetScript("OnMouseDown", function()
		frame:StartSizing("BOTTOMRIGHT")
	end)
	grip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetSize(20, 20)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
	close:SkinCloseButton()

	return frame, editBox
end

function Copy:CopyChat(chatFrame)
	if not self.CopyFrame then
		self.CopyFrame, self.CopyFrameEditBox = BuildCopyFrame()
	end

	local frame = self.CopyFrame
	local editBox = self.CopyFrameEditBox
	local count = 0

	for i = 1, chatFrame:GetNumMessages() do
		local msg, r, g, b = chatFrame:GetMessageInfo(i)

		-- secret strings can't be concatenated by addon code
		if msg and not (issecretvalue and issecretvalue(msg)) then
			count = count + 1
			copyLines[count] = CopyText(msg, r, g, b)
		end
	end

	if count > 0 then
		frame:Show()
		editBox:SetWidth(frame.Scroll:GetWidth())
		editBox:SetText(table.concat(copyLines, "\n", 1, count))
		editBox:HighlightText(0)

		-- open at the newest lines, once the text has been laid out
		C_Timer.After(0, function()
			-- on the first open the scroll frame may not have its size yet when the text is set
			editBox:SetWidth(frame.Scroll:GetWidth())

			local range = frame.Scroll:GetVerticalScrollRange()

			frame.Scroll:SetVerticalScroll(range)
			UpdateScrollBar(frame)
		end)
	end
end

function Copy:OnMouseUp()
	local Frame = self.ChatFrame

	Copy:CopyChat(Frame)
end

function Copy:OnEnter()
	local Button = self.CopyButton or self

	Button:SetAlpha(1)
end

function Copy:OnLeave()
	local Button = self.CopyButton or self

	Button:SetAlpha(0)
end

function Copy:Enable()
	if (not C.Chat.Enable) then
		return
	end

	-- Create Copy Buttons
	for i = 1, NUM_CHAT_WINDOWS do
		local Frame = _G["ChatFrame"..i]

		Frame.CopyButton = CreateFrame("Button", nil, Frame)
		Frame.CopyButton:SetPoint("TOPRIGHT", 0, 0)
		Frame.CopyButton:SetSize(20, 20)
		Frame.CopyButton:SetNormalTexture(C.Medias.Copy)
		Frame.CopyButton:SetAlpha(0)
		Frame.CopyButton:CreateBackdrop()
		Frame.CopyButton.ChatFrame = Frame

		Frame.CopyButton:SetScript("OnMouseUp", self.OnMouseUp)
		Frame.CopyButton:SetScript("OnEnter", self.OnEnter)
		Frame.CopyButton:SetScript("OnLeave", self.OnLeave)

		Frame:HookScript("OnEnter", self.OnEnter)
		Frame:HookScript("OnLeave", self.OnLeave)
	end
end

Chat.Copy = Copy
