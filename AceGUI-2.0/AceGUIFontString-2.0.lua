local MAJOR_VERSION = "AceGUIFontString-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUILayeredRegion = AceLibrary("AceGUILayeredRegion-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUIFontString = AceOO.Class(AceGUILayeredRegion,AceGUIFontInstance)
AceGUIFontString.new = AceGUILayeredRegion.new
AceGUIFontString.UIObjectType = "FontString"


function AceGUIFontString:CreateUIObject(parent)
    return parent:CreateFontString()
end

function AceGUIFontString.prototype:Configure(def,parent,name,handler)
    --AceGUIFontString.super.prototype.Configure(self,def,parent,name,handler)
    AceGUILayeredRegion.prototype.Configure(self,def,parent,name,handler)
    
    self:SetNonSpaceWrap(def.NonSpaceWrap)
	
    t = def.AlphaGradient
    if(t) then self:SetAlphaGradient(def.AlphaGradient.start,def.AlphaGradient.length) end
	
    if def.text then self:SetText(def.text) end
end

AceLibrary:Register(AceGUIFontString,MAJOR_VERSION,MINOR_VERSION)