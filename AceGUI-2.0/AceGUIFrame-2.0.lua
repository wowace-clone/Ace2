local MAJOR_VERSION = "AceGUIFrame-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIRegion = AceLibrary("AceGUIRegion-2.0")
local AceGUIFrame = AceOO.Class(AceGUIRegion)
AceGUIFrame.new = AceGUIRegion.new
AceGUIFrame.UIObjectType = "Frame"

function AceGUIFrame:CreateUIObject()
    return CreateFrame(self.UIObjectType)
end


local scripts = {"OnSizeChanged","OnEvent", "OnUpdate", "OnShow", "OnHide", "OnEnter","OnLeave", "OnMouseDown", 
"OnMouseUp", "OnMouseWheel", "OnDragStart", "OnDragStop", "OnReceiveDrag", "OnClick", "OnDoubleClick", 
"OnValueChanged", "OnUpdateModel", "OnAnimFinished", "OnEnterPressed", "OnEscapePressed", "OnSpacePressed", 
"OnTabPressed", "OnTextChanged", "OnTextSet", "OnCursorChanged", "OnInputLanguageChanged", "OnEditFocusGained", 
"OnEditFocusLost", "OnHorizontalScroll", "OnVerticalScroll", "OnScrollRangeChanged", "OnChar", "OnKeyDown", 
"OnKeyUp", "OnColorSelect", "OnHyperlinkEnter", "OnHyperlinkLeave", "OnHyperlinkClick", "OnMessageScrollChanged",
"OnMovieFinished", "OnMovieShowSubtitle", "OnMovieHideSubtitle", "OnTooltipSetDefaultAnchor", "OnTooltipCleared",
"OnTooltipAddMoney"}

function AceGUIFrame.prototype:Configure(def,parent,name,handler)
    --AceGUIFrame.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIRegion.prototype.Configure(self,def,parent,name,handler)
    
    self:EnableMouse(def.enableMouse)
    self:EnableKeyboard(def.enableKeyboard)
    self:EnableMouseWheel(def.enableMouseWheel)
    
    self:SetScale(def.scale or 1)
    self:SetMovable(def.movable)
    self:SetResizable(def.resizable)
    
    local t = def.minResizeBounds
    if(t) then self:SetMinResizeBounds(t[1] or t.width,t[2] or t.height) end

    t = def.maxResizeBounds
    if(t) then self:SetMaxResizeBounds(t[1] or t.width,t[2] or t.height) end
    
    t = def.frameStrata
    if(t) then self:SetFrameStrata(t) end
    
    t = def.frameLevel
    if(t) then self:SetFrameLevel(t) end
    
    t = def.backdrop
    if(t) then self:SetBackdrop(t) end
    
    t = def.backdropBorderColor
    if(t) then self:SetBackdropBorderColor(t[1] or t.r,t[2] or t.g, t[3] or t.b,t[4] or t.a) end
    
    t = def.backdropColor
    if(t) then self:SetBackdropColor(t[1] or t.r,t[2] or t.g, t[3] or t.b,t[4] or t.a) end
    
    t = def.id
    if(t) then self:SetID(def.id) end

    self:SetToplevel(self.toplevel)
    
    for _,script in pairs(scripts) do
        if def[script] and self:HasScript(script) then
            local method = def[script]
            if type(method) == "string" then
                local tmp = handler[method]
                if not tmp then
                    self:error("Handler %q for script %q on object %q not found",method,script,name)
                end
                method = function()tmp(handler)end
            end
            self:SetScript(script,method)
        end
    end
end

AceLibrary:Register(AceGUIFrame, MAJOR_VERSION, MINOR_VERSION)