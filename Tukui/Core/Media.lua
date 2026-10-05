local T, C = unpack((select(2, ...)))

local TukuiMedia = CreateFrame("Frame")
local Locale = GetLocale()

-- Create our own fonts
local TukuiFont = CreateFont("TukuiFont")
	TukuiFont:SetFont(C["Medias"].Font, 12, "")
	TukuiFont:SetShadowColor(0, 0, 0)
	TukuiFont:SetShadowOffset(1, -1)

	local TukuiFontOutline = CreateFont("TukuiFontOutline")
	TukuiFontOutline:SetFont(C["Medias"].Font, 12, "THINOUTLINE")

	local TukuiUFFont = CreateFont("TukuiUFFont")
	TukuiUFFont:SetShadowColor(0, 0, 0)
	TukuiUFFont:SetShadowOffset(1, -1)
	TukuiUFFont:SetFont(C["Medias"].UnitFrameFont, 12, "")

local TukuiUFFontOutline = CreateFont("TukuiUFFontOutline")
TukuiUFFontOutline:SetFont(C["Medias"].UnitFrameFont, 12, "THINOUTLINE")

local PixelFont = CreateFont("TukuiPixelFont")
PixelFont:SetFont(C["Medias"].PixelFont, 12, "MONOCHROMEOUTLINE")

local TukuiDamageFont = CreateFont("TukuiDamageFont")
TukuiDamageFont:SetFont(C["Medias"].DamageFont, 12, "OUTLINE")

-- Ubuntu Condensed (Ubuntu Font Licence, see Medias\Fonts\UbuntuCondensed-LICENCE.txt): narrow, with Cyrillic
local UbuntuCondensedPath = [[Interface\AddOns\Tukui\Medias\Fonts\UbuntuCondensed.ttf]]

local TukuiUbuntuCondensed = CreateFont("TukuiUbuntuCondensedFont")
TukuiUbuntuCondensed:SetFont(UbuntuCondensedPath, 12, "")
TukuiUbuntuCondensed:SetShadowColor(0, 0, 0)
TukuiUbuntuCondensed:SetShadowOffset(1, -1)

local TukuiUbuntuCondensedOutline = CreateFont("TukuiUbuntuCondensedFontOutline")
TukuiUbuntuCondensedOutline:SetFont(UbuntuCondensedPath, 12, "THINOUTLINE")

-- JetBrains Mono NL Nerd Font, Medium (OFL): monospaced, no ligatures, with Cyrillic
local JetBrainsMonoPath = [[Interface\AddOns\Tukui\Medias\Fonts\JetBrainsMonoNLNerdFontMono-Medium.ttf]]

local TukuiJetBrainsMono = CreateFont("TukuiJetBrainsMonoFont")
TukuiJetBrainsMono:SetFont(JetBrainsMonoPath, 12, "")
TukuiJetBrainsMono:SetShadowColor(0, 0, 0)
TukuiJetBrainsMono:SetShadowOffset(1, -1)

local TukuiJetBrainsMonoOutline = CreateFont("TukuiJetBrainsMonoFontOutline")
TukuiJetBrainsMonoOutline:SetFont(JetBrainsMonoPath, 12, "THINOUTLINE")

-- Roboto Condensed SemiBold (OFL, see Medias\Fonts\RobotoCondensed-OFL.txt): static weight 600
-- instance of Google's variable font, narrow, with Cyrillic
local RobotoCondensedPath = [[Interface\AddOns\Tukui\Medias\Fonts\RobotoCondensed-SemiBold.ttf]]

local TukuiRobotoCondensed = CreateFont("TukuiRobotoCondensedFont")
TukuiRobotoCondensed:SetFont(RobotoCondensedPath, 12, "")
TukuiRobotoCondensed:SetShadowColor(0, 0, 0)
TukuiRobotoCondensed:SetShadowOffset(1, -1)

local TukuiRobotoCondensedOutline = CreateFont("TukuiRobotoCondensedFontOutline")
TukuiRobotoCondensedOutline:SetFont(RobotoCondensedPath, 12, "THINOUTLINE")

-- Ubuntu Nerd Font Propo, Bold (Ubuntu Font Licence, see Medias\Fonts\UbuntuNerdFont-LICENCE.txt):
-- proportional, with Cyrillic
local UbuntuBoldPath = [[Interface\AddOns\Tukui\Medias\Fonts\UbuntuNerdFontPropo-Bold.ttf]]

local TukuiUbuntuBold = CreateFont("TukuiUbuntuBoldFont")
TukuiUbuntuBold:SetFont(UbuntuBoldPath, 12, "")
TukuiUbuntuBold:SetShadowColor(0, 0, 0)
TukuiUbuntuBold:SetShadowOffset(1, -1)

local TukuiUbuntuBoldOutline = CreateFont("TukuiUbuntuBoldFontOutline")
TukuiUbuntuBoldOutline:SetFont(UbuntuBoldPath, 12, "THINOUTLINE")

