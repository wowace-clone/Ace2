local MAJOR_VERSION = "AceGUISlider-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFrame = AceLibrary("AceGUIFrame-2.0")
local AceGUISlider = AceOO.Class(AceGUIFrame)
AceGUISlider.new = AceGUIFrame.new
AceGUISlider.CreateUIObject = AceGUIFrame.CreateUIObject
AceGUISlider.UIObjectType = "Slider"

local factory = AceLibrary("AceGUIFactory-2.0")

function AceGUISlider.prototype:Build(def, parent, name, handler)
    --AceGUISlider.super.prototype.Build(self,def,parent,name,handler)
    AceGUIFrame.prototype.Build(self,def,parent,name,handler)
    
    local thumbDef = def.ThumbTexture
    if type(thumbDef) == "table" then
        thumbDef.type = "texture"
        def.elements = def.elements or {}
        def.elements.ThumbTexture = thumbDef
    end
end

function AceGUISlider.prototype:Configure(def,parent,name,handler)
    --AceGUISlider.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIFrame.prototype.Configure(self,def,parent,name,handler)
    
    if self.ThumbTexture then
        self:SetThumbTexture(self.ThumbTexture)
    elseif type(def.ThumbTexture) == "string" then
        self:SetThumbTexture(self.ThumbTexture)
    end
    
    self:SetOrientation(def.orientation or "HORIZONTAL")
    self:SetMinMaxValues(def.minValue or 0, def.maxValue or 100)
    
    if def.valueStep then self:SetValueStep(def.valueStep) end
end


AceLibrary:Register(AceGUISlider, MAJOR_VERSION, MINOR_VERSION)