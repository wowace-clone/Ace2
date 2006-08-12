local MAJOR_VERSION = "AceGUIFontInstance-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFontInstance = AceOO.Mixin{ "ConfigureFontInstance" }

function AceGUIFontInstance:ConfigureFontInstance(def)
    self:SetFontObject(def.FontObject or GameFontNormal)
		
	local font,size,flags = self:GetFont()
	self:SetFont(def.Font or font,def.FontHeight or size,def.Flags or flags)
	
	local t = def.Color
	if(t) then self:SetTextColor(t.r or t[1], t.g or t[2], t.b or t[3], t.a or t[4] or 1) end
	
	t = def.JustifyH
	if(t) then self:SetJustifyH(def.justifyH) end

	t = def.JustifyV
	if(t) then self:SetJustifyV(def.justfyV) end
end

AceLibrary:Register(AceGUIFontInstance,MAJOR_VERSION,MINOR_VERSION)