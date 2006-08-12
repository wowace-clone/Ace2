local MAJOR_VERSION = "AceGUIRegion-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIBase = AceLibrary("AceGUIBase-2.0")
local AceGUIRegion = AceOO.Class(AceGUIBase)
AceGUIRegion.new = AceGUIBase.new
AceGUIRegion.virtual = true
local registry = ACEGUI_FACTORY

function AceGUIRegion.prototype:Configure(def,parent,name,handler)
    --AceGUIRegion.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIBase.prototype.Configure(self,def,parent,name,handler)
    
    if def.height then self:SetHeight(def.height) end
    if def.width then self:SetWidth(def.width) end
    
    if(def.setAllPoints) then
        if type(def.setAllPoints) == "table" then
            self:SetAllPoints(def.setAllPoints)
        else
            self:SetAllPoints(parent)
        end
    elseif def.anchors then
        for point,options in pairs(def.anchors) do
            if type(options) ~= "table" then
                self:SetPoint(point,0,0)
            else
                local relTo = options.relTo
                if type(relTo) == "string" then
                    local tmp = registry.objects[relTo]
                    if not tmp then
                        error("No AceGUI Object named '"..relTo.."' exists to anchor object '"..name.."' to.")
                    end
                    relTo = tmp.o
                end
                local relPoint = options.relPoint or point
                self:SetPoint(point,relTo or parent,relPoint,options.xOffset or 0, options.yOffset or 0)
            end
        end
    end
    
end

AceLibrary:Register(AceGUIRegion, MAJOR_VERSION, MINOR_VERSION)


