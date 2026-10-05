local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Movers = T["Movers"]
local Alerts = CreateFrame("Frame")

function Alerts:UpdateAnchors()
	AlertFrame:ClearAllPoints()
	AlertFrame:SetPoint("CENTER", Alerts.Holder, "Center", 0, 0)
end

-- Not a hook on AlertFrame:UpdateAnchors: Blizzard calls it from secure layout code,
-- and on this client a hooked Blizzard method breaks there. Poll from our holder.
function Alerts:AddHooks()
	local Elapsed = 0

	self.Holder:SetScript("OnUpdate", function(Holder, Delta)
		Elapsed = Elapsed + Delta

		if Elapsed < 0.2 then
			return
		end

		Elapsed = 0

		local Point, Relative = AlertFrame:GetPoint(1)

		if Point ~= "CENTER" or Relative ~= Holder or AlertFrame:GetNumPoints() ~= 1 then
			Alerts:UpdateAnchors()
		end
	end)
end

function Alerts:AddHolder()
	self.Holder = CreateFrame("Frame", "TukuiAlerts", UIParent)
	self.Holder:SetSize(200, 17)
	self.Holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 226)
end

function Alerts:Enable()
	self:AddHolder()
	self:AddHooks()

	Movers:RegisterFrame(self.Holder, "Alerts holder")
end

Miscellaneous.Alerts = Alerts
