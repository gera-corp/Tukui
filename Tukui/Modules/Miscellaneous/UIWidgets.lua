local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local UIWidgets = CreateFrame("Frame")

function UIWidgets:SkinUIWidgetStatusBar(widgetInfo, widgetContainer)
	local Bar = self.Bar
	local Torghast = IsInJailersTower and IsInJailersTower() or false

	if Bar and not Bar.IsSkinned then
		if Bar.BGLeft and Bar.BGLeft.SetAlpha then Bar.BGLeft:SetAlpha(0) end
		if Bar.BGRight and Bar.BGRight.SetAlpha then Bar.BGRight:SetAlpha(0) end
		if Bar.BGCenter and Bar.BGCenter.SetAlpha then Bar.BGCenter:SetAlpha(0) end
		if Bar.BorderLeft and Bar.BorderLeft.SetAlpha then Bar.BorderLeft:SetAlpha(0) end
		if Bar.BorderRight and Bar.BorderRight.SetAlpha then Bar.BorderRight:SetAlpha(0) end
		if Bar.BorderCenter and Bar.BorderCenter.SetAlpha then Bar.BorderCenter:SetAlpha(0) end
		
		Bar:CreateBackdrop(Torghast and "Transparent" or "")
		
		Bar.Backdrop:CreateShadow()
		Bar.Backdrop:SetFrameLevel(Bar:GetFrameLevel())
		Bar.Backdrop:SetOutside(Bar)

		if Torghast then
			Bar.Indicator = Bar:CreateTexture(nil, "OVERLAY")
			Bar.Indicator:SetSize(16, 16)
			Bar.Indicator:SetPoint("TOP", 23, 9)
			Bar.Indicator:SetTexture(C.Medias.ArrowDown)
			Bar.Indicator:SetVertexColor(1, 0, 0)
		end

		Bar.IsSkinned = true
	end

	if self:GetParent() == UIWidgetPowerBarContainerFrame then
		Bar:ClearAllPoints()
		Bar:SetPoint("CENTER", UIWidgets.Holder, "CENTER", 0, 0)
	end

	-- Just hate that thing to be in objective tracker
	if Torghast then
		local Container = self:GetParent()

		Container:SetParent(UIWidgets.Holder)
		Container:ClearAllPoints()
		Container:SetPoint("TOP", UIWidgets.Holder, "TOP", 0, 0)
	end
end

function UIWidgets:Enable()
	local MinimapWidget = UIWidgetBelowMinimapContainerFrame

	-- (Tukui used to override MinimapWidget.GetNumWidgetsShowing here to stop Blizzard
	-- from moving it. On this client Blizzard's secure layout code can't call functions
	-- an addon put on its frames, so the holder below puts it back by polling instead.)

	-- Create a widget holder
	self.Holder = CreateFrame("Frame", "TukuiWidget", UIParent)
	self.Holder:SetSize(220, 20)
	self.Holder:SetPoint("TOP", 3, -96)

	-- This is now the frame that contain capture bar and other shit like that.
	MinimapWidget:SetParent(self.Holder)
	MinimapWidget:ClearAllPoints()
	MinimapWidget:SetPoint("CENTER")
	
	if UIWidgetPowerBarContainerFrame then
		if C.Misc.DisplayWidgetPowerBar then
			-- This is power bar
			UIWidgetPowerBarContainerFrame:SetParent(self.Holder)
			UIWidgetPowerBarContainerFrame:ClearAllPoints()
			UIWidgetPowerBarContainerFrame:SetPoint("CENTER")
		else
			UIWidgetPowerBarContainerFrame:SetParent(T.Hider)
		end
	end

	-- Skin status bars and keep the containers in our holder. Not a hook on
	-- UIWidgetTemplateStatusBarMixin.Setup: Blizzard calls Setup from a C_Timer ticker,
	-- where a hooked method breaks on this client. Poll the containers instead.
	local Containers = {UIWidgetTopCenterContainerFrame, MinimapWidget, UIWidgetPowerBarContainerFrame}
	local Elapsed = 0

	self.Holder:SetScript("OnUpdate", function(Holder, Delta)
		Elapsed = Elapsed + Delta

		if Elapsed < 0.5 then
			return
		end

		Elapsed = 0

		local _, Relative = MinimapWidget:GetPoint(1)

		if Relative ~= Holder then
			MinimapWidget:ClearAllPoints()
			MinimapWidget:SetPoint("CENTER", Holder)
		end

		for _, Container in pairs(Containers) do
			if Container.widgetFrames then
				for _, Widget in pairs(Container.widgetFrames) do
					local IsStatusBar = Enum.UIWidgetVisualizationType and Widget.widgetType == Enum.UIWidgetVisualizationType.StatusBar

					if IsStatusBar and Widget.Bar and Widget:IsShown() then
						UIWidgets.SkinUIWidgetStatusBar(Widget)
					end
				end
			end
		end
	end)

	T.Movers:RegisterFrame(self.Holder, "UI Widgets")
end

Miscellaneous.UIWidgets = UIWidgets
