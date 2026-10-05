local T, C, L = unpack((select(2, ...)))

local Miscellaneous = T["Miscellaneous"]
local Movers = T["Movers"]
local VehicleIndicator = CreateFrame("Frame")

function VehicleIndicator:SetPosition()
	local Indicator = VehicleSeatIndicator
	local Holder = TukuiVehicleIndicator
	
	Indicator:ClearAllPoints()
	Indicator:SetAllPoints(Holder)
end

function VehicleIndicator:Enable()
	local Indicator = VehicleSeatIndicator
	local Holder = CreateFrame("Frame", "TukuiVehicleIndicator", UIParent)
	
	Holder:SetSize(Indicator:GetSize())
	Holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)	

	Indicator:SetParent(Holder)
	Indicator:ClearAllPoints()
	Indicator:SetPoint("CENTER", Holder)
	Indicator:SetFrameStrata("BACKGROUND")
	
	-- Blizzard re-anchors it from secure layout code, where a hooked SetPoint breaks
	-- on this client; the holder puts it back by polling instead.
	local Elapsed = 0

	Holder:SetScript("OnUpdate", function(_, Delta)
		Elapsed = Elapsed + Delta

		if Elapsed < 0.2 then
			return
		end

		Elapsed = 0

		local _, Relative = Indicator:GetPoint(1)

		if Relative ~= Holder or Indicator:GetNumPoints() ~= 2 then
			VehicleIndicator:SetPosition()
		end
	end)

	Movers:RegisterFrame(Holder, "Vehicle Indicator")
end

Miscellaneous.VehicleIndicator = VehicleIndicator