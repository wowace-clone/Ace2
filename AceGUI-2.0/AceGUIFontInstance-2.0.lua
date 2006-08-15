local MAJOR_VERSION = "AceGUIFontInstance-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFontInstance = AceOO.Mixin{ "ConfigureFontInstance" }

function AceGUIFontInstance:ConfigureFontInstance(def)
    self:SetFontObject(def.fontObject or GameFontNormal)
		
	local font,size,flags = self:GetFont()
	self:SetFont(def.font or font,def.fontHeight or size,def.flags or flags)
	
	local t = def.color
	if(t) then self:SetTextColor(t.r or t[1], t.g or t[2], t.b or t[3], t.a or t[4] or 1) end
	
	t = def.justifyH
	if(t) then self:SetJustifyH(def.justifyH) end

	t = def.justifyV
	if(t) then self:SetJustifyV(def.justfyV) end
end

AceLibrary:Register(AceGUIFontInstance,MAJOR_VERSION,MINOR_VERSION)