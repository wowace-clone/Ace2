local MAJOR_VERSION = "AceGUIBase-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFactory = AceLibrary("AceGUIFactory-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUIBase = AceOO.Class()

local AceEvent

if AceLibrary:HasInstace("AceEvent-2.0") then
    AceEvent = AceLibrary("AceEvent-2.0")
end

AceGUIBase.virtual = true

local old_new = AceGUIBase.new

local registry = AceLibrary("AceGUI-2.0").registry
local scripts
AceGUIBase.new = function(self,def,handler,parent,name)
    local tmp = old_new(self)
    local o = self:CreateUIObject(parent)
    for k,v in pairs(tmp) do
        o[k] = v
    end
    local index = getmetatable(tmp).__index
    local frame_index = __framescript_meta.__index
    o = setmetatable(o,{__index = function(t,k)
        return index[k] or frame_index(t,k)
    end})  
    
    if registry.objects[name] then
        self:error("An AceGUI ojbect with the name %q already exists",name)
    end
    parent = def.parent or parent
    o:SetParent(parent)
    local children = {}
    local scripts = {}
    local info = { o = o, name = name, def = def, handler = handler, parent = parent, children = children, scripts = scripts }
    registry.objects[name] = info
    registry.objects[o] = info
    
    if AceEvent then AceEvent:TriggerEvent("ACEGUI_NEW_OBJECT",name,o) end
    o:Build(def,parent,name,handler)
    o:BuildChildren(def,parent,name,handler,children)
    return o    
end

function AceGUIBase.prototype:BuildChildren(def,parent,prefix,handler,children)
    local elements = def.elements
    if elements then
        for suffix,def in pairs(elements) do
            local child = AceGUIFactory:make(def,handler,self, prefix .. suffix)
            self[suffix] = child
            table.insert(children,child)
        end
    end
end

function AceGUIBase.prototype:Configure(def,parent,name,handler)
    self:SetParent(parent)
    local alpha = def.alpha
    if alpha then
        self:SetAlpha(alpha)
    end
    
    local s = registry.objects[self].scripts
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
            s[script] = method
        end
    end
end

function AceGUIBase.prototype:Build(def,parent,name,handler) end

function AceGUIBase.prototype:RunScript(script,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    local f = self:GetScript(script)
    if f then
        local tthis, ta1,ta2,ta3,ta4,ta5,ta6,ta7,ta8,ta9 = this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
        this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9 = self,a1,a2,a3,a4,a5,a6,a7,a8,a9
        f()
        this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9 = tthis, ta1,ta2,ta3,ta4,ta5,ta6,ta7,ta8,ta9
    end
end

function AceGUIBase.prototype:GetAceGUIName()
    return registry.objects[self].name
end

AceLibrary:Register(AceGUIBase,MAJOR_VERSION,MINOR_VERSION)
AceGUIBase = AceLibrary(MAJOR_VERSION)

scripts = {"OnSizeChanged","OnEvent", "OnUpdate", "OnShow", "OnHide", "OnEnter","OnLeave", "OnMouseDown", 
"OnMouseUp", "OnMouseWheel", "OnDragStart", "OnDragStop", "OnReceiveDrag", "OnClick", "OnDoubleClick", 
"OnValueChanged", "OnUpdateModel", "OnAnimFinished", "OnEnterPressed", "OnEscapePressed", "OnSpacePressed", 
"OnTabPressed", "OnTextChanged", "OnTextSet", "OnCursorChanged", "OnInputLanguageChanged", "OnEditFocusGained", 
"OnEditFocusLost", "OnHorizontalScroll", "OnVerticalScroll", "OnScrollRangeChanged", "OnChar", "OnKeyDown", 
"OnKeyUp", "OnColorSelect", "OnHyperlinkEnter", "OnHyperlinkLeave", "OnHyperlinkClick", "OnMessageScrollChanged",
"OnMovieFinished", "OnMovieShowSubtitle", "OnMovieHideSubtitle", "OnTooltipSetDefaultAnchor", "OnTooltipCleared",
"OnTooltipAddMoney","OnLoad"}