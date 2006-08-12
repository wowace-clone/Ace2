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
local AceGUIFactory = AceLibrary("AceGUIFactory-2.0")
local AceGUI = AceOO.Mixin{"CreateGUI"}

function AceGUI:CreateGUI(def)
    return AceGUIFactory:make(def,self)
end

AceLibrary:Register(AceGUI, MAJOR_VERSION, MINOR_VERSION)