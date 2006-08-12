local MAJOR_VERSION = "AceGUICustomClass-2.0"
local MINOR_VERSION = 12345

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceOO = AceLibrary("AceOO-2.0")
local AceGUICustomClass = AceOO.Interface{ UIObjectType = "string", CreateUIObject = "function", BuildChildren = "function" , Configure = "function" }

AceLibrary:Register(AceGUICustomClass, MAJOR_VERSION, MINOR_VERSION)

