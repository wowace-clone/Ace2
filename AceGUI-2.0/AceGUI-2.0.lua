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


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIFontInstance = AceLibrary("AceGUIFontInstance-2.0")
local AceGUI = AceOO.Mixin{"CreateGUI"}

local registry
local AceGUIFactory
local AceEvent

local function configureTree(root)    
    local info = registry.objects[root]
    if AceOO.inherits(root,AceGUIFontInstance) then
        root:ConfigureFontInstance(info.def)
    end
    root:Configure(info.def,info.parent,info.name,info.handler)
    root:RunScript("OnLoad")
    if root:IsVisible() then root:RunScript("OnShow") end
        
    local children = info.children
    for i,child in ipairs(children) do
        configureTree(child)
    end
    
    if AceEvent then AceEvent:TriggerEvent("ACEGUI_OBJECT_CONFIGURED",info.name,root) end
end

function AceGUI:CreateGUI(def,handler)
    local root = AceGUIFactory:make(def,handler or self)
    configureTree(root)
    return root
end

local function activate(newLib, oldLib, oldDeactivate)
    AceGUI = newLib
    --AceGUI.super.activate(AceGUI, oldLib, oldDeactivate)
    if oldLib then
        newLib.registry = oldLib.registry
    end
    if not newLib.registry then
        newLib.registry = {templates = {}, objects = {}}
    end
    registry = newLib.registry
end

local function external(self,major,instance)
    if major == "AceEvent-2.0" then
        AceEvent = instance
    elseif major == "AceGUIFactory-2.0" then
        AceGUIFactory = instance
    end
end

AceLibrary:Register(AceGUI, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)