-- Same font with letters 7% of an em closer together (advance widths -70/1000, outlines
-- re-centred), made with fontTools
local UbuntuBoldTightPath = [[Interface\AddOns\Tukui\Medias\Fonts\UbuntuNerdFontPropo-BoldTight.ttf]]

local TukuiUbuntuBoldTight = CreateFont("TukuiUbuntuBoldTightFont")
TukuiUbuntuBoldTight:SetFont(UbuntuBoldTightPath, 12, "")
TukuiUbuntuBoldTight:SetShadowColor(0, 0, 0)
TukuiUbuntuBoldTight:SetShadowOffset(1, -1)

local TukuiUbuntuBoldTightOutline = CreateFont("TukuiUbuntuBoldTightFontOutline")
TukuiUbuntuBoldTightOutline:SetFont(UbuntuBoldTightPath, 12, "THINOUTLINE")

-- Ubuntu Sans Bold at width 85 (Ubuntu Font Licence, see Medias\Fonts\UbuntuSans-LICENCE.txt):
-- static instance of Canonical's variable font (wdth 85, wght 700), with Cyrillic
local UbuntuSansPath = [[Interface\AddOns\Tukui\Medias\Fonts\UbuntuSans-Bold-Width85.ttf]]

local TukuiUbuntuSans = CreateFont("TukuiUbuntuSansFont")
TukuiUbuntuSans:SetFont(UbuntuSansPath, 12, "")
TukuiUbuntuSans:SetShadowColor(0, 0, 0)
TukuiUbuntuSans:SetShadowOffset(1, -1)

local TukuiUbuntuSansOutline = CreateFont("TukuiUbuntuSansFontOutline")
TukuiUbuntuSansOutline:SetFont(UbuntuSansPath, 12, "THINOUTLINE")

local TextureTable = {
	["Blank"] = [[Interface\BUTTONS\WHITE8X8]],
	["Tukui"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Tukui]],
	["ElvUI1"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\ElvUI1]],
	["ElvUI2"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\ElvUI2]],
	["sRainbow1"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Rainbow1]],
	["sRainbow2"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Rainbow2]],
	["sGloss1"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy1]],
	["sSword"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy2]],
	["sBeam"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy3]],
	["sStorm"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy4]],
	["sCrater"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy5]],
	["sStrokes"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy6]],
	["sSponge"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy7]],
	["sSimple1"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy8]],
	["sGrudge"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy9]],
	["sGrass"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy10]],
	["sExplosion"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy11]],
	["sWaterPaper"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy12]],
	["sDarkStrokes"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy13]],
	["sDrySwirl"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy14]],
	["sCrosshatch"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy15]],
	["sDoubleDragon"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy16]],
	["sSingleDragon"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy17]],
	["sSplitIce"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy18]],
	["sWaterDroplets"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy19]],
	["sPawPrints"] = [[Interface\AddOns\Tukui\Medias\Textures\Status\Simpy20]],
}

local FontTable = {
	["Tukui"] = "TukuiFont",
	["Tukui Outline"] = "TukuiFontOutline",
	["Tukui UF"] = "TukuiUFFont",
	["Tukui UF Outline"] = "TukuiUFFontOutline",
	["Pixel"] = "TukuiPixelFont",
	["Game Font"] = "GameFontWhite",
	["Tukui Damage"] = "TukuiDamageFont",
	["Ubuntu Condensed"] = "TukuiUbuntuCondensedFont",
	["Ubuntu Condensed Outline"] = "TukuiUbuntuCondensedFontOutline",
	["JetBrains Mono"] = "TukuiJetBrainsMonoFont",
	["JetBrains Mono Outline"] = "TukuiJetBrainsMonoFontOutline",
	["Roboto Condensed"] = "TukuiRobotoCondensedFont",
	["Roboto Condensed Outline"] = "TukuiRobotoCondensedFontOutline",
	["Ubuntu Bold"] = "TukuiUbuntuBoldFont",
	["Ubuntu Bold Outline"] = "TukuiUbuntuBoldFontOutline",
	["Ubuntu Bold Tight"] = "TukuiUbuntuBoldTightFont",
	["Ubuntu Bold Tight Outline"] = "TukuiUbuntuBoldTightFontOutline",
	["Ubuntu Sans Bold 85"] = "TukuiUbuntuSansFont",
	["Ubuntu Sans Bold 85 Outline"] = "TukuiUbuntuSansFontOutline",
}

T.GetFont = function(font)
	if FontTable[font] then
		return FontTable[font]
	else
		return FontTable["Tukui"] -- Return something to prevent errors
	end
end

T.GetTexture = function(texture)
	if TextureTable[texture] then
		return TextureTable[texture]
	else
		return TextureTable["Blank"] -- Return something to prevent errors
	end
end

function TukuiMedia:RegisterTexture(name, path)
	if (not TextureTable[name]) then
		TextureTable[name] = path
	end
end

function TukuiMedia:RegisterFont(name, path)
	if (not FontTable[name]) then
		FontTable[name] = path
	end
end

T["Media"] = TukuiMedia
T.FontTable = FontTable
T.TextureTable = TextureTable
