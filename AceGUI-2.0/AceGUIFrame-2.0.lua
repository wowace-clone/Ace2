local MAJOR_VERSION = "AceGUIFrame-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


--[[local AceOO = AceLibrary("AceOO-2.0")
local AceGUIRegion = AceLibrary("AceGUIRegion-2.0")
local AceGUIFrame = AceOO.Class(AceGUIRegion)
AceGUIFrame.new = AceGUIRegion.new
AceGUIFrame.UIObjectType = "Frame"
]]

local frame = AceLibrary("AceGUIFactory-2.0"):new("AceGUIRegion-2.0")
frame.UIObjectType = "Frame"
function frame:CreateUIObject(parent)
    return CreateFrame(self.UIObjectType,nil,parent)
end

function frame.prototype:Configure(def,parent,name,handler)
    frame.super.prototype.Configure(self,def,parent,name,handler)
    --AceGUIRegion.prototype.Configure(self,def,parent,name,handler)
    
    self:EnableMouse(def.enableMouse)
    self:EnableKeyboard(def.enableKeyboard)
    self:EnableMouseWheel(def.enableMouseWheel)
    
    self:SetScale(def.scale or 1)
    self:SetMovable(def.movable)
    self:SetResizable(def.resizable)
    
    local t = def.minResizeBounds
    if t then self:SetMinResizeBounds(t[1] or t.width,t[2] or t.height) end

    t = def.maxResizeBounds
    if t then self:SetMaxResizeBounds(t[1] or t.width,t[2] or t.height) end
    
    t = def.frameStrata
    if t then self:SetFrameStrata(t) end
    
    t = def.frameLevel
    if t then self:SetFrameLevel(t) end
    
    t = def.backdrop
    if t then self:SetBackdrop(t) end
    
    t = def.backdropBorderColor
    if t then self:SetBackdropBorderColor(t[1] or t.r,t[2] or t.g, t[3] or t.b,t[4] or t.a) end
    
    t = def.backdropColor
    if t then self:SetBackdropColor(t[1] or t.r,t[2] or t.g, t[3] or t.b,t[4] or t.a) end
    
    t = def.id
    if t then self:SetID(def.id) end

    t = def.hitRectInsets
    if t then self:SetHitRectInsets(t[1] or t.minX or t.left,t[2] or t.maxX or t.right, t[3] or t.maxY or t.top, t[4] or t.minY or t.bottom) end
    
    self:SetClampedToScreen(def.clampedToScreen)
    
    self:SetToplevel(self.toplevel)
end

AceLibrary:Register(frame, MAJOR_VERSION, MINOR_VERSION)
frame = AceLibrary(MAJOR_VERSION)