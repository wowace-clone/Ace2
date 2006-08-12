local MAJOR_VERSION = "AceGUILayeredRegion-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIRegion = AceLibrary("AceGUIRegion-2.0")
local AceGUILayeredRegion = AceOO.Class(AceGUIRegion)
AceGUILayeredRegion.new = AceGUIRegion.new
AceGUILayeredRegion.virtual = true

function AceGUILayeredRegion.prototype:Configure(def,parent,name,handler)
    --AceGUILayeredRegion.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIRegion.prototype.Configure(self,def,parent,name,handler)
    
    local t = def.drawLayer
    if t then self:SetDrawLayer(t) end
    t = def.VertexColor
	if t then self:SetVertexColor(t.r or t[1],t.g or t[2],t.b or t[3],t.a or t[4]) end
    
end

AceLibrary:Register(AceGUILayeredRegion,MAJOR_VERSION,MINOR_VERSION)