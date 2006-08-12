local MAJOR_VERSION = "AceGUIBase-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFactory = AceLibrary("AceGUIFactory-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUIBase = AceOO.Class()

AceGUIBase.virtual = true

local old_new = AceGUIBase.new

local registry = ACEGUI_REGISTRY

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
        error("An AceGUI ojbect with the name '"..name.."' already exists",3)
    end
    parent = def.parent or parent
    local children = {}
    local info = { o = o, name = name, def = def, handler = handler, parent = parent, children = children }
    registry.objects[name] = info
    registry.objects[o] = info
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
end

function AceGUIBase.prototype:Build(def,parent,name,handler)

end

function AceGUIBase.prototype:GetAceGUIName()
    return registry.objects[self].name
end

AceLibrary:Register(AceGUIBase,MAJOR_VERSION,MINOR_VERSION)
AceGUIBase = AceLibrary(MAJOR_VERSION)