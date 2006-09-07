local MAJOR_VERSION = "AceGUIFontString-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


--[[local AceOO = AceLibrary("AceOO-2.0")
local AceGUILayeredRegion = AceLibrary("AceGUILayeredRegion-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUIFontString = AceOO.Class(AceGUILayeredRegion,AceGUIFontInstance)
AceGUIFontString.new = AceGUILayeredRegion.new
AceGUIFontString.UIObjectType = "FontString"
]]
local fontstring = AceLibrary("AceGUIFactory-2.0"):new("AceGUILayeredRegion-2.0","AceGUIFontInstance-2.0")
fontstring.UIObjectType = "FontString"

function fontstring:CreateUIObject(parent)
    return parent:CreateFontString()
end

function fontstring.prototype:Configure(def,parent,name,handler)
    fontstring.super.prototype.Configure(self,def,parent,name,handler)
    --AceGUILayeredRegion.prototype.Configure(self,def,parent,name,handler)
    
    self:SetNonSpaceWrap(def.nonSpaceWrap)
	
    t = def.alphaGradient
    if(t) then self:SetAlphaGradient(def.alphaGradient.start,def.alphaGradient.length) end
	
    if def.text then self:SetText(def.text) end
end

AceLibrary:Register(fontstring,MAJOR_VERSION,MINOR_VERSION)
fontstring = AceLibrary(MAJOR_VERSION)