local MAJOR_VERSION = "AceGUICheckButton-2.0"
local MINOR_VERSION = "$Rev$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end


local AceOO = AceLibrary("AceOO-2.0")
local AceGUIButton = AceLibrary("AceGUIButton-2.0")
local AceGUICheckButton = AceOO.Class(AceGUIButton)
AceGUICheckButton.new = AceGUIFrame.new
AceGUICheckButton.CreateUIObject = AceGUIButton.CreateUIObject
AceGUICheckButton.UIObjectType = "CheckButton"



local function attachTexture(textureType,def,elements)
    if type(def[textureType]) == "table" then
        local textureDef = def[textureType]
        elements[textureType] = textureDef
        textureDef.type = "texture"
        textureDef.anchors = textureDef.anchors or buttonTextTemplate.anchors
    end
end

function AceGUIButton.prototype:Build(def,parent,name,handler)
    --AceGUIButton.super.prototype.Build(self,def,parent,name,handler)
    AceGUIFrame.prototype.Build(self,def,parent,name,handler)

    attachTexture("CheckedTexture",def,elements)
    attachTexture("DisabledCheckTexture",def,elements)
end

local function setTexture(self,textureType,def)
    local method = "Set"..textureType
    local arg = def[textureType]
    if self[textureType] then
        arg = self[textureType]
    end
    self[method](self,arg)
end


function AceGUIButton.prototype:Configure(def,parent,name,handler)
    --AceGUIButton.super.prototype.Configure(self,def,parent,name,handler)
    AceGUIButton.prototype.Configure(self,def,parent,name,handler)
    
    setTexture(self,"CheckedTexture",def)
    setTexture(self,"DisabledCheckTexture",def)
end
    

AceLibrary:Register(AceGUIButton, MAJOR_VERSION, MINOR_VERSION)