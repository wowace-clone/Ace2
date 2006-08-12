--[[
Name: AceGUI-2.0
Revision: $Rev$
Author: Tem (tardmrr@gmail.com)
Inspired By: AceGUI by Turan
Website: http://www.wowace.com
Documentation: 
SVN: svn.wowace.com/root/trunk/Ace2/AceGUI-2.0
Description: An embedable library to easily create Frames from lua code.
Dependencies: AceLibrary, AceOO-2.0
]]

local MAJOR_VERSION = "AceGUI-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local registry = ACEGUI_REGISTRY

local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFactory = AceLibrary("AceGUIFactory-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUI = AceOO.Mixin{"CreateGUI"}

local function simulateOnLoad(self,def,handler)
    local method = def.OnLoad
    if method then
        if type(method) == "string" then
            local tmp = handler[method]
            if not tmp then
                self:error("Handler %q for script %q on object %q not found",method,script,name)
            end
            method = function()tmp(handler)end
        end
        assert(type(method) == "function" or (type(method) == "table" and getmetatable(method).__call))
        local tmp = this
        this = self
        method()        
        this = tmp
    end
end

local function configureTree(root)
    
    local info = registry.objects[root]
    if AceOO.inherits(child,AceGUIFontInstance) then
        root:ConfigureFontInstance(info.def)
    end
    root:Configure(info.def,info.parent,info.name,info.handler)
    simulateOnLoad(root,info.def,info.handler)
    
    local children = info.children
    for _,child in children do
        info = registry.objects[child]
        if AceOO.inherits(child,AceGUIFontInstance) then
            child:ConfigureFontInstance(info.def)
        end
        child:Configure(info.def,info.parent,info.name,info.handler)
        configureTree(child)
    end
end

function AceGUI:CreateGUI(def)
    local root = AceGUIFactory:make(def,self)
    configureTree(root)
    return root
end

AceLibrary:Register(AceGUI, MAJOR_VERSION, MINOR_VERSION)